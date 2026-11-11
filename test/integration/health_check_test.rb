require "test_helper"

# Load balancers, Thruster and the Coolify and Kamal deploys decide whether the app is up
# from this endpoint, so it must answer 200 without a signed-in user or a tenant.
class HealthCheckTest < ActionDispatch::IntegrationTest
  test "the health check answers 200" do
    get rails_health_check_path

    assert_response :ok
  end
end
