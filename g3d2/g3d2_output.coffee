net = require 'net'
{ Animation } = require 'animation'
{ getNow } = require './util'

class exports.Output
    constructor: (host="g3d2.hq.c3d2.de", port=1339) ->
        @animation = new Animation
            frame:'50ms'

        @frame = []
        @old_frame = []
        for y in [0..(@height - 1)]
            @frame[y] = []
            @old_frame[y] = []
            for x in [0..(@width - 1)]
                @frame[y][x] = "0"
                @old_frame[y][x] = "0"

        sock = net.connect port, host, =>
            @sock = sock
            try @sock.write "0404\r\n"
            catch err
                console.error "sockerr", err
            @animation.nextTick @loop
        #sock.on 'data', (data) ->
        #    console.log "<< #{data}"
        sock.on 'error', (err) ->
           console.log "SOCKET ERROR", err
        sock.on 'close', =>
            delete @sock
            console.error "G3D2 connection closed"
            process.exit 1

    width: 72

    height: 32

    putPixel: (x, y, r, g, b) ->
        #console.log "putPixel", x, y, r, g, b
        g = Math.ceil(Math.log(g / 255 + 1) * 255)
        @frame[y][x] = ((g >> 4) & 0xF).toString(16)

    flush: =>
        if @sock
            console.log @frame.map((line) -> line.join("")).join("\n")
            frame = @frame.map((line) -> line.join("")).join("")
            try @sock.write "03#{frame}\r\n"
            catch err
                console.error "sockerr", err

    loop: (dt) =>
        lastTick = getNow()
        @on_drain?(dt)
        if @flush()
            now = getNow()
            console.log "frametime", now - lastTick, "ms", "(#{dt}ms)"
            @animation.nextTick @loop
        else
            @sock.once 'drain', =>
                now = getNow()
                console.log "drain---------------------------------------------------------------------------------------------------"
                @loop(now - lastTick + dt)
