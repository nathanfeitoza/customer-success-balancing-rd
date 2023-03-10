require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success
    @customers = customers
    @away_customer_success = away_customer_success
  end

  # Returns the ID of the customer success with most customers
  def execute
    get_customer_success_with_most_customers
  end

  def get_customer_success_with_most_customers
    _, most_customers = group_by_customer_success_services

    return 0 unless most_customers.count == 1

    most_customers.first[:id]
  end

  def group_by_customer_success_services
    return [] if services_balanced.empty?

    services_balanced
      .group_by { |service_balanced| service_balanced[:customers].count }
      .sort_by {|service_group| -service_group.first}
      .first
  end

  def services_balanced
    @services_balanced ||= distribute_customers_to_customers_success
  end

  def available_customers_success
    return @customer_success if @away_customer_success.empty?

    @customer_success.reject {|customer_success| @away_customer_success.include? customer_success[:id]}
  end

  def ordered_customers_success_by_score
    @ordered_customers_success_by_score ||= order_by_score(available_customers_success)
  end

  def ordered_customers_by_score
    @ordered_customers_by_score ||= @customers.empty? ? [] : order_by_score(@customers)
  end

  def order_by_score(dataObjects)
    dataObjects.sort_by {|dataObject| dataObject[:score]}
  end

  def distribute_customers_to_customers_success
    ordered_customers_success_by_score.map.with_index do |customer_success, index|
      previous_customer_sucess = index.zero? ? nil : ordered_customers_success_by_score[index - 1]
      customers = fetch_customers_by_customer_success(customer_success, previous_customer_sucess)
      customer_success[:customers] = customers

      customer_success
    end
  end

  def fetch_customers_by_customer_success(customer_success, previous_customer_sucess)
    ordered_customers_by_score.select do |customer|
      match_customer_with_customer_success(
        customer,
        customer_success,
        previous_customer_sucess
      )
    end
  end

  def match_customer_with_customer_success(customer, customer_success, previous_customer_sucess)
    return customer[:score] <= customer_success[:score] if previous_customer_sucess.nil?

    customer[:score] <= customer_success[:score] && customer[:score] > previous_customer_sucess[:score]
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10000, 998)),
      [999]
    )
    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 6, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end
