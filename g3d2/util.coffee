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
        return if err or not info.thumbnail_url?
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
    resize {
        srcData:data
        width:size.width
        height:size.height
        format:'png'
        srcFormat:ext
    }, (err, stdout, stderr) ->
#         console.log "resized", size, err
        callback?(new Buffer stdout, 'binary') unless err
