class AddAspectsandflagshiddenblockPrivacyPolicies < ActiveRecord::Migration
  def change
  	add_column :privacy_policies, :allowed_aspect, :integer
  	add_column :privacy_policies, :block, :boolean
  	add_column :privacy_policies, :hide, :boolean
  end
end
