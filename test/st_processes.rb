
#
# Testing ruote-rest
#
# John Mettraux at OpenWFE dot org
#
# Sun Apr 13 14:44:10 JST 2008
#

require File.dirname(__FILE__) + '/testbase'


class StProcessesTest < Test::Unit::TestCase

  include TestBase


  LI_WITH_DEFINITION = OpenWFE::LaunchItem.new <<-EOS
    class TestStProcesses1 < OpenWFE::ProcessDefinition
      sequence do
        alpha
        bravo
      end
    end
  EOS

  LI_WITH_DEFINITION_XML =
    OpenWFE::Xml.launchitem_to_xml(LI_WITH_DEFINITION, :indent => 2)

  LI_WITH_DEFINITION_JSON =
    OpenWFE::Json.launchitem_to_h(LI_WITH_DEFINITION).to_json


  def test_get_processes

    get '/processes'

    assert_equal(
      'application/xml',
      @response.content_type)

    assert_match(/count="0"/,  @response.body)
  end

  def test_launch_process

    post(
      '/processes',
      LI_WITH_DEFINITION_XML,
      { 'CONTENT_TYPE' => 'application/xml' })

    fei = OpenWFE::Xml.fei_from_xml @response.body

    assert_equal 201, @response.status
    assert_equal 'TestStProcesses', fei.workflow_definition_name
    assert_not_nil @response['Location']

    sleep 0.350

    get '/processes'

    assert_not_nil @response.body.index(fei.wfid)

    get "/processes/#{fei.wfid}"

    assert_not_nil @response.body.index("<wfid>#{fei.wfid}</wfid>")

    get "/processes/#{fei.wfid}/representation.json"

    js = json_parse(@response.body)
    assert_kind_of Array, js
    assert_equal 'application/json', @response['Content-Type']

    delete "/processes/#{fei.wfid}"

    assert_equal 200, @response.status

    sleep 0.350

    get '/processes'

    assert_not_nil @response.body.index('count="0"')

    get "/processes/#{fei.wfid}"

    assert_equal 404, @response.status
  end


  def assert_process_count (count, query_string)

    query_string = "?#{query_string}" if query_string

    get "/processes.json#{query_string}"

    #puts @response.body

    elts = json_parse(@response.body)['elements']

    assert_equal(count, elts.size)
  end

  def test_process_lookup

    running_expressions = []
    running_expressions << RuoteRest.engine.launch(OpenWFE.process_definition(:name => 'one') do
      sequence do
        _set :var => 'v', :val => 'val0'
        alpha
      end
    end)
    running_expressions << RuoteRest.engine.launch(OpenWFE.process_definition(:name => 'two') do
      sequence do
        _set :var => 'v', :val => 'val1'
        alpha
      end
    end)
    running_expressions << RuoteRest.engine.launch(OpenWFE.process_definition(:name => 'three') do
      sequence do
        _set :field => 'f', :val => 'val0'
        alpha
      end
    end)
    running_expressions << RuoteRest.engine.launch(OpenWFE.process_definition(:name => 'four') do
      sequence do
        _set :field => 'nes', :val => { 'ted' => 'val0', 'tod' => 'val1' }
        alpha
      end
    end)

    running_expressions << RuoteRest.engine.launch(OpenWFE.process_definition(:name => 'five') do
      sequence do
        _set :field => 'object', :val => 77
        alpha
      end
    end)


    sleep 0.350

    # default to all processes
    assert_process_count 5, nil

    # simple variable & field name lookups
    assert_process_count 2, 'variable=v'
    assert_process_count 1, 'field=f'

    # simple nested lookups
    assert_process_count 1, 'field=nes.ted'
    assert_process_count 1, 'field=nes.ted&val=val0'
    assert_process_count 0, 'field=nes.ted&val=val1'

    # check recursive searches
    assert_process_count 2, 'val=val0'

    # check lookups by to_string
    assert_process_count 0, 'val=77'
    assert_process_count 1, 'val=77&to_string=true'

    # over.

    running_expressions.each do |fei|
      RuoteRest.engine.cancel_process(fei)
    end

    sleep 0.350
  end


  def test_pause_resume

    assert_equal 0, OpenWFE::Extras::ArWorkitem.find(:all).size
      #
      # this fixes an AR 2.2.2 issue, grumpf...

    #RuoteRest.engine.register_participant :alpha, OpenWFE::HashParticipant

    li = OpenWFE::LaunchItem.new <<-EOS
      class TestStProcesses2 < OpenWFE::ProcessDefinition
        alpha
      end
    EOS

    post(
      '/processes',
      OpenWFE::Xml.launchitem_to_xml(li, :indent => 2),
      { 'CONTENT_TYPE' => 'application/xml' })

    fei = OpenWFE::Xml.fei_from_xml @response.body

    sleep 0.350

    put(
      "/processes/#{fei.wfid}",
      '<process><paused>true</paused></process>',
      { 'CONTENT_TYPE' => 'application/xml' })

    assert_not_nil @response.body.index('<paused>true</paused>')

    get "/processes/#{fei.wfid}"

    assert_not_nil @response.body.index('<paused>true</paused>')

    put(
      "/processes/#{fei.wfid}",
      '<process><paused>false</paused></process>',
      { 'CONTENT_TYPE' => 'application/xml' })

    assert_not_nil @response.body.index('<paused>false</paused>')

    RuoteRest.engine.cancel_process(fei)

    sleep 0.450

    assert_equal 0, OpenWFE::Extras::ArWorkitem.find(:all).size
  end

  #
  # schedules
  #
  def test_3

    #RuoteRest.engine.register_participant :alpha, OpenWFE::HashParticipant

    li = OpenWFE::LaunchItem.new <<-EOS
      class TestStProcesses3 < OpenWFE::ProcessDefinition
        _sleep '1h'
      end
    EOS

    post(
      '/processes',
      OpenWFE::Xml.launchitem_to_xml(li, :indent => 2),
      { 'CONTENT_TYPE' => 'application/xml' })

    fei = OpenWFE::Xml.fei_from_xml @response.body

    sleep 0.350

    get "/processes/#{fei.wfid}"

    #puts @response.body
    assert_match(/Rufus::.*AtJob/, @response.body)
  end

  def test_cancel_process_over_json

    fei = RuoteRest.engine.launch(%{
      <process-definition name="test">
        <alpha/>
      </process-definition>
    })

    sleep 0.350

    delete "/processes/#{fei.wfid}.json"

    assert_equal 200, @response.status
  end

  def test_launch_process_json

    post(
      '/processes.json',
      LI_WITH_DEFINITION_XML,
      { 'CONTENT_TYPE' => 'application/xml' })

    sleep 0.350

    assert_equal 'application/json', @response.headers['Content-type']

    fei = json_parse(@response.body)
    assert_equal 'ruote_rest', fei['engine_id']
  end

  def test_launch_process_with_json_launchitem

    li = LI_WITH_DEFINITION.to_h.dup
    li['attributes']['food'] = 'tamales'

    post(
      '/processes.json',
      li.to_json,
      { 'CONTENT_TYPE' => 'application/json' })

    sleep 0.350

    #puts @response.body

    assert_equal 'application/json', @response.headers['Content-type']

    fei = json_parse(@response.body)
    assert_equal 'ruote_rest', fei['engine_id']

    assert_equal 1, OpenWFE::Extras::ArWorkitem.find(:all).size
    wi = OpenWFE::Extras::ArWorkitem.find(:first)

    assert_equal 'tamales', wi.as_owfe_workitem.fields['food']
  end
end

