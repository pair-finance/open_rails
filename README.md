# OpenAPI implementation for Ruby On Rails   
           
## Usage 

### Gemfile 
```ruby
gem 'pair_kit_open_rails'
```

### Plugins 
```ruby
class ApplicationController < ActionController::Base
  include PairKit::OpenRails::ControllerPlugin
  include PairKit::ActiveScope::Controller
  
  before_action :authenticate_user!    # use classical Rails Device
  before_action :grant_security_scope!
  
  def grant_security_scope!
    if @current_user.is_active
      @security_scope = ["user:#{@current_user.id}", @current_user.is_admin ? 'admin' : 'user']
    end
  end
end
```

```ruby
class ApplicationRecord < ActiveRecord
  include PairKit::ActiveJson::Record
  include PairKit::ActiveScope::Record
end
```


## Example 

### Define Model

```ruby
class User < ApplicationRecord
  belongs_to :company
  has_many :tasks 
  
  def full_name
    "#{first_name} #{last_name}"  
  end
  
  security_scope('user:{id}') { |id| where(id: id) } # filter by user
  security_scope(:admin) # full access
  
  schema do
    # own properties
    prop (:id)        .int   .ro                         .r(:admin)
    prop!(:first_name).str                               .rw(:admin, :user)
    prop!(:last_name) .str                               .rw(:admin, :user)
    prop!(:email)     .email                             .rw(:admin).r(:user)
    prop (:full_name) .str   .ro(:first_name, :last_name).r(:admin, :user)
    prop (:is_active) .bool  .defaut(true)               .rw(:admin)
    prop (:is_admin)  .bool  .defaut(false)              .rw(:admin)
    prop!(:company_id).int                               .rw(:admin)
    
    prop!(:password)  .passwd.wo                         .w(:user)
    prop!(:confirm)   .passwd.wo                         .w(:user)
    
    # relations 
    prop(:company)    .object { ref('company') }.ro      .r(:admin)
    prop(:tasks)      .arr { items.ref('task') }.ro      .r(:admin, :user)
  end
end
```

```ruby
class Company < ApplicationRecord
  has_many :users
  
  security_scope('user:{id}') { |id| where(id: User.find(id).company_id) } # filter by user
  security_scope(:admin) # full access
  
  schema do
    # own properties
    prop (:id)  .int   .ro  .r(:admin)
    prop!(:name).str        .rw(:admin).r(:user)
  end
end
```


```ruby
class Task < ApplicationRecord
  belongs_to :user
  
  security_scope('user:{id}') { |id| where(user_id: id) } # filter by user
  security_scope(:admin) # full access
  
  schema do
    # own properties
    prop (:id)      .int.ro                    .r(:admin, :user)
    prop!(:name)    .str                       .rw(:admin, :user)
    prop!(:due_date).date                      .rw(:admin, :user)
    
    prop(:user)     .object { ref(:user) }.ro  .r(:admin)
  end
end
```


```ruby
class Order < ApplicationRecord
  belongs_to :company
  
  security_scope('user:{id}') { |id| where(company_id: User.find(id).company_id) } # filter by user
  security_scope(:admin) # full access

  # the dynamic_enum can be used by fron and back end both for validation 
  # plus frontend can use it for preview 
  # this hast to work like this in Json Chema
  # ...
  # properties: {
  #    ...
  #    companyId: {
  #       type: 'integer',
  #       x-dynamic-enum: {
  #         optionsUrl: '//companies?jql=$[][id, name]',
  #         validationUrl: '//companies/{val}',   => 200 means validation passt 
  #         optionsKey: 'id'
  #       }
  #    }
  # }
  # Only applicable for writing for the admin        
  
  schema do
    # own properties
    prop (:id)          .int.ro                         .r(:admin, :user)
    prop!(:date)        .date.ro                        .r(:admin, :user)
    prop!(:amount_cents).int                            .rw(:admin, :user)
    prop!(:status)      .enum(:new, :processing, :done) .rw(:admin, :user)
    prop!(:company_id)                                  .rw(:admin).r(:user)
                        .int { dynamic_enum(options_key: id, 
                                            options: '//companies?jql=$[][id, name]',
                                            validate: '/companies/{val}') }

    prop(:company)      .object { ref(:company) }.ro    .r(:admin)
  end
end
```



