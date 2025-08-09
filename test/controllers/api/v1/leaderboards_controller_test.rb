require "test_helper"

class Api::V1::LeaderboardsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_leaderboards_index_url
    assert_response :success
  end
end
