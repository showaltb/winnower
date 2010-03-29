require 'test_helper'
require 'winnower'

class WinnowerTest < ActionController::TestCase

  context "A filter" do
    setup do
      @filter = Winnower::Filter.new
    end
  end

  context "A filter set" do
    setup do
      @filters = Winnower::Filters.new
    end

    context "as html" do
      setup do
        @html = @filters.html
      end
      should "Contain fieldset in outer div" do
        assert_select_from @html, 'div fieldset'
      end
    end
  end

end
