class CreatePrivacyPolicies < ActiveRecord::Migration
  def change
    create_table :privacy_policies do |t|
      t.integer :user_id
      t.string :shareable_type

      t.timestamps
    end
  end
end
