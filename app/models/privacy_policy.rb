class PrivacyPolicy < ActiveRecord::Base
  attr_accessible :shareable_type, :user_id
end
