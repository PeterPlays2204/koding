kd                   = require 'kd'
React                = require 'kd-react'
immutable            = require 'immutable'
ChatPane             = require 'activity/components/chatpane'
ChatInputWidget      = require 'activity/components/chatinputwidget'
ChatPaneWrapperMixin = require 'activity/components/chatpane/chatpanewrappermixin'

module.exports = class PrivateChatPane extends React.Component

  @defaultProps =
    thread   : immutable.Map()
    messages : immutable.List()


  render: ->
    <div>
      <ChatPane
        thread     = { @props.thread }
        className  = 'PrivateChatPane'
        onSubmit   = { @bound 'onSubmit' }
        onInviteOthers = {@bound 'onInviteOthers'}
        onLoadMore = { @bound 'onLoadMore' }
      >
      </ChatPane>
      <footer className='PrivateChatPane-footer'>
        <ChatInputWidget
          onSubmit         = { @bound 'onSubmit' }
          onCommand        = { @bound 'onCommand' }
          channelId        = { @channel 'id' }
          disabledFeatures = { ['search'] }
          onResize         = { @bound 'onResize' }
          ref              = 'chatInputWidget'
        />
      </footer>
    </div>

React.Component.include.call PrivateChatPane, [ChatPaneWrapperMixin]

