{ Animation } = require 'animation'
SDL = require 'sdl'
SDL.init SDL.INIT.VIDEO
SDL.events.on 'QUIT', -> process.exit 0

process.on 'uncaughtException', (err) ->
    console.log('Caught exception: ', err)

W = 72
H = 32
ZOOM = 16
COLORS = 16

class exports.Output
    constructor: ->
        @animation = new Animation
            frame:'50ms'
        @screen = SDL.setVideoMode @width * ZOOM, @height * ZOOM, 24, SDL.SURFACE.SWSURFACE

        @animation.on('tick', @loop)
        @animation.start()

    width:
        W

    height:
        H

    putPixel: (x, y, r, g, b) ->
        size = Math.max(ZOOM - 1, 1)
#         color_step = 255 / COLORS
#         green = Math.ceil(Math.floor(g / color_step) * color_step)
        SDL.fillRect @screen, [x * ZOOM, y * ZOOM, size, size], SDL.mapRGB @screen.format, r, g, b#green << 8

    flush: ->
        SDL.flip @screen

    loop: (dt) =>
        @on_drain?()
        @flush()

