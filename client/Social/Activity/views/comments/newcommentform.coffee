class NewCommentForm extends KDView

  constructor: (options = {}, data) ->

    options.type       or= "new-comment"
    options.cssClass     = KD.utils.curry "item-add-comment-box", options.cssClass
    options.showAvatar  ?= yes

    super options, data

    @input          = new KDHitEnterInputView
      type          : "textarea"
      delegate      : this
      placeholder   : "Type your comment and hit enter..."
      autogrow      : yes
      validate      :
        rules       :
          required  : yes
          maxLength : 2000
        messages    :
          required  : "Please type a comment..."
      callback      : @bound "enter"

    @input.on "focus", @bound "inputFocused"
    @input.on "blur", @bound "inputBlured"


  submit: ->

    @emit "Submit", @input.getValue()


  enter: ->

    kallback = =>

      @submit()

      KD.mixpanel "Comment activity, click", @input.getValue().length

      @input.setValue ""
      @input.resize()
      @input.setBlur()

    KD.requireMembership
      callback  : kallback
      onFailMsg : "Login required to post a comment!"
      tryAgain  : yes
      groupName : KD.getGroup().slug


  setFocus: ->

    @input.setFocus()
    KD.singleton("windowController").setKeyView @input


  inputFocused: ->

    @emit "Focused"
    KD.mixpanel "Comment activity, focus"


  inputBlured: ->

    return  unless @input.getValue() is ""
    @emit "Blured"


  viewAppended: ->

    if @getOption "showAvatar"
      @addSubView new AvatarStaticView
        size    :
          width : 42
          height: 42
      , KD.whoami()

    @addSubView @input
