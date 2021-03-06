
#
# Testing ruote-rest
#
# John Mettraux at OpenWFE dot org
#
# Mon Apr 14 15:45:00 JST 2008
#

require File.dirname(__FILE__) + '/testbase'


class StParticipantsTest < Test::Unit::TestCase

  include TestBase


  def test_0

    get '/participants'

    #puts @response.body

    assert_equal 200, @response.status
    assert_equal 'application/xml', @response['Content-Type']

    post(
      '/participants',
      '["toto","OpenWFE::HashParticipant"]',
      { 'CONTENT_TYPE' => 'application/json' })

    #puts @response.body

    assert_equal 201, @response.status
    assert_not_equal '', @response.body

    get '/participants'

    #puts @response.body

    assert_not_nil(
      @response.body.index(' count="4"'), "expected 4 participants")

    get '/participants/toto'

    #puts @response.body

    assert_not_nil @response.body.index('>toto<')

    delete '/participants/toto'

    assert_equal 200, @response.status

    get '/participants'

    #puts @response.body

    assert_not_nil @response.body.index(' count="3"')
  end

  def test_1

    post(
      '/participants',
      '["toto","OpenWFE::Extras::ArParticipant", "totostore"]',
      { 'CONTENT_TYPE' => 'application/json' })

    #p @response.status
    #puts @response.body

    assert_equal 201, @response.status
    assert_not_equal '', @response.body

    get '/participants'

    assert_not_nil(
      @response.body.index(' count="4"'), 'expected 4 participants')

    get '/participants?pname=toto'

    assert_equal 200, @response.status
    assert_not_nil @response.body.index('toto')
  end

  def test_2

    assert_equal(
      [ 'one', 'two', 'three' ],
      RuoteRest.engine.get_participant_map.lookup_participant('carlito').params)
  end

end

