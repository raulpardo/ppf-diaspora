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

    def add_policy(uid, shareable, to_block, to_hide, aspect)
      return_message = ""

      policy = PrivacyPolicy.new(:user_id => uid,
                                 :shareable_type => shareable,
                                 :block => to_block == "yes" ? 1 : 0, # Take the input from the user
                                 :hide => to_hide == "yes" ? 1 : 0, # Take the input from the user
                                 :allowed_aspect => aspect) # Take the input from the user
      policy.save
      return_message = "Diaspora is protecting your " + shareable
      return return_message
    end

    def delete_policy(shareable, uid)
      policy = PrivacyPolicy.where(:user_id => uid,
                                  :shareable_type => shareable).first
      policy.destroy if policy != nil
      return "Diaspora is **NOT** protecting your " + shareable
    end

    def reset_policies(shareable, uid)
      PrivacyPolicy.where(:user_id => uid,
                          :shareable_type => shareable).find_each do |policy|
        policy.destroy
      end
    end

    def get_user_aspect_ids(uid)
      aspects_temp = Aspect.where(:user_id => uid)
      aspects = []
      aspects_temp.each do |a|
        aspects = aspects.push(a.id)
      end
      return aspects
    end

    def get_user_disallowed_aspects(uid, shareable)
      location_privacy_policies = PrivacyPolicy.where(:user_id => uid,
                                                      :shareable_type => shareable)
      if location_privacy_policies.collect{|pp| pp.allowed_aspect}.include? -1
        return [-1]
      else
        aspects = get_user_aspect_ids(uid)
        return aspects.collect{|a| a if !location_privacy_policies.collect{|pp| pp.allowed_aspect}.include? a}
      end
    end
  end
end
