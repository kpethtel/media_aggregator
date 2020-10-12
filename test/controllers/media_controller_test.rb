require 'test_helper'
require 'minitest/autorun'
require 'minitest/spec'
# not sure why this is necessary since i'm not that familiar with minitest
# but it wasn't picking up services
require_relative '../../app/services/media_gatherer.rb'

class MediaControllerTest < ActionDispatch::IntegrationTest
  facebook_address = 'https://takehome.io/facebook'
  twitter_address = 'https://takehome.io/twitter'
  instagram_address = 'https://takehome.io/instagram'

  teardown do
    WebMock.reset!
  end

  test 'it returns the aggregate of the social media responses' do
    facebook_body = [{name: 'brian', status: 'messiah'}].to_json
    instagram_body = [{username: 'picture person', picture: 'thatsthejoke.jpg'}].to_json
    twitter_body = [{username: 'tweety',tweet: 'tweedle-eet'}].to_json
    body = {
      'facebook' => facebook_body,
      'instagram' => instagram_body,
      'twitter' => twitter_body,
    }

    stub_request(:get, facebook_address).to_return(status: 200, body: facebook_body)
    stub_request(:get, instagram_address).to_return(status: 200, body: instagram_body)
    stub_request(:get, twitter_address).to_return(status: 200, body: twitter_body)

    get media_url
    assert_response :success
    assert_equal JSON.parse(@response.body), body
  end

  test 'it informs the user that the service is unavailable when no 200 is returned' do
    body = {
      'facebook' => 'Service unavailable',
      'instagram' => 'Service unavailable',
      'twitter' => 'Service unavailable',
    }

    stub_request(:get, facebook_address).to_return(status: 500, body: '')
    stub_request(:get, instagram_address).to_return(status: 500, body: '')
    stub_request(:get, twitter_address).to_return(status: 500, body: '')

    get media_url

    assert_response :success
    assert_equal JSON.parse(@response.body), body
  end

  test 'it informs the user that the service is unavailable when invalid json is returned' do
    body = {
      'facebook' => 'Service unavailable',
      'instagram' => 'Service unavailable',
      'twitter' => 'Service unavailable',
    }

    stub_request(:get, facebook_address).to_return(status: 200, body: 'hey')
    stub_request(:get, instagram_address).to_return(status: 200, body: 'hey')
    stub_request(:get, twitter_address).to_return(status: 200, body: 'hey')

    get media_url

    assert_response :success
    assert_equal JSON.parse(@response.body), body
  end

end