require 'active_record'

module Winnower

  # provides access to AR's sanitize_sql and merge_conditions methods
  class Sanitizer < ActiveRecord::Base
  end

end
