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
end
```

```ruby
class ApplicationRecord < ActiveRecord
  include PairKit::OpenRails::ActiveRecordPlugin
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
  
  schema do
    # own properties
    prop(:first_name).required.str
    prop(:last_name).required.str
    prop(:email).required.format(:email)
    prop(:full_name).read_only.dependent_on(:first_name, :last_name).str
    prop(:is_active).required.bool
    
    # relations 
    prop(:company).read_only.ref('$/pair_kit/open_rails/models/users/view')
    prop(:tasks).read_only.arr.ref('$/pair_kit/open_rails/models/users/view')
    
    # permissions of fields level
    prop(:first_name).allow.read(:admin, :self).write(:admin).filter(:admin).sort(:admin)
    prop(:last_name).allow.read(:admin, :self).write(:admin).filter(:admin).sort(:admin)
    prop(:email).allow(:admin, :self)
    prop(:is_active).allow.read(:admin, :self).filter(:admin)
    prop(:company).allow.read(:admin)
    prop(:tasks).allow(:tasks, :self)
  end
end
```



### Define Controller 

```ruby

class UsersController < ApplicationController
  before_action :authenticate_user!
  
  before_openapi_action(except: %i[create index]) { |params| @user = User.find(params[:id]) }
  
  openapi_tags :admin_only, :users 
  
  openapi_action :create do
    tag :top_security
    
    allow :admin
    
    summary 'Create User'
    
    request.ref('$/pair_kit/open_rails/models/users/update_params')
    
    response(:created).content.ref('$/pair_kit/open_rails/models/users/view')
    response(:bad_request).content.ref('#/components/schemas/ErrorModel')

    perform { |input| User.create(input) }
  end
  
  openapi_action :update do
    summary 'Update User'

    allow :admin
    
    param(:id).in_path.int
    request.ref('$/pair_kit/open_rails/models/users/update_params')
    
    response(:ok).content.ref('$/pair_kit/open_rails/models/users/view')
    response(:bad_request).content.ref('#/components/schemas/ErrorModel')
    response(:not_found)
    
    perform { |_, input| @user.update(input) }
  end
  
  openapi_action :delete do
    tag :top_security
    
    summary 'Delete user'

    allow :admin

    param(:id).in_path.int
    
    response(:no_content).content.object.prop(:id).int
    response(:forbidden).content.object.prop(:message).str

    perform do 
      throw(:forbidden, { message: "Can't delete last user in the company" }) unless  @user.company.users.count > 1 
      
      @user.destroy  
    end
  end
  
  openapi_action :show do
    tags :admin_only, :top_security, :users, :get

    summary 'Get User'

    allow :admin, :self
    
    param(:id).in_path.int

    response(:ok).content.ref('$/pair_kit/open_rails/models/users/view')
    response(:not_found)

    perform { @user }
  end

  openapi_action :index do
    tags :admin_only, :top_security, :users, :index

    summary 'Index Users'

    allow :admin

    param(:jql).in_query.ref('$/pair_kit/open_rails/models/users/json_path')
    response(:ok).content.arr.items.ref('$/pair_kit/open_rails/models/users/view')

    perform { |params| User.json_path(params[:jql]) }
  end
end
```


### Use Console Client on Your Local Machine 
```ruby
  client = PairKit::OpenApi::Client.new('https://pairfincne.com/openapi/v.1.1', 
                                        cert: '~/.ssh/pair_api_cert.pem')

  client.users[23].update(email: 'test@test.com')

  query = <<-JQL
    $[?(@balance_cents > 10000, @status = "active"), 100:200]{id, balance, debtor{email}}
  JQL

  client.companies[1238].case_files[jql: query].lazy.each do |cf|
    puts "id=#{cd.id} email=#{cf.debtor.email}"  
  end

``` 


## Other Features

* ACL on operations and fields level 
* Cashing (almost for free HTTP spec)
* Support for many media types (like csv, exel) on the library level (without a line custom code)
* Automatic API client generation (JavaScript, TypoScript, Python) for internal usage and customers 
* Progressive migration, i.e. classical Rails app can bin converted into open API action by action.
