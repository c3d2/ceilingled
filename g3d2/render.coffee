Canvas = require('canvas')

{ Output } = require './sdl_output'
#{ Output } = require './g3d2_output'
{ getNow, pick_randomly } = require './util'

class exports.Renderer
    constructor: ->
        @output = new Output()
        { @width, @height } = @output
        canvas = new Canvas @width, @height
        @ctx = canvas.getContext('2d');

        @output.on_drain = =>
            @on_drain?()
            @render()

    render: ->
        data = @ctx.getImageData(0, 0, @output.width, @output.height)?.data
        #console.log "data", data
        offset = 0
        for y in [0..@output.height-1]
            for x in [0..@output.width-1]
                [r, g, b] = [data[offset++], data[offset++], data[offset++]]
                offset++
                #console.log "x", x, "y", y, [r, g, b]
                @output.putPixel x, y, r, g, b


class exports.DrawText
    constructor: (@text) ->

    draw: (ctx, t) ->
        th = 16
        padding = 1
        ctx.font = "#{th}px Sans";
        unless @font_lines?
            @font_lines = []
            for line in @text.split(/\n/)
                while line.length > 0
                    i = line.length
                    while i > 1 && ctx.measureText(line.slice(0, i)).width > @width
                        i--
                    @font_lines.push(line.slice(0, i))
                    line = line.slice(i)

        height = padding * 2 + @font_lines.length * th
        ctx.translate(0, -t * Math.max(0, height - @height) + padding)
        ctx.textBaseline = 'top'
        ctx.fillStyle = '#fff'
        for line in @font_lines
            ctx.fillText(line, 0, 0)
            ctx.translate(0, th)


class exports.DrawImg
    constructor: (data) ->
        img = new Canvas.Image
        img.onload = =>
#             console.log "image loaded.", data.length
            @image = img
        img.onerror = (err) =>
            console.error "IMAGE ERRORED:", err
        img.src = data

    draw: (ctx, t) ->
#         return console.log("NO IMAGE!!!!!!!") unless @image?
        return unless @image?
#         console.log "drawImage", @image.width, @image.height

#         min = ceil((@image.height - @height) * t)
#         max = @image.height - min

#         console.log "drawImage", 0, min, @image.width, max
        ctx.translate(0, (@height - @image.height) * t)
        ctx.drawImage @image, 0, 0, @image.width, @image.height

    inspect: () ->
        "IMGBUFFER"

class exports.Transition
    constructor: (@a, @b) ->

    draw: (ctx, t) ->
        if @a?
            ctx.save()
            @prepareA ctx, t
            @a.draw(ctx, 1)
            ctx.restore()

        if @b?
            ctx.save()
            @prepareB ctx, t
            @b.draw(ctx, 0)
            ctx.restore()

    prepareA: (ctx, t) ->

    prepareB: (ctx, t) ->

class exports.BlendTransition extends exports.Transition
    prepareA: (ctx, t) ->
        ctx.globalAlpha = 1 - t

    prepareB: (ctx, t) ->
        ctx.globalAlpha = t

class exports.HorizontalSlideTransition extends exports.Transition
    constructor: ->
        super

        @direction = pick_randomly('left', 'right')

    prepareA: (ctx, t) ->
        if @direction is 'left'
            ctx.translate t * @width, 0
        else
            ctx.translate t * -@width, 0

    prepareB: (ctx, t) ->
        if @direction is 'left'
            ctx.translate (1 - t) * -@width, 0
        else
            ctx.translate (1 - t) * @width, 0

class exports.VerticalSlideTransition extends exports.Transition
    prepareA: (ctx, t) ->
        ctx.translate 0, t * -@height

    prepareB: (ctx, t) ->
        ctx.translate 0, (1 - t) * @height

class exports.RotateTransition extends exports.Transition
    pick_edge: ->
        if @edge?
            return
        @edge = pick_randomly [0, 0],
            [@width, 0], [@width, @height], [0, @height]
        #@edge = [0, 0]
        @anti_edge = [-@edge[0], -@edge[1]]
        @direction = pick_randomly 'up', 'down'
        console.log "edge", @edge, "direction", @direction

    prepareA: (ctx, t) ->
        @pick_edge()

        ctx.translate @edge...
        if @direction is 'up'
            a = -t
        else
            a = t
        ctx.rotate(a * Math.PI / 2)
        ctx.translate @anti_edge...

        ctx.globalAlpha = 1 - t

    prepareB: (ctx, t) ->
        @pick_edge()

        if @direction is 'up'
            a = 1 - t
        else
            a = t - 1
        ctx.translate @edge...
        ctx.rotate(a * Math.PI / 2)
        ctx.translate @anti_edge...

        ctx.globalAlpha = t


class exports.Compositor
    PHASE: 1000
    TRANSITION_PHASE: 2000

    constructor: (@width, @height) ->
        @current = null
        @queue = []
        @state = 'show'

    add: (drawable) ->
        drawable.width = @width
        drawable.height = @height

        @queue.push drawable

    make_transition: (a, b) ->
        klass = pick_randomly exports.BlendTransition, exports.HorizontalSlideTransition, exports.VerticalSlideTransition, exports.RotateTransition
        transition = new klass(a, b)
        transition.width = @width
        transition.height = @height
        transition

    tick: ->
        if @get_t() >= 1
            if @state is 'show'
                @state = 'transition'
                @current = @make_transition(@current, @queue[0])
                @start = getNow()
            else if @state is 'transition'
                @state = 'show'
                delete @current

        unless @current
            @current = @queue.shift()
#             console.log "new current", @current
            @start = getNow()

    get_t: ->
        if @state is 'show'
            phase = @PHASE
        else if @state is 'transition'
            phase = @TRANSITION_PHASE
        if @start
            (getNow() - @start) / phase
        else
            0

    draw: (ctx) ->
        ctx.save()
        @current?.draw(ctx, @get_t())
        ctx.restore()

