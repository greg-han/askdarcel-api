class AddressSerializer < ActiveModel::Serializer
  attributes :id, :full_street_address, :city, :state, :state_code, :postal_code, :country, :country_code, :longitude, :latitude

  belongs_to :resource
end