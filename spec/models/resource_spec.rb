require File.dirname(__FILE__) + '/../spec_helper'

describe Resource do

  before(:all) do
    load_foundation_cache
    iucn_user = User.find_by_given_name('IUCN')
    iucn_content_partner = ContentPartner.find_by_user_id(iucn_user.id)
    @iucn_resource1 = Resource.gen(:content_partner => iucn_content_partner)
    @iucn_resource2 = Resource.gen(:content_partner => iucn_content_partner)
    content_partner = ContentPartner.gen(:user => User.gen)
    resource = Resource.gen(:content_partner => content_partner)
    @oldest_published_harvest_event = HarvestEvent.gen(:resource => resource, :published_at => 3.hours.ago)
    @latest_unpublished_harvest_event = HarvestEvent.gen(:resource => resource, :published_at => nil)
    @latest_published_harvest_event = HarvestEvent.gen(:resource => resource, :published_at => 2.hours.ago)
    @latest_harvest_event = @latest_published_harvest_event
    @resource = Resource.find(resource.id)
  end

  it "should return the resource's oldest published harvest event" do
    @resource.oldest_published_harvest_event.should == @oldest_published_harvest_event
  end
  it "should return the resource's latest published harvest event" do
    @resource.latest_published_harvest_event.should == @latest_published_harvest_event
  end
  it "should return the resource's latest unpublished harvest event" do
    # this test reflects that this method is probably dumb, since what is probably wanted is to see if the latest harvest event is unpublished
    @resource.latest_unpublished_harvest_event.should == @latest_unpublished_harvest_event
  end
  it "should return the resource's latest harvest event" do
    @resource.latest_harvest_event.should == @latest_harvest_event
  end

  describe "iucn" do
    it 'returns the last IUCN resource' do
      Resource.iucn.should == @iucn_resource2
    end
  end

end
