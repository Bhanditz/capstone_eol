require File.dirname(__FILE__) + '/../../spec_helper'

describe Users::NewsfeedsController do

  before(:all) do
    truncate_all_tables
    load_scenario_with_caching :testy
    @testy = EOL::TestInfo.load('testy')
  end

  describe 'GET show' do

    it 'should instantiate the user' do
      get :show, :user_id => @testy[:user].id.to_i
      assigns[:user].should == @testy[:user]
    end
    it 'should instantiate the parent property for use in a new comment' do
      get :show, :user_id => @testy[:user].id.to_i
      assigns[:parent].should == @testy[:user]
    end

  end

end
