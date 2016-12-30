#   Copyright (c) 2010-2011, Diaspora Inc.  This file is
#   licensed under the Affero General Public License version 3 or later.  See
#   the COPYRIGHT file.

class PhotosController < ApplicationController
  before_filter :authenticate_user!, :except => :show

  respond_to :html, :json

  def show
    @photo = if user_signed_in?
      current_user.photos_from(Person.find_by_guid(params[:person_id])).where(id: params[:id]).first
    else
      Photo.where(id: params[:id], public: true).first
    end

    raise ActiveRecord::RecordNotFound unless @photo
  end

  def index
    @post_type = :photos
    @person = Person.find_by_guid(params[:person_id])

    if @person
      @contact = current_user.contact_for(@person)

      if @contact
        @contacts_of_contact = @contact.contacts
        @contacts_of_contact_count = @contact.contacts.count
      else
        @contact = Contact.new
      end

      @posts = current_user.photos_from(@person, max_time: max_time)

      respond_to do |format|
        format.all { render 'people/show' }
        format.json{ render_for_api :backbone, :json => @posts, :root => :photos }
      end

    else
      flash[:error] = I18n.t 'people.show.does_not_exist'
      redirect_to people_path
    end
  end

  def create
    rescuing_photo_errors do
      if remotipart_submitted?
        @photo = current_user.build_post(:photo, photo_params)
        if @photo.save
          respond_to do |format|
            format.json { render :json => {"success" => true, "data" => @photo.as_api_response(:backbone)} }
          end
        else
          respond_with @photo, :location => photos_path, :error => message
        end
      else
        legacy_create
      end
    end
  end

  def make_profile_photo
    author_id = current_user.person_id
    @photo = Photo.where(:id => params[:photo_id], :author_id => author_id).first

    if @photo
      profile_hash = {:image_url        => @photo.url(:thumb_large),
                      :image_url_medium => @photo.url(:thumb_medium),
                      :image_url_small  => @photo.url(:thumb_small)}

      if current_user.update_profile(profile_hash)
        respond_to do |format|
          format.js{ render :json => { :photo_id  => @photo.id,
                                       :image_url => @photo.url(:thumb_large),
                                       :image_url_medium => @photo.url(:thumb_medium),
                                       :image_url_small  => @photo.url(:thumb_small),
                                       :author_id => author_id},
                            :status => 201}
        end
      else
        render :nothing => true, :status => 422
      end
    else
      render :nothing => true, :status => 422
    end
  end

  def destroy
    photo = current_user.photos.where(:id => params[:id]).first

    if photo
      current_user.retract(photo)

      respond_to do |format|
        format.json{ render :nothing => true, :status => 204 }
        format.html do
          flash[:notice] = I18n.t 'photos.destroy.notice'
          if StatusMessage.find_by_guid(photo.status_message_guid)
              respond_with photo, :location => post_path(photo.status_message)
          else
            respond_with photo, :location => person_photos_path(current_user.person)
          end
        end
      end
    else
      respond_with photo, :location => person_photos_path(current_user.person)
    end
  end

  def edit
    if @photo = current_user.photos.where(:id => params[:id]).first
      respond_with @photo
    else
      redirect_to person_photos_path(current_user.person)
    end
  end

  def encrypt
    abe_path = 'abe-photos/'
    puts "Encrypting the picture!"    
    photo = Photo.where(:id => params[:id]).first
    # current_user.retract(photo) # Delete the picture
    file = File.read(abe_path+'global_conf.json') # Open the configuration file
    data_hash = JSON.parse(file) # Parse it to a hash object

    # TODO: Change operation to 'encrypt'
    data_hash['operation'] = "encrypt"
    data_hash['user_decrypt'] = current_user.id.to_s
    data_hash['image']['path'] = "../public/uploads/images/" + photo[:unprocessed_image] # Update path to the picture to be encrypted
    data_hash['image']['encrypted_image'] = "data/encrypted.jpg" # Update path to the resulting encrypted picture

    coordinates = params[:coordinates]
    data_hash['image']['encrypted_area'] = [coordinates[:y1].to_i, coordinates[:y2].to_i, coordinates[:x1].to_i, coordinates[:x2].to_i] # Update coordinates to encrypt

    File.open(abe_path+"global_conf.json","w") do |f| # Open file to write
      f.write(JSON.pretty_generate data_hash) # Save the updated file
    end

    puts system("python "+abe_path+"waters15.py") # Encrypting the picture \o/
    system("cp "+abe_path+"data/encrypted.jpg public/uploads/images/"+photo[:unprocessed_image])
    system("cp "+abe_path+"data/encrypted.jpg public/uploads/images/scaled_full_"+photo[:unprocessed_image])
    system("cp "+abe_path+"data/encrypted.jpg public/uploads/images/thumb_small_"+photo[:unprocessed_image])
    system("cp "+abe_path+"data/encrypted.jpg public/uploads/images/thumb_medium_"+photo[:unprocessed_image])
    system("cp "+abe_path+"data/encrypted.jpg public/uploads/images/thumb_large_"+photo[:unprocessed_image])

    flash[:notice] = "Picture successfully encrypted! Yeeeeeeeeaaaaaaaahhh"

    file = File.read(abe_path+'data/ct.json') # Open the configuration file
    photo_ct = JSON.parse(file) # Parse it to a hash object
    photo_ct['coordinates'] = [coordinates[:y1].to_i, coordinates[:y2].to_i, coordinates[:x1].to_i, coordinates[:x2].to_i]
    File.open(abe_path+"data/ct.json","w") do |f| # Open file to write
      f.write(JSON.pretty_generate photo_ct) # Save the updated file
    end


    # Add ct to img encryptions
    path_img_encryptions = abe_path+"img-encryptions/"+photo[:unprocessed_image]+".json"
    photo_encryptions = {}
    if File.file?(path_img_encryptions) # If the img was encrypted before just add it
      file = File.read(path_img_encryptions)
      photo_encryptions = JSON.parse(file)
      photo_encryptions["cts"].push(photo_ct)
    else # Otherwise create a new list
      photo_encryptions = {
        "cts" => [photo_ct]
      }
    end
    # Save img encryption
    File.open(path_img_encryptions,"w") do |f| # Open file to write
      f.write(JSON.pretty_generate photo_encryptions)
    end

    respond_to do |format|
      format.js { render :json => {picture_name: photo[:unprocessed_image]} }
    end
  end

  def update
    photo = current_user.photos.where(:id => params[:id]).first
    if photo
      if current_user.update_post( photo, photo_params )
        flash.now[:notice] = I18n.t 'photos.update.notice'
        respond_to do |format|
          format.js{ render :json => photo, :status => 200 }
        end
      else
        flash.now[:error] = I18n.t 'photos.update.error'
        respond_to do |format|
          format.html{ redirect_to [:edit, photo] }
          format.js{ render :status => 403 }
        end
      end
    else
      redirect_to person_photos_path(current_user.person)
    end
  end

  private

  def photo_params
    params.require(:photo).permit(:public, :text, :pending, :user_file, :image_url, :aspect_ids, :set_profile_photo)
  end

  def file_handler(params)
    # For XHR file uploads, request.params[:qqfile] will be the path to the temporary file
    # For regular form uploads (such as those made by Opera), request.params[:qqfile] will be an UploadedFile which can be returned unaltered.
    if not request.params[:qqfile].is_a?(String)
      params[:qqfile]
    else
      ######################## dealing with local files #############
      # get file name
      file_name = params[:qqfile]
      # get file content type
      att_content_type = (request.content_type.to_s == "") ? "application/octet-stream" : request.content_type.to_s
      # create tempora##l file
      file = Tempfile.new(file_name, {:encoding =>  'BINARY'})
      # put data into this file from raw post request
      file.print request.raw_post.force_encoding('BINARY')

      # create several required methods for this temporal file
      Tempfile.send(:define_method, "content_type") {return att_content_type}
      Tempfile.send(:define_method, "original_filename") {return file_name}
      file
    end
  end

  def legacy_create
    if params[:photo][:aspect_ids] == "all"
      params[:photo][:aspect_ids] = current_user.aspects.collect { |x| x.id }
    elsif params[:photo][:aspect_ids].is_a?(Hash)
      params[:photo][:aspect_ids] = params[:photo][:aspect_ids].values
    end

    params[:photo][:user_file] = file_handler(params)

    @photo = current_user.build_post(:photo, params[:photo])

    if @photo.save
      aspects = current_user.aspects_from_ids(params[:photo][:aspect_ids])

      unless @photo.pending
        current_user.add_to_streams(@photo, aspects)
        current_user.dispatch_post(@photo, :to => params[:photo][:aspect_ids])
      end

      if params[:photo][:set_profile_photo]
        profile_params = {:image_url => @photo.url(:thumb_large),
                          :image_url_medium => @photo.url(:thumb_medium),
                          :image_url_small => @photo.url(:thumb_small)}
        current_user.update_profile(profile_params)
      end

      respond_to do |format|
        format.json{ render(:layout => false , :json => {"success" => true, "data" => @photo}.to_json )}
        format.html{ render(:layout => false , :json => {"success" => true, "data" => @photo}.to_json )}
      end
    else
      respond_with @photo, :location => photos_path, :error => message
    end
  end

  def rescuing_photo_errors
    begin
      yield
    rescue TypeError
      message = I18n.t 'photos.create.type_error'
      respond_with @photo, :location => photos_path, :error => message

    rescue CarrierWave::IntegrityError
      message = I18n.t 'photos.create.integrity_error'
      respond_with @photo, :location => photos_path, :error => message

    rescue RuntimeError => e
      message = I18n.t 'photos.create.runtime_error'
      respond_with @photo, :location => photos_path, :error => message
      raise e
    end
  end
end
