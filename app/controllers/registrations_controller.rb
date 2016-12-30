#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class RegistrationsController < Devise::RegistrationsController
  before_filter :check_registrations_open_or_valid_invite!, :check_valid_invite!

  layout ->(c) { request.format == :mobile ? "application" : "with_header" }, :only => [:new]
  before_filter -> { @css_framework = :bootstrap }, only: [:new, :create]

  def create
    @user = User.build(user_params)
    @user.process_invite_acceptence(invite) if invite.present?

    if @user.sign_up
      flash[:notice] = I18n.t 'registrations.create.success'
      @user.seed_aspects
      sign_in_and_redirect(:user, @user)
      Rails.logger.info("event=registration status=successful user=#{@user.diaspora_handle}")

      # TODO: Make sure that the following code is data race free!!!
      # ================================== ADDED FOR ABE PURPOSES -- EXECUTING KEYGEN ===============================
      # Getting pod name
      pod_name = @user.diaspora_handle.split('@')[1].split(":").join.upcase
      # Add user handle and access policy to conf.json --- ABE photos support
      abe_path = 'abe-photos/'
      file = File.read(abe_path+'conf.json') # Open the configuration file
      data_hash = JSON.parse(file) # Parse it to a hash object
      new_user = {"gid" => @user.id.to_s,
                  "path" => "data/user_"+@user.id.to_s+".json",
                  "attributes" => [{
                                      "atts" => ["FRIENDS"+@user.username.to_s.upcase],
                                      "location" => pod_name
                                   }],
                  "access_policy" => "FRIENDS"+@user.username.to_s.upcase+"@"+pod_name}
      data_hash['users'].push(new_user)


      # Add all authorities and attributes from the know people in the pod
      Person.pluck(:diaspora_handle).each do |dh|
        username_and_pod = dh.split('@')
        person_username = username_and_pod[0].upcase
        person_pod_name = username_and_pod[1].split(":").join.upcase

        included_in_conf = false

        data_hash['authorities'].each do |auth|
          if auth['location'] == person_pod_name
            if !auth['attributes'].include?("FRIENDS"+person_username) # If the user was not already inluded
              auth['attributes'].push("FRIENDS"+person_username)
            end
            included_in_conf = true # Flag to check whether the authority is in conf.json
          end
        end

        if !included_in_conf
          data_hash['authorities'].push({"attributes" => ["FRIENDS"+person_username],
                                         "location" => person_pod_name,
                                         "path" => "data/auth_"+person_pod_name+".json"})
        end
      end

      File.open(abe_path+"conf.json","w") do |f| # Open file to write
        f.write(JSON.pretty_generate data_hash) # Save the updated file
      end
      # Add user handle and access policy to conf.json --- ABE photos support

      # Erase the data folder and create new info -- KeyGen
      system("rm -rf "+abe_path+"data/*")
      file = File.read(abe_path+'global_conf.json') # Open the configuration file
      data_hash = JSON.parse(file) # Parse it to a hash object
      data_hash['operation'] = "init"
      data_hash['user_decrypt'] = @user.id.to_s
      File.open(abe_path+"global_conf.json","w") do |f| # Open file to write
        f.write(JSON.pretty_generate data_hash) # Save the updated file
      end
      system("python "+abe_path+"waters15.py") # Generating keys
      # ================================== ADDED FOR ABE PURPOSES -- EXECUTING KEYGEN ===============================

    else
      @user.errors.delete(:person)

      flash[:error] = @user.errors.full_messages.join(" - ")
      Rails.logger.info("event=registration status=failure errors='#{@user.errors.full_messages.join(', ')}'")
      render :action => 'new', :layout => 'with_header'
    end
  end

  def new
    super
  end

  private

  def check_valid_invite!
    return true if AppConfig.settings.enable_registrations? #this sucks
    return true if invite && invite.can_be_used?
    flash[:error] = t('registrations.invalid_invite')
    redirect_to new_user_session_path
  end

  def check_registrations_open_or_valid_invite!
    return true if invite.present?
    unless AppConfig.settings.enable_registrations?
      flash[:error] = t('registrations.closed')
      redirect_to new_user_session_path
    end
  end

  def invite
    if params[:invite].present?
      @invite ||= InvitationCode.find_by_token(params[:invite][:token])
    end
  end

  helper_method :invite

  def user_params
    params.require(:user).permit(:username, :email, :getting_started, :password, :password_confirmation, :language, :disable_mail, :invitation_service, :invitation_identifier, :show_community_spotlight_in_stream, :auto_follow_back, :auto_follow_back_aspect_id, :remember_me, :captcha, :captcha_key)
  end
end
