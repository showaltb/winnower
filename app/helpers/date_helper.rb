#
# Distributed with Rails Date Kit
# http://www.methods.co.nz/rails_date_kit/rails_date_kit.html
#
# Author:  Stuart Rackham <srackham@methods.co.nz>
# License: This source code is released under the MIT license.
#
module DateHelper

  # Rails text_field helper plus drop-down calendar control for date input. Same
  # options as text_field plus optional :format option which accepts
  # same date display format specifiers as calendar_open() (%d, %e, %m, %b, %B, %y, %Y).
  # If the :format option is not set the the global Rails :default date format
  # is used or failing that  '%d %b %Y'.
  #
  # Explicitly pass it the date value to ensure it is formatted with desired format.
  # Example:
  #
  # <%= date_field('person', 'birthday', :value => @person.birthday) %>
  #
  def date_field(object_name, method, options={})
    object = options[:object] || instance_variable_get("@#{object_name}")
    options = {
      :size => 9,
      :value => object.send(method),
    }.merge(options)
    if options[:value].is_a?(Date)
      format = options.delete(:format) ||
               Date::DATE_FORMATS[:default] ||
               '%d %b %Y'
      options[:value] = format.respond_to?(:call) ? format.send(:call, options[:value]) : options[:value].strftime(format)
    end
    months = Date::MONTHNAMES[1..12].collect { |m| "'#{m}'" }
    months = '[' + months.join(',') + ']'
    days = Date::DAYNAMES.collect { |d| "'#{d}'" }
    days = '[' + days.join(',') + ']'
    options = {:onfocus => "this.select();calendar_open(this,{format:'%m/%d/%Y',images_dir:'/images',month_names:#{months},day_names:#{days}})",
               :onclick => "event.cancelBubble=true;this.select();calendar_open(this,{format:'%m/%d/%Y',images_dir:'/images',month_names:#{months},day_names:#{days}})",
              }.merge(options);
    text_field object_name, method, options
  end

  def date_field_tag(name, value = nil, options = {})
    options.reverse_merge! :size => 9
    if value.is_a?(Date)
      format = options.delete(:format) ||
               Date::DATE_FORMATS[:default] ||
               '%d %b %Y'
      value = format.respond_to?(:call) ? format.send(:call, value) : value.strftime(format)
    end
    months = Date::MONTHNAMES[1..12].collect { |m| "'#{m}'" }
    months = '[' + months.join(',') + ']'
    days = Date::DAYNAMES.collect { |d| "'#{d}'" }
    days = '[' + days.join(',') + ']'
    options.reverse_merge!  :onfocus => "this.select();calendar_open(this,{format:'%m/%d/%Y',images_dir:'/images',month_names:#{months},day_names:#{days}})",
       :onclick => "event.cancelBubble=true;this.select();calendar_open(this,{format:'%m/%d/%Y',images_dir:'/images',month_names:#{months},day_names:#{days}})"
    text_field_tag name, value, options
  end

end

module ActionView
  module Helpers

    class FormBuilder
      def date_field(method, options = {})
        @template.date_field(@object_name, method, options.merge(:object => @object))
      end
    end

  end
end
