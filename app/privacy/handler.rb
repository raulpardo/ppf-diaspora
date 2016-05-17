module Privacy
  class Handler
    def add_policy(uid, shareable, to_block, to_hide)
      return_message = ""
      policyTemp = PrivacyPolicy.where(:user_id => uid,
                                     :shareable_type => shareable).first
      if policyTemp != nil
        return_message = "Diaspora is already protecting your " + shareable
      else
        policy = PrivacyPolicy.new(:user_id => uid,
                                   :shareable_type => shareable,
                                   :block => to_block == "yes" ? 1 : 0, # Take the input from the user
                                   :hide => to_hide == "yes" ? 1 : 0, # Take the input from the user
                                   :allowed_aspect => nil) # Take the input from the user
        policy.save
        return_message = "Diaspora is protecting your " + shareable
      end
      return return_message
    end

    def delete_policy(shareable, uid)
      policy = PrivacyPolicy.where(:user_id => uid,
                                  :shareable_type => shareable).first
      policy.destroy if policy != nil
      return "Diaspora is *NOT* protecting your " + shareable
    end
  end
end
