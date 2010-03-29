require 'winnower'

class TestFilters < Winnower::Filters

  def filters
    filter :text, "Customer Name", "customers.name"
    filter :select, "Customer Type", "customers.name", :choices => %w(Customer Prospect Lead) + ("A".."Z").to_a
    filter :date, "Customer Since", "customers.since"
    filter :check_boxes, "Never had Job of Type", "foo", :choices => [['HVAC', '1'], ['Electrical', 2], ['Plumbing', 3]]
    filter :boolean, "Commercial?", "customers.commercial"
    filter :radio_buttons, "Sex", "customers.sex", :choices => [['Male', 'm'], ['Female', 'f']]
  end

end

class MainController < ApplicationController

  def index

    # initial filter set
    @filters = TestFilters.new

    if request.post?
      @filters.parse_params(params[:filters]) unless params[:filters_reset].present?
    end

  end

end
