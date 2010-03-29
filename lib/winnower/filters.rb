require 'action_view'
require 'rack'

require 'winnower/filter'
require 'winnower/sanitizer'

module Winnower

  # Winnower::Filters provides a way to build a set of filters, or query
  # conditions with a simple interface. The Winnower::Filters object
  # produces a set of conditions suitable for passing to ActiveRecord#find
  # in order to retrive the matching rows.
  class Filters

    include ActionView::Helpers::FormTagHelper
    include ActionView::Helpers::JavaScriptHelper
    include ActionView::Helpers::TagHelper
    include Rack::Utils

    attr_reader :all_filters, :errors, :conditions

    # creates a filter set
    def initialize
      @all_filters = []
      @errors = []
      @conditions = nil
      filters
      reset
    end

    # adds initial filters to the set. override in subclass to provide
    # specific filters
    def filters
    end

    # adds a filter to the set, returning the new filter object
    # add using a predefined type:
    #   filter(:text, "Customer Name", "customer.name", {:active => true, :operator => :is, :value => "Jones"})
    # add using a class name (subclass of Winnower::Filter):
    #   filter(MyFilter, "jobs.id", options)
    # add using a filter object already constructed:
    #   filter(my_object)
    def filter(kind, *args)
      case kind
      when String, Symbol
        klass = %Q{Winnower::#{"#{kind.to_s}_filter".classify}}.constantize
        filter klass, *args
      when Class
        obj = kind.new(*args)
        filter obj
      else
        @all_filters << kind
      end
    end

    # reset all filters to default values, and then validate
    def reset
      all_filters.each(&:reset)
      validate
    end

    # returns a query string representing current state of filters
    def to_query
      hash = {:fields => [], :operators => {}, :values => {}}
      active_filters.each do |f|
        hash[:fields] << f.name
        hash[:operators][f.name] = f.operator
        hash[:values][f.name] = f.value
      end
      hash.to_query
    end

    # initializes filter state from params hash
    def parse_params(params)
      all_filters.each {|f| f.reset; f.active = false}
      data = params.symbolize_keys
      Array(data[:fields]).each do |name|
        filter = all_filters.find {|f| f.name == name}
        if filter
          filter.active = true
          operator = data[:operators][name].to_sym
          filter.operator = operator if filter.operators.include?(operator)
          filter.value = data[:values][name]
        end
      end
      validate
    end

    # initializes filter state from query string (from to_query)
    def parse_query(query)
      parse_params(parse_nested_query(query))
    end

    # returns a dom id for this filter set
    def dom_id(suffix = nil)
      [@html_options[:dom_prefix], suffix].reject(&:blank?).join("_")
    end

    # returns HTML for the user interface to manage the filters
    # options:
    #   :div = hash of html options for outer div
    def html(options = {})
      @html_options = options.symbolize_keys.reverse_merge(:div => {:id => "filters"})
      @html_options[:div] ||= {}
      @html_options[:dom_prefix] ||= @html_options[:div][:id] || "filters"
      @html_options[:name_prefix] ||= "filters"
      div_options = (@html_options[:div] || {}).reverse_merge(:class => "winnower")
      content_tag :div, [html_toggler, html_fieldset, html_errors].join, div_options
    end

    # returns HTML for the fieldset toggler
    def html_toggler
      content_tag(:div, 
        link_to_function('Filters &raquo;', "$('#{dom_id('toggler')}').hide();$('#{dom_id('fieldset')}').show()"),
        :id => dom_id('toggler'), :style => "display:#{errors.present? ? 'none' : 'block'}")
    end

    # returns HTML for the fieldset legend
    def html_legend
      content_tag(:legend, 
        link_to_function('Filters &laquo;', "$('#{dom_id('fieldset')}').hide();$('#{dom_id('toggler')}').show()"))
    end

    # returns HTML for the fieldset containing the filters
    def html_fieldset
      content_tag(:fieldset,
        html_legend <<
        content_tag(:table, 
          content_tag(:tr,
            content_tag(:td, html_filters) <<
            content_tag(:td, html_add_filter, :align => "right"),
          :valign => "top"),
        :width => "100%") <<
        html_controls <<
        javascript_tag(active_filters.collect(&:js_value_settle).join(";")),
      :id => dom_id('fieldset'), :style => "display:#{errors.present? ? 'block' : 'none'}")
    end

    def html_filters
      content_tag(:table, all_filters.collect {|f| f.html(@html_options[:dom_prefix], @html_options[:name_prefix])}.join)
    end

    def html_controls
      content_tag(:p, [
        link_to_function("Apply", "$('#{dom_id('reset')}').value='';this.up('form').submit()"),
        '&nbsp;',
        link_to_function("Reset", "if (confirm('Reset to default filters?')) {$('#{dom_id('reset')}').value='1';this.up('form').submit()}"),
        hidden_field_tag(dom_id("reset")),
      ].join(' '))
    end

    def html_add_filter
      select_tag(dom_id("add_filter"),
      ([content_tag(:option, 'Add Filter...')] + all_filters.reject(&:active).collect {|f| content_tag(:option, h(f.label), :value => h(f.name), :disabled => f.active)}).join, 
      :onchange => js_add_filter)
    end

    def js_add_filter
      %Q{
      var value = this.value;
      if (value != '') {
        $('#{@html_options[:dom_prefix]}_' + value + '_active').checked = true;
        $('#{@html_options[:dom_prefix]}_' + value).show();
        $('#{@html_options[:dom_prefix]}_' + value + '_operator').onchange();
        //this.options[this.selectedIndex].disabled = true;
        this.options[this.selectedIndex] = null;
      }
      this.selectedIndex = 0;
      }
    end

    # returns HTML for the errors (if any) for the filters
    def html_errors
      if errors.present?
        content_tag :ul, errors.collect {|error| content_tag(:li, h(error))}.join, :class => "errors"
      end
    end

    # returns active filters
    def active_filters
      all_filters.select(&:active)
    end

    # validates all active filters, setting errors and conditions
    def validate
      active_filters.each {|f| f.validate}
      @errors = active_filters.reject(&:valid?).collect {|f| "#{f.label}: #{f.error}"}
      @conditions = Sanitizer.send(:merge_conditions, *(active_filters.collect(&:condition)))
      valid?
    end

    # true if all active filters are valid (no errors)
    def valid?
      errors.none?
    end

  end

end
