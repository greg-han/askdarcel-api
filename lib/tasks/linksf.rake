# lib/tasks/linksf.rake
# invoke on command line from root directory of repo by running
# `bundle exec rake linksf:import[path/to/linksf-dump.json]`
# you can also run on a production server by running
# `bundle exec rake linksf:import[path/to/linksf-dump.json] RAILS_ENV=production`

require 'json' # not sure if this is necessary in ruby 2.x, json might be part of stdlib now

namespace :linksf do
  task :import, [:filename] => :environment do |_t, args|
    args.with_defaults(filename: 'linksf-pretty.json')

    filename = './linksf.json'

    data = JSON.parse(File.read(filename), symbolize_names: true)

    # Drop the first element because it's just an integer count of the number
    # of resource records.

    category_names = %w(Shelter Food Medical Hygiene Technology Money)
    category_image_paths = %w('ic-housing@3x.png', 'ic-food@3x.png',
                              'ic-health@3x.png', 'ic-hygiene@3x.png', 'ic-work@3x.png', 'ic-money@3x.png')

    6.times do |i|
      FactoryGirl.create(:category, name: category_names[i], image_path: category_image_paths[i])
    end

    # %w(Shelter Food Medical Hygiene Technology).each do |category|
    #  FactoryGirl.create(:category, name: category)
    # end

    days_of_week = %w(Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday)

    records = data[:result].drop(1)

    records.each do |record|
      resource = Resource.new
      resource.name = record[:name]
      resource.website = record[:website]
      resource.long_description = record[:notes]

      category_name = record[:categories]
      category_name = 'shelter' if category_name == 'housing'

      record[:services].each do |service_json|
        category_name = service_json[:category]
        category_name = 'shelter' if category_name == 'housing'
        puts 'catname' + category_name
        cat = Category.where('lower(name) = ?', category_name).first
        resource.categories << cat
      end

      # cat = Category.where('lower(name) = ?', category_name).first
      # resource.categories << cat

      if record[:phoneNumbers].present?
        record[:phoneNumbers].each do |phone_number|
          next unless phone_number[:number].present?
          phone = resource.phones.build
          phone.country_code = 'US'
          phone.service_type = phone_number[:info]
          phone.number = phone_number[:number]
        end
      end

      # 7.times do |i|
      #  schedule_day = resource.schedule.schedule_days.build
      #  schedule_day.day = days_of_week[i]
      #  schedule_day.opens_at = record[:openHours].get[0]
      #  schedule_day.closes_at = record[:openHours].get[0]
      # end

      puts resource.name

      address = resource.addresses.build
      address.city = record[:city]
      address.address_1 = Faker::Address.street_address
      address.state_province = 'CA'
      address.postal_code = Faker::Address.postcode
      address.country = 'USA'

      json_location = record[:location]
      address.latitude = json_location[:latitude]
      address.longitude = json_location[:longitude]

      record[:services].each do |json_service|
        puts '$' + json_service[:name]
        service = resource.services.build
        service.name = json_service[:name]
        service.long_description = json_service[:description]

        if record[:notes].present?
          note = service.notes.build
          note.note = record[:notes]
        end

        service.schedule = Schedule.new

        resource.schedule = service.schedule

        next unless json_service[:openHours].present?
        json_service[:openHours].each do |key, value|
          puts "key = #{key}, value= #{value}"
          open = value[0][0] / 100
          close = value[0][1] / 100
          service.schedule.schedule_days.build(opens_at: open, closes_at: close, day: days_of_week[key.to_s.to_i])
        end
      end

      # ...

      resource.save!
    end
  end
end