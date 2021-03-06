require File.dirname(__FILE__) + '/../spec_helper'

# before :all was getting called for each describe block, but I only want this to be done once
Vetted.define_core_relationships :include => [:taxon_concepts, :hierarchy_entries]

describe 'Core Relationships' do
  before :all do
    truncate_all_tables
    load_foundation_cache
    Vetted.gen_if_not_exists(:label => 'trusted')
    @trusted = Vetted.trusted    
    @taxon_concept = TaxonConcept.gen(:vetted => @trusted)
    @hierarchy_entry = HierarchyEntry.gen(:vetted => @trusted)
    @data_objects_hierarchy_entry = DataObjectsHierarchyEntry.gen(:vetted => @trusted)
  end
  
  before :each do
    # make sure any loaded assoications are reverted
  end
  
  # helper methods
  it 'should remove elements from arrays' do
    [:a, :b].remove_element!(:a).should == [:b]
    [:a, :b].remove_element!(:b).should == [:a]
    [:a, :b].remove_element!([:a, :b]).should == []
    [:a, {:b => :c}].remove_element!(:a).should == [{:b => :c}]
    [:a, {:b => :c}].remove_element!(:b).should == [:a]
    [:a, {:b => :c}].remove_element!({:b => :c}).should == [:a]
    [:a, {:b => [:c, :d]}].remove_element!(:b).should == [:a]
    [:a, {:b => [:c, :d]}].remove_element!({:b => :c}).should == [:a, {:b => [:d]}]
    [:a, {:b => [:c, :d]}].remove_element!({:b => :d}).should == [:a, {:b => [:c]}]
    [:a, {:b => [:c, :d]}].remove_element!({:b => [:c, :d]}).should == [:a]
  end
  
  it 'should remove elements from hashes' do
    {:a => :b}.remove_element!(:a).should == {}
    {:a => [:b, :c]}.remove_element!(:a).should == {}
    {:a => :b, :c => :d}.remove_element!(:a).should == {:c => :d}
    {:a => :b, :c => :d}.remove_element!(:b).should == {:a => :b, :c => :d}
    {:a => [:b, :c]}.remove_element!({:a => :b}).should == {:a => [:c]}
    {:a => {:b => {:c => [:d, :e]}}}.remove_element!({:a => {:b => {:c => :d}}}).should == {:a => {:b => {:c => [:e]}}}
  end
  
  it 'should add elements to arrays' do
    [:a, :b].add_element!(:a).should == [:a, :b]
    [:a, :b].add_element!(:c).should == [:a, :b, :c]
    [:a, :b].add_element!({:b => :c}).should == [:a, {:b => :c}]
    [:a, {:b => :c}].add_element!(:b).should == [:a, {:b => :c}]
    [:a, :b].add_element!({:c => :d}).should == [:a, :b, {:c => :d}]
    [:a, {:b => :c}].add_element!({:b => :c}).should == [:a, {:b => :c}]
    [:a, {:b => :c}].add_element!({:b => :d}).should == [:a, {:b => [:c, :d]}]
    [:a, {:b => :c}].add_element!({:b => {:c => [:d, :e]}}).should == [:a, {:b => {:c => [:d, :e]}}]
    [:a, {:b => :c}].add_element!([{:b => {:c => [:d, :e]}}, :f]).should == [:a, {:b => {:c => [:d, :e]}}, :f]
  end
  
  # as association
  it 'should create a method core_relationships' do
    Vetted.last.core_relationships.class.should == Vetted
    Vetted.last.core_relationships.id.should == @trusted.id
    Vetted.last.core_relationships.taxon_concepts.should == Vetted.last.taxon_concepts
    Vetted.last.core_relationships.hierarchy_entries.should == Vetted.last.hierarchy_entries
  end
  
  it 'should eager load the associations' do
    Vetted.last.core_relationships.instance_variable_get("@taxon_concepts").should_not == nil
    Vetted.last.core_relationships.instance_variable_get("@hierarchy_entries").should_not == nil
    Vetted.last.instance_variable_get("@taxon_concepts").should == nil
    Vetted.last.instance_variable_get("@hierarchy_entries").should == nil
    
    # but not ones we didnt specify
    Vetted.last.core_relationships.instance_variable_get("@data_objects_hierarchy_entries").should == nil
    Vetted.last.instance_variable_get("@data_objects_hierarchy_entries").should == nil
  end
  
  it 'should not allow define_core_relationships to be called more than once' do
    got_error = false
    begin
      Vetted.define_core_relationships :include => [:taxon_concepts, :hierarchy_entries, :data_objects_hierarchy_entries]
    rescue
      got_error = true
    end
    
    got_error.should == true
    Vetted.last.core_relationships.instance_variable_get("@data_objects_hierarchy_entries").should == nil
  end
  
  # as named scope
  it 'should allow associations to be removed with :except' do
    r = Vetted.core_relationships().last
    r.instance_variable_get("@taxon_concepts").should_not == nil
    r.instance_variable_get("@hierarchy_entries").should_not == nil
    
    r = Vetted.core_relationships(:except => :hierarchy_entries).last
    r.instance_variable_get("@taxon_concepts").should_not == nil
    r.instance_variable_get("@hierarchy_entries").should == nil
  end
  
  it 'should allow :only certain associations' do
    r = Vetted.core_relationships().last
    r.instance_variable_get("@taxon_concepts").should_not == nil
    r.instance_variable_get("@hierarchy_entries").should_not == nil
    r.instance_variable_get("@data_objects_hierarchy_entries").should == nil
    
    r = Vetted.core_relationships(:only => :taxon_concepts).last
    r.instance_variable_get("@taxon_concepts").should_not == nil
    r.instance_variable_get("@hierarchy_entries").should == nil
    r.instance_variable_get("@data_objects_hierarchy_entries").should == nil
    
    # the value of :only does not have to be in the define_core_relationships
    # any association can be included = think of this as a whole new :include
    r = Vetted.core_relationships(:only => :data_objects_hierarchy_entries).last
    r.instance_variable_get("@taxon_concepts").should == nil
    r.instance_variable_get("@hierarchy_entries").should == nil
    r.instance_variable_get("@data_objects_hierarchy_entries").should_not == nil
  end
  
  it 'should NOT remove default relationships permanently' do
    r = Vetted.core_relationships(:except => :taxon_concepts).last
    r.instance_variable_get("@taxon_concepts").should == nil
    r.instance_variable_get("@hierarchy_entries").should_not == nil
    
    # now we're removing data_object but taxon_concepts SHOULD be returned
    r = Vetted.core_relationships(:except => :hierarchy_entries).last
    r.instance_variable_get("@taxon_concepts").should_not == nil
    r.instance_variable_get("@hierarchy_entries").should == nil
    
    # and none of this should affect the association version
    r = Vetted.last.core_relationships
    r.instance_variable_get("@taxon_concepts").should_not == nil
    r.instance_variable_get("@hierarchy_entries").should_not == nil
    
    # now remove nothing, so we should get data objects and concepts
    r = Vetted.core_relationships.last
    r.instance_variable_get("@taxon_concepts").should_not == nil
    r.instance_variable_get("@hierarchy_entries").should_not == nil
  end
end
