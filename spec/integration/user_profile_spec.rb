require File.dirname(__FILE__) + '/../spec_helper'

def create_user username, password
  user = User.gen :username => username, :password => password
  user.password = password
  user.save!
  user
end

describe 'User Profile' do

  before(:all) do
    truncate_all_tables
    load_foundation_cache
    Capybara.reset_sessions!
    @username = 'userprofilespec'
    @password = 'beforeall'
    @user     = create_user(@username, @password)
    @watch_collection = @user.watch_collection
  end

  after(:each) do
    visit('/logout')
  end

  it 'should allow users to change filter content hierarchy' do
    login_as @user
    visit('/account/site_settings')
    body.should_not have_tag('#header a[href*=?]', /login/)
    body.should include('Filter EOL')
    body.should have_tag('input#user_filter_content_by_hierarchy')
  end

  it 'should generate api key' do
    login_as @user
    visit('/account/site_settings')
    body.should include('Generate a key')
    click_button("Generate a key")
    body.should_not include("Generate a key")
    body.should include("Your key is")
  end

  describe 'collections' do
    before(:each) do
      visit(user_collections_path(@user))
    end
    it 'should show their watch collection' do
      page.body.should have_tag('#collections_tab', /#{@watch_collection.name}/)
    end
  end

end
