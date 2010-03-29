require 'date_validator'

# dates within a 100-year window ending Date::WINDOW years in the future
# can be entered with 2-digit years and are displayed with 2-digit years.
# For example, if window is 25, and current year is 2009, then the years
# 1935 through 2034 are the range. A date like '01/01/35' is assumed to
# be 1935, while a date like '01/01/34' is assumed to be 2034.
Date::WINDOW = 19
Date::WINDOW_END = Date.today.year + Date::WINDOW
Date::WINDOW_BEG = Date::WINDOW_END - 99

# override default date and time formats
Date::DATE_FORMATS[:default] = lambda {|d| d.strftime(d.year < Date::WINDOW_BEG || d.year > Date::WINDOW_END ? '%m/%d/%Y' : '%m/%d/%y')}
Time::DATE_FORMATS[:default] = lambda {|t| t.strftime(t.year < Date::WINDOW_BEG || t.year > Date::WINDOW_END ? '%m/%d/%Y %I:%M %p' : '%m/%d/%y %I:%M %p')}
