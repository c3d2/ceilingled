request = require 'request'
oembed = require 'oembed'
{ Superfeedr } = require 'superfeedr'
{ Renderer, Compositor, DrawText, DrawImg } = require './render'
{ getNow, pick_randomly } = require './util'
config = require './config'

oembed.EMBEDLY_KEY = config.oembedkey

renderer = new Renderer
compositor = new Compositor renderer.width, renderer.height

renderer.on_drain = ->
    ctx = renderer.ctx

    ctx.fillStyle = '#000'
    ctx.fillRect 0, 0, renderer.width, renderer.height
    ctx.antialias = 'grey'

    compositor.tick()
    compositor.draw renderer.ctx


client = new Superfeedr config.user, config.pass
client.on 'connected', ->
#     client.subscribe "http://en.wikipedia.org/w/index.php?title=Special:RecentChanges&feed=atom", (err, feed) ->
#         console.log "subscribe", err, feed
    client.on 'notification', (notification) ->
#         console.log "notification", notification
        notification.entries.forEach (notification) ->
#             console.log notification.link?.href
            if notification.link?.href?
                oembed.fetch notification.link.href,  { maxwidth: 10 }, (err, info) ->
                    return if err or not info.thumbnail_url?
#                     console.log "info", info
                    return if info.thumbnail_url.toLowerCase().indexOf('.png') is -1
                    request info.thumbnail_url, (err, res, data) ->
                        console.log "link", info.thumbnail_url
                        if res.statusCode is 200
                            buf = new Buffer(data, 'binary')
                            console.log buf
                            compositor.add new DrawImg(buf) unless err
#             compositor.add new DrawText(notification.title)