### Define Controller 

```ruby

class UsersController < ApplicationController
  before_openapi_action{ @users ||= security_scope(User) }
  before_openapi_action(except: %i[create index]) { |params| @user ||= @users.find(params[:id]) }
  
  openapi_tags :users 
  
  openapi_action :create do
    summary 'Create User'

    request.content.content.dynamic_ref('#/components/schemas/models/users:create;security_scope={security_scope}')
    
    response(:created).content.ref('#/components/schemas/models/users:read;security_scope={security_scope}')
    response(:bad_request).content.ref('#/components/schemas/ErrorModel')

    perform { |input| @users.create(input) }
  end
  
  openapi_action :update do
    summary 'Update User'
    
    security_scope :admin, :user
    
    param(:id).in_path.int
    request.content.content.dynamic_ref('#/components/schemas/models/users:update;security_scope={security_scope}')
    
    response(:ok).content.dynamic_ref('#/components/schemas/models/users:read;security_scope={security_scope}')
    response(:bad_request).content.ref('#/components/schemas/ErrorModel')
    response(:not_found)
    
    perform { |_, input| @user.update(input) }
  end
  
  openapi_action :delete do
    summary 'Delete user'

    security_scope :admin

    param(:id).in_path.int
    
    response(:no_content)
    response(:forbidden).content.object.prop(:message).str

    perform do 
      if @user && @user.company.users.count > 1
        throw :forbidden, { message: "Can't delete last user in the company" }
      end
      
      @user&.destroy  
    end
  end
  
  openapi_action :show do
    summary 'Get User'

    security_scope :admin, :user
    
    param(:id).in_path.int

    response(:ok).content.ref('#/components/schemas/models/users:create;scope={security_scope}')
    response(:not_found)

    perform { @user }
  end

  openapi_action :index do
    summary 'Index Users'

    security_scope :admin

    param(:jql).in_query.schema.ref('#/components/schemas/models/users:jql;scope={security_scope}')
    
    response(:ok).content.arr.items.ref('#/components/schemas/models/users:show;scope={security_scope}')

    perform { |params| @users.json_path(params[:jql]) }
  end
end
```


### Use Console Client on Your Local Machine 
```ruby
  client = PairKit::OpenApi::Client.new('https://pairfincne.com/openapi/v.1.1', 
                                        cert: '~/.ssh/pair_api_cert.pem')

  client.users[23].update(email: 'test@test.com')

  query = <<-JQL
    $[?(@amount_cents > 10000, @status = "new"), ^(@amount_cents-, @debtor.last_name+), 100:200]
      {id, amount_cents, debtor{last_name, email}}
  JQL

  client.companies[1238].orders[jql: query].lazy.each do |cf|
    puts "id=#{cd.id} email=#{cf.debtor.email}"  
  end

```

```ruby
class OrderController < Create
  before_openapi_action { @orders ||= security_scope(Order) }
  before_openapi_action(except: %i[create index]) { |params| @order ||= @orders.find(params[:id]) }

  
  openapi_action :create do
    summary 'Create Order'
    
    response(:created).content.ref('#/components/schemas/models/users:read;security_scope={security_scope}')
    response(:bad_request).content.ref('#/components/schemas/ErrorModel')

    request.content.ref('#/components/schemas/models/orders:create;security_scope={security_scope}')
    security_scope :admin, :user
    
    perform { @orders.create(input) } 
  end
end
```

## Other Features

* ACL on operations and fields level 
* Cashing (almost for free HTTP spec)
* Support for many media types (like csv, exel) on the library level (without a line custom code)
* Automatic API client generation (JavaScript, TypoScript, Python) for internal usage and customers 
* Progressive migration, i.e. classical Rails app can bin converted into open API action by action.

## TODO
* Floating input/output schema dependent on params(do we need it? oneOf solution maybe)
* What if I create some sub-graph of data (like order->items), how to orchanize dynamic validation in the context?
* 
