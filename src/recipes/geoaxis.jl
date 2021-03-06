frameattrs = (
    width = 1,
    color = :black,
    visible = true,
    style = nothing
)

yaxisattrs = (
    tick = (
    # tick marks
        ticks   = WilkinsonTicks(7; k_min = 5, k_max = 15),
        autolimitmargin = 0.05f0,
        size    = 10f0,
        visible = true,
        color   = RGBA(Colors.colorant"lightgrey", 0.7),
        align   = 0f0,
        width   = 1f0,
        style   = nothing,

        # tick labels
        label = (
            size      = 20f0,
            formatter = Formatting.format,
            visible   = true,
            font      = "DejaVu Sans",
            color     = RGBf0(0, 0, 0),
            spacing   = 20f0,
            padding   = 5f0,
            rotation  = 0f0,
            align     = (:center, :top),
            position  = MakieLayout.Left()::MakieLayout.GridLayoutBase.Side

        ),
    ),
)

xaxisattrs = (
    tick = (
    # tick marks
        ticks   = WilkinsonTicks(7; k_min = 5, k_max = 12),
        autolimitmargin = 0.05f0,
        size    = 10f0,
        visible = true,
        color   = RGBA(Colors.colorant"lightgrey", 0.7),
        align   = 0f0,
        width   = 1f0,
        style   = nothing,

        # tick labels
        label = (
            size      = 20f0,
            formatter = Formatting.format,
            visible   = true,
            font      = "DejaVu Sans",
            color     = RGBf0(0, 0, 0),
            spacing   = 20f0,
            padding   = 5f0,
            rotation  = 0f0,
            align     = (:center, :top),
            position  = MakieLayout.Bottom()::MakieLayout.GridLayoutBase.Side

        ),
    ),
)

@recipe(GeoAxis, limits) do scene
    merge(scene.attributes,
    Theme(
        samples = 100,
        show_axis = false,

        frames = (
            top = frameattrs,
            left = frameattrs,
            right = frameattrs,
            bottom = frameattrs
        ),

        grid = (
            visible = true,
            color   = RGBf0(0, 0, 0),
            width   = 1f0,
            style   = nothing
        ),

        x = xaxisattrs,
        y = yaxisattrs,
    )
    )
end

convert_arguments(::Type{<: GeoAxis}, xmin::Real, xmax::Real, ymin::Real, ymax::Real) = (Rect2D{Float32}(xmin, ymin, xmax - xmin, ymax - ymin),)

function convert_arguments(::Type{<: GeoAxis}, xs::Tuple, ys::Tuple)
    xmin, xmax = xs
    ymin, ymax = ys
    return (Rect2D{Float32}(xmin, ymin, xmax - xmin, ymax - ymin),)
end

function convert_arguments(::Type{<: GeoAxis}, xs::AbstractVector{<: Number}, ys::AbstractVector{<: Number})
    xmin, xmax = extrema(xs)
    ymin, ymax = extrema(ys)
    return (Rect2D{Float32}(xmin, ymin, xmax - xmin, ymax - ymin),)
end

# function AbstractPlotting.calculated_attributes!(plot::GeoAxis)
#     @extract plot (x, y, limits)
#
#     lift(limits, x.tick.label.size, y.tick.label.size) do limits, xticklabelsize, yticklabelsize
#         newrect = [limits[LEFT] limits[TOP]; limits[RIGHT] limits[BOTTOM]]
#         textscale = maximum(diff.(eachcol(newrect)))
#
#         x.tick.label.textsize[] = xticklabelsize * textscale/100
#         y.tick.label.textsize[] = yticklabelsize * textscale/100
#
#     end
#
# end

function AbstractPlotting.plot!(plot::GeoAxis{T}) where T

    @extract plot (x, y)

    draw_frames!(plot)

    draw_ticks!(plot)

end

function draw_frames!(plot::GeoAxis{T}) where T

    @extract plot (frames, samples)

    @extract frames (top, bottom, left, right)


    # initialize frames
    topline = Observable(Vector{Point2f0}())
    bottomline = Observable(Vector{Point2f0}())
    leftline = Observable(Vector{Point2f0}())
    rightline = Observable(Vector{Point2f0}())

    # initialize the line vectors
    lift(plot.limits, samples) do lims, samples

        lonrange = LinRange(MakieLayout.left(lims), MakieLayout.right(lims), samples)
        latrange = LinRange(MakieLayout.bottom(lims), MakieLayout.top(lims), samples)

        topline[] = Point2f0.(lonrange, MakieLayout.top(lims))
        leftline[] = Point2f0.(MakieLayout.left(lims), latrange)
        rightline[] = Point2f0.(MakieLayout.right(lims), latrange)
        bottomline[] = Point2f0.(lonrange, MakieLayout.bottom(lims))

    end

    # plot the frames
    lines!.(
        plot,
        (top, bottom, left, right),                # forward the frame attributes
        (topline, bottomline, leftline, rightline) # pass the lines
    )

end

