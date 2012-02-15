fs = require 'fs'
path = require 'path'
request = require 'request'
oembed = require 'oembed'
{ resize } = require 'imagemagick'

exports.getNow = ->
    new Date().getTime()

exports.pick_randomly = (a...) ->
    a[Math.floor(Math.random() * a.length)]




exports.download = (url, callback) ->
    return unless url?
    oembed.fetch url,  {}, (err, info) ->
        return console.error("oembederr", err, info) if err or not info.thumbnail_url?
#         console.log "info", info
#         return if info.thumbnail_url.toLowerCase().indexOf('.png') is -1
        request url:info.thumbnail_url, encoding:'binary', (err, res, data) ->
#             console.log "link", info.thumbnail_url, data?.length
            if res.statusCode is 200
                callback?(info.thumbnail_url, data)


exports.resize = (url, size, data, callback) ->
    ext = path.extname(url)
    if ext.indexOf('.')
        ext = null
    else
        ext = ext[1 ..]
#     console.log data
    s = Math.max(size.width, size.height)
    resize {
        srcData:data
        format:'png'
        width:off
        height:off
        srcFormat:ext
        customArgs:['-scale',"#{s}x#{s}"]
    }, (err, stdout, stderr) ->
#         console.log "resized", size, err
        callback?(new Buffer stdout, 'binary') unless err
