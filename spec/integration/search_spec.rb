require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../lib/eol_data'
class EOL::NestedSet; end
EOL::NestedSet.send :extend, EOL::Data

require 'solr_api'

def assert_results(options)
  search_string = options[:search_string] || 'tiger'
  per_page = options[:per_page] || 10
  visit("/search?q=#{search_string}&per_page=#{per_page}#{options[:page] ? "&page=#{options[:page]}" : ''}")
  body.should have_tag('#main ul') do
    result_index = options[:num_results_on_this_page]
    with_tag("li:nth-child(#{result_index})")
    without_tag("li:nth-child(#{result_index + 1})")
  end
end

describe 'Search' do
  before :all do
    truncate_all_tables
    load_scenario_with_caching(:search_names)
    data = EOL::TestInfo.load('search_names')

    @panda                      = data[:panda]
    @name_for_all_types         = data[:name_for_all_types]
    @name_for_multiple_species  = data[:name_for_multiple_species]
    @unique_taxon_name          = data[:unique_taxon_name]
    @text_description           = data[:text_description]
    @image_description          = data[:image_description]
    @video_description          = data[:video_description]
    @sound_description          = data[:sound_description]
    @tiger_name                 = data[:tiger_name]
    @tiger                      = data[:tiger]
    @tiger_lilly_name           = data[:tiger_lilly_name]
    @tiger_lilly                = data[:tiger_lilly]
    @tricky_search_suggestion   = data[:tricky_search_suggestion]
    @suggested_taxon_name       = data[:suggested_taxon_name]
    @user1                      = data[:user1]
    @user2                      = data[:user2]
    @community                  = data[:community]
    @collection                 = data[:collection]

    Capybara.reset_sessions!
    visit('/logout')
    make_all_nested_sets
    flatten_hierarchies
    ci_solr_api = SolrAPI.new($SOLR_SERVER, $SOLR_COLLECTION_ITEMS_CORE)
    ci_solr_api.delete_all_documents
    builder = EOL::Solr::SiteSearchCoreRebuilder.new()
    builder.begin_rebuild
  end

  it 'should redirect to species page if only 1 possible match is found (also for pages/searchterm)' do
    visit("/search?q=#{@unique_taxon_name}")
    current_path.should match /\/pages\/#{@panda.id}/
    visit("/search/#{@unique_taxon_name}")
    current_path.should match /\/pages\/#{@panda.id}/
  end

  it 'should redirect to search page if a string is passed to a species page' do
    visit("/pages/#{@unique_taxon_name}")
    current_path.should match /\/pages\/#{@panda.id}/
  end

  it 'should show a list of possible results (linking to /found) if more than 1 match is found  (also for pages/searchterm)' do
    visit("/search?q=#{@tiger_name}")
    body.should have_tag('li', /#{@tiger_name}/) do
      with_tag('a[href*=?]', %r{/pages/#{@tiger.id}})
    end
    body.should have_tag('li', /#{@tiger_lilly_name}/) do
      with_tag('a[href*=?]', %r{/pages/#{@tiger_lilly.id}})
    end
  end

  it 'should be able to return suggested results for "bacteria"' do
    visit("/search?q=#{@tricky_search_suggestion}&search_type=text")
    body.should have_tag("#main li", /#{@suggested_taxon_name}/)
  end

  it 'should treat empty string search gracefully when javascript is switched off' do
    visit('/search?q=')
    body.should_not include "500 Internal Server Error"
  end

  it 'should show only common names which include whole search query' do
    visit("/search?q=#{URI.escape @tiger_lilly_name}")
    # should find only common names which have 'tiger lilly' in the name
    # we have only one such record in the test, so it redirects directly
    # to the species page
    current_path.should match /\/pages\/#{@tiger_lilly.id}/
  end

  it 'should return a helpful message if no results' do
    # TaxonConcept.should_receive(:search_with_pagination).at_least(1).times.and_return([])
    visit("/search?q=bozo")
    body.should have_tag('h2', /0 results for.*?bozo/)
  end

  it 'should place suggested search results at the top of the list' do
    visit("/search?q=#{@tricky_search_suggestion}&search_type=text")
    body.should have_tag("#search_results li", /#{@suggested_taxon_name}/)
  end

  it 'should sort by score by default' do
    visit("/search?q=#{@name_for_all_types}")
    default_body = body.gsub(/content[0-9]{1,2}\./, 'content1.')  # normalizing content server host names
    visit("/search?q=#{@name_for_all_types}&sort_by=score")
    newest_body = body.gsub(/content[0-9]{1,2}\./, 'content1.')  # normalizing content server host names
    default_body.gsub(/return_to.*?\"/, '').should == newest_body.gsub(/return_to.*?\"/, '')
  end

  it 'should sort by newest and oldest' do
    visit("/search?q=#{@name_for_all_types}&sort_by=newest")
    newest_results = []
    page.find(:xpath, "//div[@id='main']").all(:xpath, './/li').each{ |li| newest_results << li.text }

    visit("/search?q=#{@name_for_all_types}&sort_by=oldest")
    oldest_results = []
    page.find(:xpath, "//div[@id='main']").all(:xpath, './/li').each{ |li| oldest_results << li.text }

    newest_results.length.should == 8
    newest_results.length.should == oldest_results.length
    newest_results.should == oldest_results.reverse
  end

  # the following tests are for redirecting when there is only one result
  it 'should redirect to species page if only 1 possible match is found' do
    visit("/search?q=#{@unique_taxon_name}")
    current_path.should match /^\/pages\/#{@panda.id}/
  end

  it 'should redirect to a text page if only 1 possible match is found' do
    visit("/search?q=#{CGI::escape(@text_description)}")
    current_path.should match /^\/data_objects\//
  end

  it 'should redirect to an image page if only 1 possible match is found' do
    visit("/search?q=#{CGI::escape(@image_description)}")
    current_path.should match /^\/data_objects\//
  end

  it 'should redirect to a video page if only 1 possible match is found' do
    visit("/search?q=#{CGI::escape(@video_description)}")
    current_path.should match /^\/data_objects\//
  end

  it 'should redirect to a sound page if only 1 possible match is found' do
    visit("/search?q=#{CGI::escape(@sound_description)}")
    current_path.should match /^\/data_objects\//
  end

  it 'should redirect to user page if only 1 possible match is found' do
    visit("/search?q=#{@user1.username}")
    current_path.should match /^\/users\/#{@user1.id}/
  end

  it 'should redirect to community page if only 1 possible match is found' do
    visit("/search?q=#{CGI::escape(@community.description)}")
    current_path.should match /^\/communities\/#{@community.id}/
  end

  it 'should redirect to collection page if only 1 possible match is found' do
    visit("/search?q=#{CGI::escape(@collection.name)}")
    current_path.should match /^\/collections\/#{@collection.id}/
  end



  # the following tests are for testing filtering. There is an entry for panda in each category, but only one, so
  # we should get redirected when the filter is on
  it 'should return all results when not filtering' do
    visit("/search?q=#{@name_for_all_types}")
    current_path.should match /^\/search/
    body.should have_tag('h2', /8 results for.*?#{@name_for_all_types}/)

    visit("/search?q=#{@name_for_all_types}&" + CGI::escape("type[]=all"))
    current_path.should match /^\/search/
    body.should have_tag('h2', /8 results for.*?#{@name_for_all_types}/)
  end

  it 'should filter by collection' do
    visit("/search?q=#{@name_for_all_types}&" + CGI::escape("type[]=collection"))
    current_path.should match /^\/collections\/#{@collection.id}/
  end

  it 'should filter by community' do
    visit("/search?q=#{@name_for_all_types}&" + CGI::escape("type[]=community"))
    current_path.should match /^\/communities\/#{@community.id}/
  end

  it 'should filter by image' do
    visit("/search?q=#{@name_for_all_types}&" + CGI::escape("type[]=image"))
    current_path.should match /^\/data_objects\//
  end

  it 'should filter by sound' do
    visit("/search?q=#{@name_for_all_types}&" + CGI::escape("type[]=sound"))
    current_path.should match /^\/data_objects\//
  end

  it 'should filter by video' do
    visit("/search?q=#{@name_for_all_types}&" + CGI::escape("type[]=video"))
    current_path.should match /^\/data_objects\//
  end

  it 'should filter by text' do
    visit("/search?q=#{@name_for_all_types}&" + CGI::escape("type[]=text"))
    current_path.should match /^\/data_objects\//
  end

  it 'should filter by taxon concept' do
    visit("/search?q=#{@name_for_all_types}&" + CGI::escape("type[]=taxon_concept"))
    current_path.should match /^\/pages\/#{@panda.id}/
  end

  it 'should filter by user' do
    visit("/search?q=#{@name_for_all_types}&" + CGI::escape("type[]=user"))
    current_path.should match /^\/users\/#{@user2.id}/
  end
end