function draw_ticks!(plot::GeoAxis)

    @extract plot (x, y)

    xtickvalues = Observable{Vector{<: AbstractFloat}}(Vector{Float64}())
    ytickvalues = Observable{Vector{<: AbstractFloat}}(Vector{Float64}())

    xlinevec = Observable(Vector{Point2f0}())
    ylinevec = Observable(Vector{Point2f0}())

    xtickannotations = Observable(Vector{Tuple{String, Point2f0}}())
    ytickannotations = Observable(Vector{Tuple{String, Point2f0}}())

    lift(x.tick.ticks, y.tick.ticks, x.tick.label.position, y.tick.label.position, plot.limits, plot.samples, x.tick.label.size, y.tick.label.size) do xticks_struct, yticks_struct, xtickp, ytickp, limits, samples, xticklabelsize, yticklabelsize

        xtickvalues[] = MakieLayout.get_tickvalues(xticks_struct, MakieLayout.left(limits), MakieLayout.right(limits))
        ytickvalues[] = MakieLayout.get_tickvalues(yticks_struct, MakieLayout.bottom(limits), MakieLayout.top(limits))

        xticklabels = MakieLayout.get_ticklabels(AbstractPlotting.automatic, xtickvalues[])
        yticklabels = MakieLayout.get_ticklabels(AbstractPlotting.automatic, ytickvalues[])

        # silently update the backend value without calling
        # these Observables' listener functions.
        xlinevec.val = Vector{Point2f0}()
        ylinevec.val = Vector{Point2f0}()

        for xtick in xtickvalues[]
            append!(xlinevec.val,
                Point2f0.(
                    xtick,
                    LinRange(
                        MakieLayout.bottom(limits),
                        MakieLayout.top(limits),
                        samples
                    )
                )
            )
            push!(xlinevec.val, Point2f0(NaN))
        end
        for ytick in ytickvalues[]
            append!(ylinevec.val,
                Point2f0.(
                    LinRange(
                        MakieLayout.left(limits),
                        MakieLayout.right(limits),
                        samples
                    ),
                    ytick
                )
            )
            push!(ylinevec.val, Point2f0(NaN))
        end

        # notify the observables that they have changed
        AbstractPlotting.notify!(xlinevec)
        AbstractPlotting.notify!(ylinevec)

        # now for the tick placement

        # first, we do the y ticks (latitude)
        ytickpositions, ytickstrings = (nothing, nothing)

        if typeof(ytickp) <: MakieLayout.GridLayoutBase.Side

            xpos = if ytickp == Left()
                MakieLayout.GridLayoutBase.left(limits)
            else
                MakieLayout.GridLayoutBase.right(limits)
            end

            ytickpositions = Point2f0.(xpos, ytickvalues[])

            ytickstrings = yticklabels

        elseif ytickp isa NTuple{2, <: MakieLayout.GridLayoutBase.Side}

            xpos1 = if ytickp[1] == Left()
                MakieLayout.GridLayoutBase.left(limits)
            else
                MakieLayout.GridLayoutBase.right(limits)
            end
            xpos2 = if ytickp[2] == Left()
                MakieLayout.GridLayoutBase.left(limits)
            else
                MakieLayout.GridLayoutBase.right(limits)
            end

            ytickpositions = Point2f0.([(x, y) for x in (xpos1, xpos2), y in ytickvalues[]])

            ytickstrings = repeat(yticklabels, 2)

        else
            @warn "Unsupported tick position format given!"
        end

        (isnothing(ytickstrings) || isnothing(ytickpositions)) || (ytickannotations[] = to2tuple.(ytickstrings, ytickpositions))

        xtickpositions, xtickstrings = (nothing, nothing)

        if typeof(xtickp) <: MakieLayout.GridLayoutBase.Side

            ypos = if ytickp == Top()
                MakieLayout.GridLayoutBase.top(limits)
            else
                MakieLayout.GridLayoutBase.bottom(limits)
            end

            xtickpositions = Point2f0.(xtickvalues[], ypos)

            xtickstrings = xticklabels

        elseif xtickp isa NTuple{2, <: MakieLayout.GridLayoutBase.Side}

            ypos1 = if ytickp[1] == Top()
                MakieLayout.GridLayoutBase.top(limits)
            else
                MakieLayout.GridLayoutBase.bottom(limits)
            end
            ypos2 = if ytickp[2] == Top()
                MakieLayout.GridLayoutBase.top(limits)
            else
                MakieLayout.GridLayoutBase.bottom(limits)
            end

            xtickpositions = Point2f0.([(x, y) for y in (ypos1, ypos2), x in xtickvalues[]])

            xtickstrings = repeat(xticklabels, 2)

        else
            @warn "Unsupported tick position format given!" xtickp
        end

        (isnothing(xtickstrings) || isnothing(xtickpositions)) || (xtickannotations[] = to2tuple.(xtickstrings, xtickpositions))

    end

    # plot the damn thing

    # x ticks
    lines!(
        plot,
        xlinevec;
        visible = x.tick.visible,
        color   = x.tick.color,
        align   = x.tick.align,
        linewidth = x.tick.width,
        linestyle = x.tick.style,
    )
    # y ticks
    lines!(
        plot,
        ylinevec;
        visible = y.tick.visible,
        color   = y.tick.color,
        align   = y.tick.align,
        linewidth = y.tick.width,
        linestyle = y.tick.style,
    )

    # annotations

    annotations!(
        plot,
        x.tick.label,
        xtickannotations;
    )

    annotations!(
        plot,
        y.tick.label,
        ytickannotations;
    )

end
