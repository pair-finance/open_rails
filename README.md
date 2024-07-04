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
    prop(:first_name).required.str
    prop(:last_name).required.str
    prop(:email).required.format(:email)
    prop(:full_name).read_only.dependent_on(:first_name, :last_name).str
    prop(:is_active).required.bool
    
    prop(:company).ref('$/pair_kit/open_rails/models/users/view')
    prop(:tasks).arr.ref('$/pair_kit/open_rails/models/users/view')
  end
end
```



### Define Controller 

```ruby

class UsersController < ApplicationController
  before_action :authenticate_user!
  
  before_openapi_action except: :create do |params| 
    @user = User.find(params[:id])
  end
  
  openapi_tags :admin_only, :users 
  
  openapi_action :create do
    tag :top_security
    
    summary 'Create User'
    
    request.ref('$/pair_kit/open_rails/models/users/update_params')
    response.ref('$/pair_kit/open_rails/models/users/view')

    perform { |input| User.create(input) }
  end
  
  openapi_action :update do
    summary 'Update User'
    
    param(:id).in_path.int
    request.ref('$/pair_kit/open_rails/models/users/update_params')
    response.ref('$/pair_kit/open_rails/models/users/view')
    
    perform { @user.update(input); @user }
  end
  
  openapi_action :delete do
    tag :top_security
    
    summary 'Delete user'

    param(:id).in_path.int

    perform do 
      throw(:forbidden, message: "Can't delete last user in the company") if  @user.last 
      @user.destroy  
    end
  end
  
  openapi_action :show do
    tags :admin_only, :top_security, :users, :get

    summary 'Get User'
    
    param(:id).in_path.int

    perform { @user }
  end

  openapi_action :index do
    tags :admin_only, :top_security, :users, :index

    summary 'Index Users'

    param(:json_query).in_path.ref('$/pair_kit/open_rails/models/users/json_query') 

    perform { |params| User.json_query(params)_ }
  end
end
```


### Use Console Client on Your Local Machine 
```ruby
  client = PairKit::OpenApi::Client.new('https://pairfincne.com/openapi/v.1.1', 
                                        cert: '~/.ssh/pair_api_cert.pem')

  client.users[23].upate(email: 'test@test.com')

  query = '$[?(@balance_cents > 10000, @status = "active"), 100:200]{id, balance, debtor{email}}'
  client.company[1238].case_files[].lazy.each do |cf|
    puts "id=#{cd.id} email=#{cf.debtor.email}"  
  end

``` 
