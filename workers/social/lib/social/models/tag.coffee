
jraphical = require 'jraphical'
CActivity = require './activity'
KodingError = require '../error'

module.exports = class JTag extends jraphical.Module

  {Relationship} = jraphical

  {ObjectId, ObjectRef, Inflector, daisy, secure, race, signature} = require 'bongo'

  Validators  = require './group/validators'
  {permit}    = require './group/permissionset'

  @trait __dirname, '../traits/filterable'
  @trait __dirname, '../traits/followable'
  @trait __dirname, '../traits/taggable'
  @trait __dirname, '../traits/protected'
  @trait __dirname, '../traits/slugifiable'
  @trait __dirname, '../traits/grouprelated'
  @trait __dirname, '../traits/restrictedquery'
  @trait __dirname, '../traits/notifying'

  @share()

  @set
    softDelete      : yes
    slugifyFrom     : 'title'
    slugTemplate    : ->
      """
      #{if @group is 'koding' then '' else "#{@group}/"}Topics/\#{slug}
      """
    permissions     :
      'read tags'             :
        public                : ['guest', 'member', 'moderator']
        private               : ['member', 'moderator']
      'create tags'           : ['member', 'moderator']
      'freetag content'       : ['member', 'moderator']
      'browse content by tag' : ['member', 'moderator']
      'edit tags'             : ['moderator']
      'delete tags'           : ['moderator']
      'edit own tags'         : ['moderator']
      'delete own tags'       : ['moderator']
      'assign system tag'     : ['moderator']
      'fetch system tag'      : ['moderator']
      'create system tag'     : ['moderator']
      'remove system tag'     : ['moderator']
      # 'delete system tag'     : ['moderator']

    emitFollowingActivities : yes # create buckets for follower / followees
    indexes         :
      # slug          : 'unique'
      title         : 'sparse'
      # group         : 'sparse'
    sharedEvents    :
      static        : ['FollowHappened', 'UnfollowHappened']
      instance      : [
        { name: 'updateInstance' }
      ]
    sharedMethods   :
      instance      :
        modify      :
          (signature Object, Function)
        follow      : [
          (signature Function)
          (signature Object, Function)
        ]
        unfollow:
          (signature Function)
        fetchFollowersWithRelationship:
          (signature Object, Object, Function)
        fetchFollowingWithRelationship:
          (signature Object, Object, Function)
        fetchContents:
          (signature Function)
        fetchContentTeasers: [
          (signature Object, Object, Function)
          (signature Object, Object, Object, Function)
        ]
        addSystemTagToStatusUpdate:
          (signature Object, Function)
        removeTagFromStatus:
          (signature Object, Function)
        delete:
          (signature Function)
        fetchLastInteractors:
          (signature Object, Function)
      static        :
        one: [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        on:
          (signature String, Function)
        some:
          (signature Object, Object, Function)
        create:
          (signature Object, Function)
        count:
          (signature Object, Function)
        fetchCount:
          (signature Function)
        someWithRelationship:
          (signature Object, Object, Function)
        byRelevance: [
          (signature String, Function)
          (signature String, Object, Function)
        ]
        cursor:
          (signature Object, Object, Function)
        cursorWithRelationship:
          (signature Object, Object, Function)
        fetchMyFollowees:
          (signature [Object], Function)
        each: [
          (signature Object, Object, Function)
          (signature Object, Object, Object, Function)
        ]
        fetchSkillTags:
          (signature Object, Object, Function)
        byRelevanceForSkills: [
          (signature String, Function)
          (signature String, Object, Function)
        ]
        fetchSystemTags:
          (signature Object, Object, Function)
        createSystemTag:
          (signature Object, Object, Function)

    schema          :
      title         :
        type        : String
        set         : (value)-> value.trim()
        required    : yes
      slug          :
        type        : String
        default     : (value)-> Inflector.slugify @title.toLowerCase()
        validate    : [
          'invalid tag name'
          (value)->
            0 < value.length <= 256 and /^(?:\d|\w|\-|\+|\#|\.| [^ ])*$/.test(value)
        ]
      body          : String
      counts        :
        followers   :
          type      : Number
          default   : 0
        following   :
          type      : Number
          default   : 0
        tagged      :
          type      : Number
          default   : 0
      meta          : require 'bongo/bundles/meta'
      synonyms      : [String]
      group         : String
      category      :
        type        : String
        default     : "user-tag"
      # owner         : ObjectId
    relationships   :->
      JAccount = require './account'
      creator       :
        targetType  : JAccount
      activity      :
        targetType  : CActivity
        as          : 'follower'
      follower      :
        targetType  : JAccount
        as          : 'follower'
      content       :
        targetType  : [
          "JNewStatusUpdate"
          # "JCodeSnip"
          # "JNewApp"
          # "JLink"
          # "JTutorial"
          # "JAccount"
          # "JOpinion"
          # "JDiscussion"
          # "JCodeShare"
          # 'JBlogPost'

        ]
        as          : 'post'

  constructor:->
    super
    @notifyGroupWhen 'FollowHappened'

  modify: permit
    advanced: [
      { permission: 'edit own tags', validateWith: Validators.own }
      { permission: 'edit tags' }
    ]
    success: (client, formData, callback)->
      {delegate} = client.connection
      if delegate.checkFlag ['super-admin', 'editor']
        modifiedTag = {slug: formData.slug.trim(), _id: $ne: @getId()}
        JTag.one modifiedTag, (err, tag)=>
          if tag
            callback new KodingError "Slug already exists!"
          else
            @update $set: formData, callback
      else
        callback new KodingError 'Access denied'

  fetchContentTeasers:(options, selector, callback)->
    [callback, selector] = [selector, callback] unless callback

    selector or= {}
    selector['data.flags.isLowQuality'] = $ne: yes

    @fetchContents selector, options, (err, contents)->
      if err then callback err
      else if contents.length is 0 then callback null, []
      else
        teasers = []
        collectTeasers = race (i, root, fin)->
          root.fetchTeaser (err, teaser)->
            if err then callback err
            else
              teasers[i] = teaser
              fin()
        , -> callback null, teasers
        collectTeasers node for node in contents

  @handleFreetags = permit 'freetag content',
    success: (client, tagRefs, callbackForEach=->)->
      existingTagIds = []
      daisy queue = [
        ->
          fin =(i)-> if i is tagRefs.length-1 then queue.next()
          tagRefs.forEach (tagRef, i)->
            if tagRef?.$suggest?
              {group} = client.context
              newTag = {title: tagRef.$suggest.trim(), group}
              JTag.one newTag, (err, tag)->
                if err
                  callbackForEach err
                else if tag?
                  callbackForEach null, tag
                  fin i
                else
                  JTag.create client, newTag, (err, tag)->
                    if err
                      callbackForEach err
                    else
                      tagRefs[i] = ObjectRef(tag).data
                      callbackForEach null, tag
                      fin i
            else
              existingTagIds.push ObjectId tagRef.id
              fin i
        ->
          JTag.all (_id: $in: existingTagIds), (err, existingTags)->
            if err
              callbackForEach err
            else
              callbackForEach null, tag for tag in existingTags
      ]


  @create$ = permit 'create tags',
    success: (client, data, callback)->
      data.category = "user-tag"
      @create client, data, callback

  @create = permit 'create tags',
    success: (client, data, callback)->
      {delegate} = client.connection
      {group} = client.context
      tag = new this data
      tag.group = group
      tag.createSlug (err, slug)->
        if err then callback err
        else
          tag.slug = slug.slug
          tag.slug_ = slug.slug
          tag.save (err)->
            if err
              callback err
            else
              tag.addCreator delegate, (err)->
                if err
                  callback err
                else
                  callback null, tag

  @findSuggestions = (client, seed, options, callback)->
    {limit, blacklist, skip, category} = options
    {group} = client.context
    @some {
        group
        title   : seed
        _id     :
          $nin  : blacklist
        category: "user-tag"

      },{
        skip
        limit
        sort    : 'title' : 1
      }, callback

  delete: permit
    advanced: [
      { permission: 'delete own tags', validateWith: Validators.own }
      { permission: 'delete tags' }
    ]
    success: (client, callback)->
      {delegate} = client.connection
      delegate.fetchRole client, (err, role)=>
        if err
          callback err
        else unless role is 'super-admin'
          callback new KodingError 'Access denied'
        else
          tagId = @getId()
          @fetchContents (err, contents)=>
            if err
              callback err
            else
              Relationship.remove {
                $or: [{
                  targetId  : tagId
                  as        : 'tag'
                },{
                  sourceId  : tagId
                  as        : 'post'
                }]
              }, (err)=>
                if err
                  callback err
                else
                  @remove (err)=>
                    if err
                      callback err
                    else
                      @emit 'TagIsDeleted', yes
                      callback null
                      contents.forEach (content)->
                        content.flushSnapshot tagId, (err)->
                          if err then console.log err

  @fetchSkillTags:(selector, options, callback)->
    selector.group = 'koding'
    @some selector, options, callback

  @byRelevanceForSkills = permit 'read tags',
    success: (client, seed, options, callback)->
      client.context.group = 'koding'
      @byRelevance client, seed, options, callback

  makeGroupSelector =(group)->
    if Array.isArray group then $in: group else group

  @one$ = permit 'read tags',
    success:(client, uniqueSelector, options, callback)->
      uniqueSelector.group = makeGroupSelector client.context.group
      @one uniqueSelector, options, callback

  @_some = (client, selector, options, callback)->
    selector.group    = makeGroupSelector client.context.group
    selector.category = "user-tag"
    @some selector, options, callback

  @some$ = permit 'read tags', success: @_some

  # fix: having read activity permission here may lead to obscurity - SY
  @fetchCount = permit 'read activity',
    success:(client, callback)-> @count callback

  @count$ = permit 'read tags',
    success:(client, selector, callback)->
      [callback, selector] = [selector, callback]  unless callback
      selector ?= {}
      selector.group    = makeGroupSelector client.context.group
      selector.category = "user-tag"
      @count selector, callback

  @cursor$ = permit 'read tags',
    success:(client, selector, options, callback)->
      selector.group    = makeGroupSelector client.context.group
      selector.category = "user-tag"
      @cursor selector, options, callback

  @each$ = permit 'read tags',
    success:(client, selector, fields, options, callback)->
      selector.group    = makeGroupSelector client.context.group
      selector.category = "user-tag"
      @each selector, fields, options, callback

  @byRelevance$ = permit 'read tags',
    success: (client, seed, options, callback)->
      @byRelevance client, seed, options, callback

  @fetchSystemTags    = permit 'fetch system tag',
   success: (client, selector, options, callback)->
    selector.group    = makeGroupSelector client.context.group
    selector.category = "system-tag"
    @some selector, options, callback

  addSystemTagToStatusUpdate : permit 'assign system tag',
    success: (client, statusUpdate, callback)->
      callback new KodingError "That is not system tag!" unless @category is "system-tag"
      JNewStatusUpdate = require './messages/newstatusupdate'
      JNewStatusUpdate.one _id:statusUpdate._id, (err, status)=>
        callback err if err
        if status
          tagsArray = [
            slug: @slug
          ]
          status.addTags client, tagsArray , (err)->
            callback err, null
        else
          callback new KodingError "Status not found!"

  @createSystemTag = permit 'create system tag',
    success: (client, data, callback)->
      data.category = "system-tag"
      @create client, data, callback

  removeTagFromStatus  = permit 'remove system tag',
    success: (client, statusUpdate, callback)->
      callback new KodingError "That is not system tag!" unless @category is "system-tag"
      JNewStatusUpdate = require './messages/newstatusupdate'
      JNewStatusUpdate.one id:statusUpdate._id, (err, status)=>
        callback err if err or not status
        Relationship.remove {
          targetId    : @getId()
          sourceId    : status.getId()
        } , callback

  fetchLastInteractors: secure (client, options, callback)->
    {limit}  = options
    limit  or= 3

    Relationship.some {
      as       : "follower"
      sourceId : @getId()
    }, {limit, sort: {'_id' : -1}}, (err, rels)->
      accounts = []
      daisy queue = rels.map (r)->
        ->
          JAccount = require './account'
          JAccount.one _id: r.targetId, (err, acc)->
            accounts.push acc  if !err and acc
            queue.next()

      queue.push -> callback null, accounts
