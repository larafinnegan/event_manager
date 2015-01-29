require "csv"
require "sunlight/congress"
require "erb"
require "date"

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phone(phone)
  phone = phone.to_s.gsub(/[^\d]/, '')
  if phone.length < 10 || phone.length > 11 || (phone.length == 11 && phone[0] != 1)
    "0000000000"
  elsif phone.length > 10 && phone[0] == 1
    phone[1..-1]
  else
    phone
  end
end

def strip_date(date)
  date = DateTime.strptime(date, '%m/%d/%Y %k:%M')
end

def legislators_by_zipcode(zipcode)
  legislators = Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letters(id, form_letter)
  Dir.mkdir("../output") unless Dir.exists? "../output"

  filename = "../output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts "Event Manager Initialized!"

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

popular_hours = {}
popular_days = {}

contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])
  phone = clean_phone(row[:homephone])
  
  date = strip_date(row[:regdate])
  popular_hours.has_key?(date.hour) ? popular_hours[date.hour] += 1 : popular_hours[date.hour] = 1
  popular_days.has_key?(date.wday) ? popular_days[date.wday] += 1 : popular_days[date.wday] = 1
  
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letters(id, form_letter)
end

puts "\nThe most popular hours are:\n\n"
sorted = popular_hours.sort_by {|hour, frequency| frequency }.reverse
sorted.each {|hour, frequency| puts "#{hour}: #{frequency}"}

days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

puts "\nThe most popular days of the week are:\n\n"
sorted = popular_days.sort_by {|day, frequency| frequency }.reverse
sorted.each {|day, frequency| puts "#{days[day]}: #{frequency}"}
