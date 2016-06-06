module Privacy
  class Checker
    def checkPolicies(params)
      # Initially no policies are violated
      count_of_violated_policies = 0

      puts "---Checking the privacy policies---"

      # Check whether any mention policy has been violated
      # count_of_violated_policies = checkMentionPolicy(params)
      count_of_violated_policies = checkShareable(params, "Mentions")
      puts "Mention policies violated: " + count_of_violated_policies.to_s
      # If not, then check for violations of Location policies
      if count_of_violated_policies == 0 && params[:location_address].present?
        # count_of_violated_policies = checkLocationPolicy(params)
        count_of_violated_policies = checkShareable(params, "Location")
        puts "Location policies violated: " + count_of_violated_policies.to_s
      end

      if count_of_violated_policies == 0 && params[:photos].present?
        # count_of_violated_policies = checkLocationPolicy(params)
        count_of_violated_policies = checkShareable(params, "Pictures")
        puts "Pictures policies violated: " + count_of_violated_policies.to_s
      end

      return count_of_violated_policies
    end

    def checkShareable(params, shareable)
      # Getting the people mentioned in the post
      ppl = Diaspora::Mentionable.people_from_string(params[:status_message][:text])

      # Temporal variables for accounting the people who have a privacy policy
      # violated
      violatedPeopleCount = 0

      # Loop through all the mentioned people
      ppl.each do |p|
        # Query to the database checking if the wanted their location to be
        # protected from everyone
        protecting_loc = PrivacyPolicy.where(:user_id => p.owner_id, :shareable_type => shareable)

        return 0 if protecting_loc.blank?
        # If we get a row, it means that the policy is going to be violated
        # since they are mentioned in a status message containing a location
        if protecting_loc.collect { |pl| pl.allowed_aspect }.include? -1
          violatedPeopleCount = violatedPeopleCount + 1
        elsif params[:status_message][:aspect_ids].include?('public') || params[:status_message][:aspect_ids].include?('all_aspects')
          violatedPeopleCount = violatedPeopleCount + 1
        else
          # Otherwise we need to check the aspects which are allowed and nobody outside this audience is included in the post audience

          # We get the ids of the people to whom the post is going to be shared
          people_to_share = people_from_aspect_ids(params[:status_message][:aspect_ids])
          # We add also the author's person id since, this user will obviously know the post
          people_to_share.push(params[:status_message][:author].id)

          # We get the ids of the people that the mentioned user allows
          location_pp_user = PrivacyPolicy.where(:user_id => p.owner_id, :shareable_type => shareable)
          people_disallowed = people_from_aspect_ids(location_pp_user.collect{|pp| pp.allowed_aspect})
          # We add the mentioned person as part of the allowed people
          # people_allowed.push(p.id)

          # Subtract the people to share minus the people allowed
          # people_result = people_to_share - people_allowed
          disallowed_people_count = 0
          people_to_share.each do |pts|
            if people_disallowed.include? pts
              disallowed_people_count = disallowed_people_count + 1
            end
          end

          # If the result is greater than 0, there are people in the audience that are not allowed to see the post
          # therefore, if the block flag is activated we block the posting
          # violatedPeopleCount = violatedPeopleCount + 1 if (people_result.count > 0 && location_pp_user.first.block)
          violatedPeopleCount = violatedPeopleCount + 1 if (disallowed_people_count > 0 && location_pp_user.first.block)
        end
      end # each do loop
      return violatedPeopleCount
    end

    def send_to_larva(uid,event)
      Thread.new{
        sock = TCPSocket.new('localhost',7)
        message = "diaspora;" + uid.to_s + ";"+event+"\n"
        sock.write(message)
        sock.close_write
        response = sock.gets
        puts("[LARVA - REPONSE] message: " + response)
        handl = Privacy::Handler.new
        if response.include? "disable-posting"
          handl.add_policy(uid,"Location","yes","no")
          puts "Blocking mentions for user " + uid.to_s
        end
        if response.include? "enable-posting"
          #Structure of the message '<user_id>;<action>'
          values = response.split(";")
          uid = values.at(0).to_i
          handl.delete_policy("Location",uid)
          puts "Enabling mentions for user " + uid.to_s
        end
        sock.close
      }
    end # send_to_larva function

    def send_to_larva(uid,event,shareable,aspect)
      Thread.new{
        sock = TCPSocket.new('localhost',7)
        message = "diaspora;" + uid.to_s + ";"+event+"\n"
        sock.write(message)
        sock.close_write
        response = sock.gets
        puts("[LARVA - REPONSE] message: " + response)
        handl = Privacy::Handler.new
        handl.reset_policies(shareable,uid)
        if response.include? "disable-posting"
          if aspect == -1
            handl.add_policy(uid,shareable,"yes","no",-1)
          else
            # puts "Entering..."
            # aspects = handl.get_user_aspect_ids(uid)
            # puts "Aspects"
            # puts aspects
            # temp = []
            # temp.push(aspect)
            # allowed_aspects = aspects - temp
            # puts "Allowed aspects"
            # puts allowed_aspects
            # allowed_aspects.each do |aa|
              handl.add_policy(uid,shareable,"yes","no",aspect)
            # end
          end
          puts "Blocking mentions for user " + uid.to_s
        end
        if response.include? "enable-posting"
          #Structure of the message '<user_id>;<action>'
          values = response.split(";")
          uid = values.at(0).to_i
          # handl.delete_policy(shareable,uid)
          handl.reset_policies(shareable,uid)
          puts "Enabling mentions for user " + uid.to_s
        end
        sock.close
      }
    end # send_to_larva function

    # @param An array with aspect ids
    # @return An array with the people ids of from the aspects ids
    def people_from_aspect_ids(aspect_ids)
      contacts = []
      aspect_ids.each do |a|
        AspectMembership.where(:aspect_id =>  a).collect{|am| am.contact_id}.each do |c|
          contacts.push(c)
        end
      end

      people = []
      contacts.each do |cid|
        Contact.where(:id => cid).collect{|c| c.person_id}.each do |pid|
          people.push(pid)
        end
      end
      return people
    end

  end # Checker class
end # Privacy module
