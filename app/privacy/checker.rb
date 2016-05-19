module Privacy
  class Checker
    def checkPolicies(params)
      # Initially no policies are violated
      count_of_violated_policies = 0
      
      puts "---Checking the privacy policies---"
      
      # Check whether any mention policy has been violated
      count_of_violated_policies = checkMentionPolicy(params)
      puts "Mention policies violated: " + count_of_violated_policies.to_s
      # If not, then check for violations of Location policies
      if count_of_violated_policies == 0 && params[:location_address].present?
        count_of_violated_policies = checkLocationPolicy(params)
        puts "Location policies violated: " + count_of_violated_policies.to_s
      end

      return count_of_violated_policies
    end

    def checkMentionPolicy(params)
      violations = 0
      mentioned_people = Diaspora::Mentionable.people_from_string(params[:status_message][:text])

      mentioned_people.each do |p|
        protect_ment = PrivacyPolicy.where(:user_id => p.owner_id,
                                           :shareable_type => "Mentions").first
        if protect_ment != nil
          violations = violations + 1
        end
      end # each do loop of mentioned people
      return violations
    end # checkMentionpolicy function

    def checkLocationPolicy(params)
      # Getting the people mentioned in the post
      ppl = Diaspora::Mentionable.people_from_string(params[:status_message][:text])

      # Temporal variables for accounting the people who have a privacy policy
      # violated
      violatedPeopleCount = 0

      # Loop through all the mentioned people 
      ppl.each do |p|
        # Query to the database checking if the wanted their location to be
        # protected
        protecting_loc = PrivacyPolicy.where(:user_id => p.owner_id,
                                             :shareable_type => "Location").first

        # If we get a row, it means that the policy is going to be violated
        # since they are mentioned in a status message containing a location
        if protecting_loc != nil
          violatedPeopleCount = violatedPeopleCount + 1
        end
      end # each do loop
      return violatedPeopleCount
    end # checkLocationPolicy function

    def send_to_larva(uid)
      Thread.new{
        sock = TCPSocket.new('localhost',7)
        message = "diaspora;" + uid.to_s + ";post\n"
        sock.write(message)
        sock.close_write
        response = sock.gets
        puts("[LARVA - REPONSE] message: " + response)
        if response.include? "disable-posting"
          handl = Privacy::Handler.new
          # handl.add_policy(uid,"Mentions","yes","no")
          handl.add_policy(uid,"Location","yes","no")
          puts "Blocking mentions for user " + uid.to_s
        end
        sock.close
      }
    end # send_to_larva function

  end # Checker class
end # Privacy module
