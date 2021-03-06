require File.dirname(__FILE__) + '/../spec_helper'

describe SessionsController do

  before(:all) do
    truncate_all_tables
    Language.create_english
    CuratorLevel.create_defaults
  end

  describe "GET new" do
    it 'should be successful' do
      get :new
      response.should be_success
    end
  end

  describe "POST create" do

    describe "invalid login" do
      it "should re-render login with flash error" do
        post :create, :session => { :username_or_email => "email@example.com", :password => "invalid" }
        response.redirected_to.should == login_path
        flash[:error].should =~ /login failed/i
      end
    end

    describe "valid login" do
      it 'should log the user in and redirect to user\'s show' do
        password = 'password'
        user = User.gen(:password => password)
        post :create, :session => { :username_or_email => user.email, :password => password }
        flash[:notice].should =~ /login successful/i
        response.should redirect_to(user_newsfeed_path(user))
      end
    end
  end

end
