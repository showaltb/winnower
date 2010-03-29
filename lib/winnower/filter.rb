require 'action_view'
require 'active_record'

module Winnower

  # abstract base class for a filter
  class Filter

    include ActionView::Helpers::FormOptionsHelper
    include ActionView::Helpers::FormTagHelper
    include ActionView::Helpers::JavaScriptHelper
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::AssetTagHelper
    include DateHelper;

    attr_accessor :active, :name, :label, :field, :operator, :value, :options
    attr_reader :condition, :error

    # creates a new filter. +label+ is name of filter field shown to the user.
    # +field+ is database column for conditions for this filter. +options+ is
    # optional hash of options for the filter.
    # 
    # options supported by all filters:
    #   :active   - true if filter is initially active
    #   :operator - initial operator
    #   :value    - initial value(s)
    #
    def initialize(label, field, options = {})
      @name = label.parameterize.to_s.gsub("-", "_")
      @label = label
      @field = field
      @options = default_options.merge(options.to_options)
      reset
    end

    # resets filter to intial values
    def reset
      @active = options[:active]
      @operator = options[:operator]
      @value = options[:value]
      @condition = nil
      @error = nil
    end

    # default options
    def default_options
      { :operator => :is }
    end

    # allowable operators for this filter
    def operators
      [:is]
    end

    # validates current filter, setting error and/or condition
    def validate
      @condition = nil
      @error = "No validation implemented for #{self.class}#validate"
    end

    def valid?
      @error.blank?
    end

    # converts operator name to value to display in drop-down
    def operator_label(op)
      op.to_s.gsub("_", " ")
    end

    # returns a field input name for this filter in the format prefix[arr][index]
    def input_name(arr, multi = false, index = name)
      s = @name_prefix.blank? ? arr.to_s : "#{@name_prefix}[#{arr}]"
      s << "[#{index}]" if index
      s << "[]" if multi
      s
    end

    # returns a dom id for this filter
    def dom_id(suffix = nil)
      [@dom_prefix, name, suffix].reject(&:blank?).join("_")
    end

    # html for TR element to display intial filter in UI.  dom_prefix is unique
    # string for this filter, used to prefix other elements associated with the
    # filter.
    def html(dom_prefix = nil, name_prefix = nil)
      @dom_prefix = dom_prefix
      @name_prefix = name_prefix
      content_tag(:tr, [
        content_tag(:td, html_label, :width => 200),
        content_tag(:td, content_tag(:div, html_operator, :id => dom_id(:operator_div)), :width => 150),
        content_tag(:td, content_tag(:div, html_value, :id => dom_id(:value_div))),
      ].join, :id => dom_id, :style => "display: #{active ? 'table-row' : 'none'}")
    end

    # html for filter label and checkbox selector
    def html_label
      check_box_tag(input_name(:fields, true, nil), name, active, :id => dom_id(:active), :onclick => js_active_toggle) + h(label)
    end

    # javascript to execute when a label checkbox is clicked. default is to
    # toggle the operator and value cells
    def js_active_toggle
      %Q{
      if (this.checked) {
        $('#{dom_id(:operator_div)}').show();
        #{js_value_settle};
      }
      else {
        $('#{dom_id(:operator_div)}').hide();
        $('#{dom_id(:value_div)}').hide();
      }
      }
    end

    # javascript to adjust display of value UI based on operator value.  called
    # only when filter itself is active. by default, displays the value div
    # unless the operator is "blank"
    def js_value_settle
      %Q{
      if ($('#{dom_id(:operator)}').value=='blank') {
        $('#{dom_id(:value_div)}').hide();
      }
      else {
        $('#{dom_id(:value_div)}').show();
      }
      }
    end

    # html for filter operator UI
    def html_operator
      select_tag(input_name(:operators), options_for_select(operators.collect {|o| [operator_label(o), o]}, operator), :id => dom_id(:operator), :onchange => js_value_settle)
    end

    # html for filter value UI
    def html_value
      "TODO: html_value for #{name}"
    end

    # returns choices array, with all values stringified
    def stringified_choices(arr = Array(options[:choices]))
      arr.collect {|entry| entry.is_a?(Array) ? stringified_choices(entry) : entry.to_s}
    end

  end

  class DateFilter < Filter
    def operators
      [:is, :on_or_after, :on_or_before, :between, :blank]
    end

    def validate
      @error = @condition = nil
      (v1, v2) = Array(value).collect(&:to_s).collect(&:strip)
      if operator != :blank
        return @error = 'please enter a date' if v1.blank?
        d1 = begin
          Date.parse_date(v1) 
        rescue ArgumentError
          nil
        end
        return @error = 'date is invalid' if d1.nil?
        if operator == :between
          return @error = 'please enter a second date' if v1.blank?
          d2= begin
            Date.parse_date(v2) 
          rescue ArgumentError
            nil
          end
          return @error = 'second date is invalid' if d2.nil?
          return @error = 'second date cannot be earlier than first date' if d2 < d1
        end
      end
      @condition = case operator
      when :is
        ["#{field}=?", d1]
      when :on_or_after
        ["#{field}>=?", d1]
      when :on_or_before
        ["#{field}<=?", d1]
      when :between
        ["#{field} between ? and ?", d1, d2]
      when :blank
        ["#{field} is null"]
      end
    end

    def html_value
      date_field_tag(input_name(:values, true), Array(value)[0], :id => dom_id(:value)) + content_tag(:span, ' and ' + date_field_tag(input_name(:values, true), Array(value)[1], :id => dom_id(:value2)), :id => dom_id(:extra))
    end

    # javascript to adjust display of value UI based on operator value.  called
    # only when filter itself is active. by default, displays the value div
    # unless the operator is "blank"
    def js_value_settle
      %Q{
      if ($('#{dom_id(:operator)}').value=='blank') {
        $('#{dom_id(:value_div)}').hide();
      }
      else {
        $('#{dom_id(:value_div)}').show();
        if ($('#{dom_id(:operator)}').value=='between') {
          $('#{dom_id(:extra)}').show();
        }
        else {
          $('#{dom_id(:extra)}').hide();
        }
      }
      }
    end
  end

  class SelectFilter < Filter

    def operators
      [:is, :is_not, :blank]
    end

    def validate
      @error = @condition = nil
      return @error = 'Please select a value' if value.nil? && operator != :blank
      @condition = case operator
      when :is
        ["#{field} in (?)", value]
      when :is_not
        ["#{field} not in (?)", value]
      when :blank
        "#{field} is null"
      end
    end

    def html_value
      multiple = Array(value).size != 1
      choices = stringified_choices
      size = multiple ? [choices.size, 7].min : 1
      select_tag(input_name(:values, true), options_for_select(options[:choices], value), :id => dom_id(:value), :multiple => multiple, :size => size, :style => "vertical-align: top") + ' ' +
      link_to_function(image_tag("expand.png", :border => 0, :align => "top"), js_toggle_multi)
    end

    def js_toggle_multi
      %Q{
      var select = $('#{dom_id(:value)}');
      select.multiple = !select.multiple;
      select.size = 1;
      if (select.multiple) {
        select.size = 7;
        if (select.length<select.size) {
          select.size=select.length;
        }
      }
      }
    end

  end

  class TextFilter < Filter

    def default_options
      super.merge({:operator => :contains})
    end

    def validate
      @error = @condition = nil
      v = value.to_s.strip
      return @error = 'please enter a value' if v.blank? and operator != :blank
      @condition = case operator
      when :is
        ["#{field}=?", v]
      when :is_not
        ["#{field}<>?", v]
      when :contains
        ["#{field} like ?", "%#{v}%"]
      when :does_not_contain
        ["#{field} not like ?", "%#{v}%"]
      when :starts_with
        ["#{field} like ?", "#{v}%"]
      when :blank
        "#{field} is null"
      end
    end

    def operators
      [:is, :is_not, :contains, :does_not_contain, :starts_with, :blank]
    end

    def html_value
      text_field_tag(input_name(:values), value, :size => options[:size] || 30)
    end

  end

  class CheckBoxesFilter < SelectFilter

    def html_value
      stringified_choices.collect do |text, val|
        val ||= text
        "#{check_box_tag(input_name(:values, true), val, Array(value).collect(&:to_s).include?(val))} #{h text} &nbsp; "
      end.join
    end

  end

  class RadioButtonsFilter < SelectFilter

    def html_value
      stringified_choices.collect do |text, val|
        val ||= text
        "#{radio_button_tag(input_name(:values), val, value.to_s == val)} #{h text} &nbsp; "
      end.join
    end

  end

  class BooleanFilter < Filter
    def operators
      ops = [:yes, :no]
      ops << :blank if options[:allow_blank]
      ops
    end

    def validate
      @error = nil
      @condition = case operator
      when :yes
        ["#{field}"]
      when :no
        ["not #{field}"]
      when :blank
        ["#{field} is null"]
      end
    end

    def default_options
      {:operator => :yes, :allow_blank => false}
    end

    def html_value
      ''
    end

    def js_value_settle
      ''
    end
  end

end
