#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class UsersController < ApplicationController
  before_filter :authenticate_user!, :except => [:new, :create, :public, :user_photo]
  before_filter -> { @css_framework = :bootstrap }, only: [:privacy_settings, :edit]

  layout ->(c) { request.format == :mobile ? "application" : "with_header_with_footer" }, only: [:privacy_settings, :edit]

  use_bootstrap_for :getting_started

  respond_to :html

  include Kbl

  def edit
    @aspect = :user_edit
    @user   = current_user
    @email_prefs = Hash.new(true)
    @user.user_preferences.each do |pref|
      @email_prefs[pref.email_type] = false
    end
  end

  def privacy_settings
    @blocks = current_user.blocks.includes(:person)
    @aspects = Aspect.where(:user_id => current_user.id)
    handler = Privacy::Handler.new


    # ------------- Added by me ---------------
    # Get all the location privacy policies of the user
    location_privacy_policies = PrivacyPolicy.where(:user_id => current_user.id, :shareable_type => "Location")

    # Check whether location must be protected
    @protecting_location = false

    # Get the blocking and hiding flag from the first row (all row will have the same, TODO makes it per policy basis)
    pp = location_privacy_policies.first
    if pp != nil
      @protecting_location = true
      @block_location = pp.block
      @hide_location = pp.hide


      # Get all disallowed aspects
      disallowed_aspects = handler.get_user_disallowed_aspects(current_user.id, "Location")
      @protected_location = []
      disallowed_aspects.each do |da|
        @protected_location.push(da)
      end
    end

    # location_policy = PrivacyPolicy.where(:user_id => current_user.id,
    #                                       :shareable_type => "Location",
    #                                       :allowed_aspect => nil).first
    #
    # if location_policy != nil
    #   @protecting_location = true
    #   @protected_location = [-1]
    #   @hide_location = location_policy[:hide]
    #   @block_location = location_policy[:block]
    # else
    #   @protecting_location = false
    # end


    # mentions_policy = PrivacyPolicy.where(:user_id => current_user.id,
    #                                       :shareable_type => "Mentions",
    #                                       :allowed_aspect => nil).first
    #
    # if mentions_policy != nil
    #   @protecting_mentions = true
    #   @protected_mentions = [-1]
    #   @hide_mentions = mentions_policy[:hide]
    #   @block_mentions = mentions_policy[:block]
    # else
    #   @protecting_mentions = false
    # end

    # Adding information about Mentions privacy policies
    mention_privacy_policies = PrivacyPolicy.where(:user_id => current_user.id, :shareable_type => "Mentions")

    # Check whether location must be protected
    @protecting_mentions = false

    # Get the blocking and hiding flag from the first row (all row will have the same, TODO makes it per policy basis)
    pp = mention_privacy_policies.first
    if pp != nil
      @protecting_mentions = true
      @block_mentions = pp.block
      @hide_mentions = pp.hide


      # Get all disallowed aspects
      disallowed_aspects = handler.get_user_disallowed_aspects(current_user.id, "Mentions")
      @protected_mentions = []
      disallowed_aspects.each do |da|
        @protected_mentions.push(da)
      end
    end

    # Adding information about Pictures privacy policies
    pictures_privacy_policies = PrivacyPolicy.where(:user_id => current_user.id, :shareable_type => "Pictures")

    # Check whether location must be protected
    @protecting_pics = false

    # Get the blocking and hiding flag from the first row (all row will have the same, TODO makes it per policy basis)
    pp = pictures_privacy_policies.first
    if pp != nil
      @protecting_pics = true
      @block_pics = pp.block
      @hide_pics = pp.hide


      # Get all disallowed aspects
      disallowed_aspects = handler.get_user_disallowed_aspects(current_user.id, "Pictures")
      @protected_pics = []
      disallowed_aspects.each do |da|
        @protected_pics.push(da)
      end
    end

    evolving_location_policy = PrivacyPolicy.where(:user_id => current_user.id,
                                                   :shareable_type => "evolving-location",
                                                   :allowed_aspect => -1).first
    if evolving_location_policy != nil
      @evolving_location = true
    else
      @evolving_location = false
    end

    evolving_weekend_policy = PrivacyPolicy.where(:user_id => current_user.id,
                                                  :shareable_type => "weekend-location")
    if evolving_weekend_policy.blank?
      @weekend_location = false
    else
      @weekend_location = true
      @weekend_pics = []
      evolving_weekend_policy.each do |wa|
        @weekend_pics.push(wa.allowed_aspect)
      end
    end
    # if evolving_weekend_policy != nil
    #   @weekend_location = true
    # else
    #   @weekend_location = false
    # end

    # ------------- Added by me ---------------


    # Testing the kbl module
    @pred = Kbl::Ment.new("Gerardito", "Raulito")
    puts(@pred.to_s)

  end

  # ----------------------------------------- Added by me ----------------------------------------------------
  def set_privacy_policies
    # if :protect_location is equal to 1 it means that it was marked, if
    # :protect_location is empty it means that is was not

    puts("Nothing was selected") if params[:location_aspects] == nil

    # Create a privacy handler to add or remove privacy policies
    handler = Privacy::Handler.new

    # First we take care of the location policies

    # We check that the user checked to protect her/his location to
    # any of the her/his aspects
    if params[:location_aspects] != nil
      # --------------------------- TODO
      # First we remove all rows regarding the location policy
      handler.reset_policies("Location",current_user.id)
      # Now we have to create one row per selected aspect

      # We take the aspects which have access to the location
      ## First we get all the aspects ids of the user
      aspects = handler.get_user_aspect_ids(current_user.id)
      # Finally, we subtract the aspects are not allowed, i.e. the ones selected
      # in the UI (note that -1 does not appear in the array aspects therefore
      # it will never be in allowed_aspects)
      allowed_aspects = aspects.map(&:to_i) - params[:location_aspects].map(&:to_i)

      # We checke whether everyone was selected, and if so we only add that privacy policy
      if params[:location_aspects].map(&:to_i).include? -1
        handler.add_policy(current_user.id,"Location",params[:block_location],params[:hide_location],-1)
      else
        # Otherwise, for each allowed aspect we add a privacy policy
        allowed_aspects.each do |p|
          handler.add_policy(current_user.id,"Location",params[:block_location],params[:hide_location],p)
        end
      end
    else
      # --------------------------- TODO
      # If none of the aspects were selected, the user is allowing
      # everyone to access (in the audience of the post) to access the
      # information, therefore we remove all privacy policies
      handler.reset_policies("Location",current_user.id)
    end




    # Informing and storing user about protecting his/her mentions
    if params[:protect_mentions]
      # --------------------------- TODO
      # First we remove all rows regarding the location policy
      handler.reset_policies("Mentions",current_user.id)
      # Now we have to create one row per selected aspect

      # We take the aspects which have access to the location
      ## First we get all the aspects ids of the user
      aspects = handler.get_user_aspect_ids(current_user.id)
      # Finally, we subtract the aspects are not allowed, i.e. the ones selected
      # in the UI (note that -1 does not appear in the array aspects therefore
      # it will never be in allowed_aspects)
      allowed_aspects = aspects.map(&:to_i) - params[:mentions_aspects].map(&:to_i)

      # We checke whether everyone was selected, and if so we only add that privacy policy
      if params[:mentions_aspects].map(&:to_i).include? -1
        handler.add_policy(current_user.id,"Mentions",params[:block_mentions],params[:hide_mentions],-1)
      else
        # Otherwise, for each allowed aspect we add a privacy policy
        allowed_aspects.each do |p|
          handler.add_policy(current_user.id,"Mentions",params[:block_mentions],params[:hide_mentions],p)
        end
      end
    else
      # --------------------------- TODO
      # If none of the aspects were selected, the user is allowing
      # everyone to access (in the audience of the post) to access the
      # information, therefore we remove all privacy policies
      handler.reset_policies("Mentions",current_user.id)
    end

    if params[:protect_pics]
      # --------------------------- TODO
      # First we remove all rows regarding the location policy
      handler.reset_policies("Pictures",current_user.id)
      # Now we have to create one row per selected aspect

      # We take the aspects which have access to the location
      ## First we get all the aspects ids of the user
      aspects = handler.get_user_aspect_ids(current_user.id)
      # Finally, we subtract the aspects are not allowed, i.e. the ones selected
      # in the UI (note that -1 does not appear in the array aspects therefore
      # it will never be in allowed_aspects)
      allowed_aspects = aspects.map(&:to_i) - params[:pics_aspects].map(&:to_i)

      # We checke whether everyone was selected, and if so we only add that privacy policy
      if params[:pics_aspects].map(&:to_i).include? -1
        handler.add_policy(current_user.id,"Pictures",params[:block_pics],params[:hide_pics],-1)
      else
        # Otherwise, for each allowed aspect we add a privacy policy
        allowed_aspects.each do |p|
          handler.add_policy(current_user.id,"Pictures",params[:block_pics],params[:hide_pics],p)
        end
      end
    else
      # --------------------------- TODO
      # If none of the aspects were selected, the user is allowing
      # everyone to access (in the audience of the post) to access the
      # information, therefore we remove all privacy policies
      handler.reset_policies("Pictures",current_user.id)
    end



    # !!!!!!Think how to start it once at the beginning and no more times!!!!!!!!!1

    # Create a handler to add policies to the database
    # Now initialised at the beginning of the method

    # Create an automaton controller
    automaton = Privacy::Automata.new(true)
    if params[:evolving_location]
      #Start automaton (if it wasn't before)
      if (defined?($larva_running)).nil?
        puts "Larva was not running, therefore we start it"
        automaton.startLarvaProtocol()
        #Indicate the larva is running
        $larva_running = true
      else
        puts "Larva was already running, therefore we only add the evolving policy to the database"
      end
      #Add the policy to the database
      handler.add_policy(current_user.id,"evolving-location",0,0,-1)
    else
      puts "Deleting location evolving policy of user " + current_user.id.to_s
      handler.delete_policy("evolving-location",current_user.id)
    end



    # TO-DO: Think of how to remove all the repeted code!!!!!!!!!!!!!!!!
    if params[:weekend_location]
      #Start automaton (if it wasn't before)
      if (defined?($larva_running)).nil?
        puts "Larva was not running, therefore we start it"
        automaton.startLarvaProtocol()
        #Indicate the larva is running
        $larva_running = true
      else
        puts "Larva was already running, therefore we only add the evolving policy to the database"
      end
      if (defined?($weekend_running)).nil?
        automaton.startLarvaWeekendNotifier()
      else
        puts "Weekend notifier already running"
      end
      #Add the policy to the database
      # aspects = handler.get_user_aspect_ids(current_user.id)
      # allowed_aspects = aspects.map(&:to_i) - params[:weekend_aspects].map(&:to_i)

      # if params[:weekend_aspects].map(&:to_i).include? -1
      #   handler.add_policy(current_user.id,"weekend-location",0,0,-1)
      # else
      #   # Otherwise, for each allowed aspect we add a privacy policy
      handler.reset_policies("weekend-location",current_user.id)
      params[:weekend_aspects].each do |a|
        handler.add_policy(current_user.id,"weekend-location",0,0,a)
      end
      # end
    else
      puts "Deleting weekend-location evolving policy of user " + current_user.id.to_s
      handler.delete_policy("weekend-location",current_user.id)
    end

    message_to_show = "Your privacy policies have been successfully updated"

    flash[:notice] = message_to_show

    # We go back to the privacy page
    redirect_to '/privacy'
  end

  # Auxiliary function to add privacy policies to the database
  # TODO: Move this method to an external library file
  def add_policy(shareable, to_block, to_hide)
    return_message = ""
    user = current_user
    policyTemp = PrivacyPolicy.where(:user_id => user.id,
                                     :shareable_type => shareable).first
      if policyTemp != nil
        return_message = "Diaspora is already protecting your " + shareable
      else
        policy = PrivacyPolicy.new(:user_id => user.id,
                                   :shareable_type => shareable,
                                   :block => to_block == "yes" ? 1 : 0, # Take the input from the user
                                   :hide => to_hide == "yes" ? 1 : 0, # Take the input from the user
                                   :allowed_aspect => nil) # Take the input from the user
        policy.save
        return_message = "Diaspora is protecting your " + shareable
      end
    return return_message
  end

  # Auxiliary function to delete privacy policies from the database
  # TODO: Move this method to an external library file
  def delete_policy(shareable)
    user = current_user
    policy = PrivacyPolicy.where(:user_id => user.id,
                                  :shareable_type => shareable).first
    policy.destroy if policy != nil
    return "Diaspora is *NOT* protecting your " + shareable
  end


  def update
    password_changed = false
    @user = current_user

    if u = user_params
      u.delete(:password) if u[:password].blank?
      u.delete(:password_confirmation) if u[:password].blank? and u[:password_confirmation].blank?
      u.delete(:language) if u[:language].blank?

      # change email notifications
      if u[:email_preferences]
        @user.update_user_preferences(u[:email_preferences])
        flash[:notice] = I18n.t 'users.update.email_notifications_changed'
      # change password
      elsif u[:current_password] && u[:password] && u[:password_confirmation]
        if @user.update_with_password(u)
          password_changed = true
          flash[:notice] = I18n.t 'users.update.password_changed'
        else
          flash[:error] = I18n.t 'users.update.password_not_changed'
        end
      elsif u[:show_community_spotlight_in_stream] || u[:getting_started]
        if @user.update_attributes(u)
          flash[:notice] = I18n.t 'users.update.settings_updated'
        else
          flash[:notice] = I18n.t 'users.update.settings_not_updated'
        end
      elsif u[:language]
        if @user.update_attributes(u)
          I18n.locale = @user.language
          flash[:notice] = I18n.t 'users.update.language_changed'
        else
          flash[:error] = I18n.t 'users.update.language_not_changed'
        end
      elsif u[:email]
        @user.unconfirmed_email = u[:email]
        if @user.save
          @user.mail_confirm_email == @user.email
          if @user.unconfirmed_email
            flash[:notice] = I18n.t 'users.update.unconfirmed_email_changed'
          end
        else
          flash[:error] = I18n.t 'users.update.unconfirmed_email_not_changed'
        end
      elsif u[:auto_follow_back]
        if  @user.update_attributes(u)
          flash[:notice] = I18n.t 'users.update.follow_settings_changed'
        else
          flash[:error] = I18n.t 'users.update.follow_settings_not_changed'
        end
      end
    end

    respond_to do |format|
      format.js   { render :nothing => true, :status => 204 }
      format.all  { redirect_to password_changed ? new_user_session_path : edit_user_path }
    end
  end

  def destroy
    if params[:user] && params[:user][:current_password] && current_user.valid_password?(params[:user][:current_password])
      current_user.close_account!
      sign_out current_user
      redirect_to(stream_path, :notice => I18n.t('users.destroy.success'))
    else
      if params[:user].present? && params[:user][:current_password].present?
        flash[:error] = t 'users.destroy.wrong_password'
      else
        flash[:error] = t 'users.destroy.no_password'
      end
      redirect_to :back
    end
  end

  def public
    if @user = User.find_by_username(params[:username])
      respond_to do |format|
        format.atom do
          @posts = Post.where(author_id: @user.person_id, public: true)
                    .order('created_at DESC')
                    .limit(25)
                    .map {|post| post.is_a?(Reshare) ? post.absolute_root : post }
                    .compact
        end

        format.any { redirect_to person_path(@user.person) }
      end
    else
      redirect_to stream_path, :error => I18n.t('users.public.does_not_exist', :username => params[:username])
    end
  end

  def getting_started
    @user     = current_user
    @person   = @user.person
    @profile  = @user.profile

    respond_to do |format|
    format.mobile { render "users/getting_started" }
    format.all { render "users/getting_started", layout: "with_header_with_footer" }
    end
  end

  def getting_started_completed
    user = current_user
    user.getting_started = false
    user.save
    redirect_to stream_path
  end

  def export
    exporter = Diaspora::Exporter.new(Diaspora::Exporters::XML)
    send_data exporter.execute(current_user), :filename => "#{current_user.username}_diaspora_data.xml", :type => :xml
  end

  def export_photos
    tar_path = PhotoMover::move_photos(current_user)
    send_data( File.open(tar_path).read, :filename => "#{current_user.id}.tar" )
  end

  def user_photo
    username = params[:username].split('@')[0]
    user = User.find_by_username(username)
    if user.present?
      redirect_to user.image_url
    else
      render :nothing => true, :status => 404
    end
  end

  def confirm_email
    if current_user.confirm_email(params[:token])
      flash[:notice] = I18n.t('users.confirm_email.email_confirmed', :email => current_user.email)
    elsif current_user.unconfirmed_email.present?
      flash[:error] = I18n.t('users.confirm_email.email_not_confirmed')
    end
    redirect_to edit_user_path
  end

  # Added by me
  def protect_location
    puts("I'm protecting your location")
  end

  private

  def user_params
    params.fetch(:user).permit(
      :email,
      :current_password,
      :password,
      :password_confirmation,
      :language,
      :disable_mail,
      :invitation_service,
      :invitation_identifier,
      :show_community_spotlight_in_stream,
      :auto_follow_back,
      :auto_follow_back_aspect_id,
      :remember_me,
      :getting_started,
      email_preferences: [
        :someone_reported,
        :also_commented,
        :mentioned,
        :comment_on_post,
        :private_message,
        :started_sharing,
        :liked,
        :reshared
      ]
    )
  end
end
