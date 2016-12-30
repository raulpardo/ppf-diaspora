//= require ../../img-selector/jquery.imgareaselect
app.views.StreamPost = app.views.Post.extend({
  templateName: "stream-element",
  className : "stream_element loaded",

  subviews : {
    ".feedback" : "feedbackView",
    ".likes" : "likesInfoView",
    ".comments" : "commentStreamView",
    ".post-content" : "postContentView",
    ".oembed" : "oEmbedView",
    ".opengraph" : "openGraphView",
    ".poll" : "pollView",
    ".status-message-location" : "postLocationStreamView"
  },

  events: {
    "click .focus_comment_textarea": "focusCommentTextarea",
    "click .show_nsfw_post": "removeNsfwShield",
    "click .toggle_nsfw_state": "toggleNsfwState",

    "click .remove_post": "destroyModel",

    "click .stream-photo": "encryptPicture",

    "click .hide_post": "hidePost",
    "click .post_report": "report",
    "click .block_user": "blockUser"
  },

  tooltipSelector : ".timeago, .post_scope, .block_user, .delete",

  initialize : function(){
    var personId = this.model.get('author').id;
    app.events.on('person:block:'+personId, this.remove, this);

    this.model.on('remove', this.remove, this);
    //subviews
    this.commentStreamView = new app.views.CommentStream({model : this.model});
    this.oEmbedView = new app.views.OEmbed({model : this.model});
    this.openGraphView = new app.views.OpenGraph({model : this.model});
    this.pollView = new app.views.Poll({model : this.model});
  },

  encryptPicture: function(evt) {
    evt && evt.preventDefault();
    const photo = this.model.get("photos")[0]; // Get the photo included in the post
                                               // We know that there must be
                                               // picture otherwise the event
                                               // could not be triggered
    let coordinates = {}; //Array to store the selected coordinates to encryt the picture

    function preview(img, selection) {
      if (!selection.width || !selection.height)
      return;
      // Print the current coordinates on the console
      // console.log("Coordinates: x1: " + selection.x1 +
      //                         " y1: " + selection.y1 +
      //                         " x2: " + selection.x2 +
      //                         " y2: " + selection.y2);
      scaling_factor = photo.dimensions.width / $("#"+photo.id).width();
      coordinates.x1 = selection.x1*scaling_factor;
      coordinates.y1 = selection.y1*scaling_factor;
      coordinates.x2 = selection.x2*scaling_factor;
      coordinates.y2 = selection.y2*scaling_factor;
    };

    $("#"+photo.id).imgAreaSelect({
      handles: true,
      onSelectChange: preview
    });

    // =========== Popup menu to encrypt the picture ===========
    $("#selected-area").attr("id","selected-area-"+photo.id);//Change the attribute with the id of the picture
    $("#selected-area-"+photo.id).contextmenu(function(e) { //Bind right click
      e.preventDefault();

      // Show contextmenu
      $(".custom-menu").finish().toggle(100).

      // In the right position (the mouse)
      css({
        top: e.pageY + "px",
        left: e.pageX + "px"
      });
    });

    // If the document is clicked somewhere
    $(document).bind("mousedown", function (e) {
      // If the clicked element is not the menu
      if (!$(e.target).parents(".custom-menu").length > 0) {
        // Hide it
        $(".custom-menu").hide(100);
      }
    });

    function encryptImage(selection) {
      console.log("The user would like to encrypt the following area of picture "+photo.id+":\n"+
                              "x1: " + selection.x1 + ", " +
                              "y1: " + selection.y1 + ", " +
                              "x2: " + selection.x2 + ", " +
                              "y2: " + selection.y2);
      jQuery.ajax({
        url: "photos/"+photo.id+"/encrypt", // it should be mapped in routes.rb in rails
        type: "GET",
        data: {coordinates: selection, user: "not_important"}, // if you want to send some data.
        dataType: "json",
        success: function(data){
          // data will be the response object(json)
          console.log("The picture is successfully encrypted");

          // Refresh the page to fetch the updated picture after encryption
          location.reload();
        }
      });
      return;
    };

    // If the menu element is clicked
    $(".custom-menu li").click(function(){

      // This is the triggered action name
      switch($(this).attr("data-action")) {

        // A case for each action. Your actions here (one per element in the HTML form (defined at status-message_tpl))
        case "encrypt-area": encryptImage(coordinates); break;
        // case "second": alert("second"); break;
        // case "third": alert("third"); break;
      }

      // Hide it AFTER the action was triggered
      $(".custom-menu").hide(100);
    });
  },

  likesInfoView : function(){
    return new app.views.LikesInfo({model : this.model});
  },

  feedbackView : function(){
    if(!app.currentUser.authenticated()) { return null }
    return new app.views.Feedback({model : this.model});
  },

  postContentView: function(){
    var normalizedClass = this.model.get("post_type").replace(/::/, "__")
      , postClass = app.views[normalizedClass] || app.views.StatusMessage;

    return new postClass({ model : this.model })
  },

  postLocationStreamView : function(){
    return new app.views.LocationStream({ model : this.model});
  },

  removeNsfwShield: function(evt){
    if(evt){ evt.preventDefault(); }
    this.model.set({nsfw : false})
    this.render();
  },

  toggleNsfwState: function(evt){
    if(evt){ evt.preventDefault(); }
    app.currentUser.toggleNsfwState();
  },

  blockUser: function(evt){
    if(evt) { evt.preventDefault(); }
    if(!confirm(Diaspora.I18n.t('ignore_user'))) { return }

    this.model.blockAuthor()
      .fail(function() {
        Diaspora.page.flashMessages.render({
          success: false,
          notice: Diaspora.I18n.t('ignore_failed')
        });
      });
  },

  remove : function() {
    $(this.el).slideUp(400, _.bind(function(){this.$el.remove()}, this));
    return this
  },

  hidePost : function(evt) {
    if(evt) { evt.preventDefault(); }
    if(!confirm(Diaspora.I18n.t('confirm_dialog'))) { return }

    $.ajax({
      url : "/share_visibilities/42",
      type : "PUT",
      data : {
        post_id : this.model.id
      }
    })

    this.remove();
  },

  focusCommentTextarea: function(evt){
    evt.preventDefault();
    this.$(".new_comment_form_wrapper").removeClass("hidden");
    this.$(".comment_box").focus();

    return this;
  }

})
