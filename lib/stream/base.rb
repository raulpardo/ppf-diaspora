class Stream::Base
  TYPES_OF_POST_IN_STREAM = ['StatusMessage', 'Reshare']

  attr_accessor :max_time, :order, :user, :publisher

  def initialize(user, opts={})
    self.user = user
    self.max_time = opts[:max_time]
    self.order = opts[:order]
    self.publisher = Publisher.new(self.user, publisher_opts)
  end

  #requied to implement said stream
  def link(opts={})
    'change me in lib/base_stream.rb!'
  end

  # @return [Boolean]
  def can_comment?(post)
    return true if post.author.local?
    post_is_from_contact?(post)
  end

  def post_from_group(post)
    []
  end

  # @return [String]
  def title
    'a title'
  end

  # @return [ActiveRecord::Relation<Post>]
  def posts
    Post.scoped
  end

  # @return [Array<Post>]
  def stream_posts
    # Temporal array which will contain the posts which can be shown
    returningArray = Array.new

    # -------- Original code -------------
    self.posts.for_a_stream(max_time, order, self.user).tap do |posts|
      like_posts_for_stream!(posts) #some sql person could probably do this with joins.
      # -------- Original code -------------

      # We iterate over all to posts which tentatively will be posted
      posts.each do |p|
        # If the author of the post is not the user accessing the post we
        # proceed to check if (s)he has access to all of them
        if p.author_id != self.user.id
          # Since we are only protecting the user's location if the post does
          # not contain a location can be shown
          if p.address == nil
            returningArray.push(p)
            # Otherwise we proceed to check
          else
            # We get all the users mentioned in the post
            ppl = Diaspora::Mentionable.people_from_string(p.text)
            # We set a counter to 0
            count = 0
            # We iterate over all the mentioned users
            ppl.each do |person|
              # We check the privacy policy about the location of the user
              protecting_loc = PrivacyPolicy.where(:user_id => person.owner_id,
              :shareable_type => "Location")
              checker = Privacy::Checker.new
              people_disallowed = checker.people_from_aspect_ids(protecting_loc.collect{|pp| pp.allowed_aspect})
              # If we get any result it means that the users is protecting her
              # location. And (&&) also we check that the user requesting the
              # post is not the one mentioned

              if people_disallowed.include?(self.user.person_id) && protecting_loc.first.hide
                # if (protecting_loc != nil) && (person.owner_id != self.user.id)
                # Therefore we increment the count
                count = count + 1
                # returningArray.push(pTemp)
              end
            end
            # Finally if there were no users protecting their location we add
            # the post to the posts to be shown
            if count == 0
              returningArray.push(p)
            else
              puts "Not adding the post"
            end
          end
          # If the author of the post is the one checking it we added to the
          # resulset since this user already knows the information.
        else
          returningArray.push(p)
        end
      end
    end

    abe_path = 'abe-photos/'
    decryption = true
    if decryption
      returningArray.each do |post|
        if post.photos.present?
          post.photos.each do |picture|
            # puts "Post " + post.id.to_s + " contains picture " + picture.id.to_s
            decrypted = false
            # Check whether the picture has been encrypted
            if File.file?(abe_path+"img-encryptions/"+picture[:unprocessed_image]+".json")
              path_picture_encryptions = abe_path+"img-encryptions/"+picture[:unprocessed_image]+".json"
              file = File.read(path_picture_encryptions) # Open the configuration file
              data_hash = JSON.parse(file)
              # We try to decrypt for each ct of the picture
              result = false
              data_hash['cts'].each do |ct|
                file = File.read(abe_path+'global_conf.json') # Open the configuration file
                data_hash = JSON.parse(file) # Parse it to a hash object


                data_hash['operation'] = "decrypt" # Update operation to perform
                data_hash['user_decrypt'] = self.user.id.to_s # Update User id
                data_hash['image']['encrypted_area'] = ct['coordinates'] # Update coordinates

                # Update ct file
                File.open(abe_path+"data/ct.json","w") do |f| # Open file to write
                  f.write(JSON.pretty_generate ct) # Save the updated file
                end

                if result
                  data_hash['image']['path'] = "data/decrypted.jpg"# Update path to the encrypted picture
                  data_hash['image']['encrypted_image'] = "data/decrypted.jpg" # Update path to the encrypted picture
                else
                  data_hash['image']['path'] = "../public/uploads/images/" + picture[:unprocessed_image] # Update path to the encrypted picture
                  data_hash['image']['encrypted_image'] = "../public/uploads/images/" + picture[:unprocessed_image] # Update path to the encrypted picture
                end
                data_hash['image']['decrypted_image'] = "data/decrypted.jpg" # Update path to the picture to be decrypted

                # Save the settings for decryption
                File.open(abe_path+"global_conf.json","w") do |f| # Open file to write
                  f.write(JSON.pretty_generate data_hash) # Save the updated file
                end

                # TODO: Try to decrypt the picture
                result = system("python "+abe_path+"waters15.py") # Decrypting the picture \o/
                puts "The decryption was " + (result ? "successful" : "NOT successful")
                decrypted = decrypted || result
              end
              # TODO: Store the decrypted picture
              decrypted_image_name = "decrypted_" + @user.id.to_s + "_"+ picture[:unprocessed_image]
              system("cp "+abe_path+"data/decrypted.jpg public/uploads/images/"+decrypted_image_name)
              system("cp "+abe_path+"data/decrypted.jpg public/uploads/images/scaled_full_"+decrypted_image_name)
              system("cp "+abe_path+"data/decrypted.jpg public/uploads/images/thumb_small_"+decrypted_image_name)
              system("cp "+abe_path+"data/decrypted.jpg public/uploads/images/thumb_medium_"+decrypted_image_name)
              system("cp "+abe_path+"data/decrypted.jpg public/uploads/images/thumb_large_"+decrypted_image_name)

              # TODO: Update the remote_photo_name of the picture
              if decrypted
                puts "The picture was decrypted"
                picture.remote_photo_name = decrypted_image_name
              else
                puts "The picture was NOT decrypted"
                picture.remote_photo_name = picture[:unprocessed_image]
              end
            else
              # If not encrypted we do nothing
            end
          end
        else
          # Nothing for now
        end
      end
    else
      puts "================================================>> Decryption disabled"
    end
    returningArray
  end

  # @return [ActiveRecord::Association<Person>] AR association of people within stream's given aspects
  def people
    people_ids = self.stream_posts.map{|x| x.author_id}
    Person.where(:id => people_ids).
      includes(:profile)
  end

  # @return [String] def contacts_title 'change me in lib/base_stream.rb!'
  def contacts_title
    'change me in lib/base_stream.rb!'
  end

  # @return [String]
  def contacts_link
    Rails.application.routes.url_helpers.contacts_path
  end

  # @return [Boolean]
  def for_all_aspects?
    true
  end

  #NOTE: MBS bad bad methods the fact we need these means our views are foobared. please kill them and make them
  #private methods on the streams that need them
  def aspects
    user.aspects
  end

  # @return [Aspect] The first aspect in #aspects
  def aspect
    aspects.first
  end

  def aspect_ids
    aspects.map{|x| x.id}
  end

  def max_time=(time_string)
    @max_time = Time.at(time_string.to_i) unless time_string.blank?
    @max_time ||= (Time.now + 1)
  end

  def order=(order_string)
    @order = order_string
    @order ||= 'created_at'
  end

  protected
  # @return [void]
  def like_posts_for_stream!(posts)
    return posts unless @user

    likes = Like.where(:author_id => @user.person_id, :target_id => posts.map(&:id), :target_type => "Post")

    like_hash = likes.inject({}) do |hash, like|
      hash[like.target_id] = like
      hash
    end

    posts.each do |post|
      post.user_like = like_hash[post.id]
    end
  end

  # @return [Hash]
  def publisher_opts
    {}
  end

  # Memoizes all Contacts present in the Stream
  #
  # @return [Array<Contact>]
  def contacts_in_stream
    @contacts_in_stream ||= Contact.where(:user_id => user.id, :person_id => people.map{|x| x.id}).all
  end

  # @param post [Post]
  # @return [Boolean]
  def post_is_from_contact?(post)
    @can_comment_cache ||= {}
    @can_comment_cache[post.id] ||= contacts_in_stream.find{|contact| contact.person_id == post.author.id}.present?
    @can_comment_cache[post.id] ||= (user.person_id == post.author_id)
    @can_comment_cache[post.id]
  end
end
