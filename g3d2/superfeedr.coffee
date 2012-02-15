{ Superfeedr } = require 'superfeedr'
{ Renderer, Compositor, DrawText, DrawImg } = require './render'
{ getNow, pick_randomly } = util = require './util'
config = require './config'

require('oembed').EMBEDLY_KEY = config.oembedkey

renderer = new Renderer
compositor = new Compositor renderer.width, renderer.height

renderer.on_drain = ->
    ctx = renderer.ctx

    ctx.fillStyle = '#000'
    ctx.fillRect 0, 0, renderer.width, renderer.height
    ctx.antialias = 'grey'

    compositor.tick()
    compositor.draw renderer.ctx

imgsize = width:renderer.width, height:renderer.height

client = new Superfeedr config.user, config.pass
client.on 'connected', ->
#     client.subscribe "http://en.wikipedia.org/w/index.php?title=Special:RecentChanges&feed=atom", (err, feed) ->
#         console.log "subscribe", err, feed
    client.on 'notification', (notification) ->
#         console.log "notification", notification
#             console.log notification.link?.href
        notification.entries.forEach (notification) ->
            util.download notification.link?.href, (url, data) ->
#                 console.log "file", url
                util.resize url, imgsize, data, (buf) ->
#                     console.log buf
                    compositor.add new DrawImg(buf)
#             compositor.add new DrawText(notification.title)
