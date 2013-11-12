class GroupPackEditForm extends KDFormViewWithFields
  constructor: (options = {}, data = new KD.remote.api.JPaymentPack) ->
    options.fields ?= {}

    model = data  if data.planCode

    options.callback ?= =>
      @emit 'SaveRequested', model, @getProductData()

    options.buttons ?=
      Save        :
        cssClass  : "modal-clean-green"
        type      : "submit"
      cancel      :
        cssClass  : "modal-cancel"
        callback  : => @emit 'CancelRequested'

    options.fields ?= {}

    options.fields.title ?=
      label           : "Title"
      placeholder     : options.placeholders?.title
      defaultValue    : data.decoded 'title'
      required        : 'Title is required!'

    options.fields.description ?=
      label           : "Description"
      placeholder     : options.placeholders?.description or "(optional)"
      defaultValue    : data.decoded 'description'

    super options, data

  getProductData: @::getData