---------------------------------------------------------------------------
-- A flexible separator widget.
--
-- By default, this widget displays a simple line, but can be extended by themes
-- (or directly) to display much more complex visuals.
--
-- This widget is mainly intended to be used alongside the `spacing_widget`
-- property supported by various layouts such as:
--
-- * `wibox.layout.fixed`
-- * `wibox.layout.flex`
-- * `wibox.layout.ratio`
--
-- When used with these layouts, it is also possible to provide custom clipping
-- functions. This is useful when the layout has overlapping widgets (negative
-- spacing).
--
--@DOC_wibox_widget_defaults_separator_EXAMPLE@
--
-- @author Emmanuel Lepage Vallee &lt;elv1313@gmail.com&gt;
-- @copyright 2014, 2017 Emmanuel Lepage Vallee
-- @widgetmod wibox.widget.separator
-- @supermodule wibox.widget.base
---------------------------------------------------------------------------
local beautiful = require( "beautiful"         )
local base      = require( "wibox.widget.base" )
local color     = require( "gears.color"       )
local gtable    = require( "gears.table"       )

local separator = {}

--- The separator's orientation.
--
-- The default value is selected automatically. If the widget is taller than
-- large, it will use vertical and vice versa.
--
--@DOC_wibox_widget_separator_orientation_EXAMPLE@
--
-- @property orientation
-- @tparam[opt="auto"] string orientation
-- @propertyvalue "vertical" From top to bottom.
-- @propertyvalue "horizontal" From left to right.
-- @propertyvalue "auto" Decide depending on the widget geometry.
-- @propemits true false

--- The separator's thickness.
--
-- This is used by the default line separator, but ignored when a shape is used.
--
-- @property thickness
-- @tparam number|nil thickness
-- @propertyunit pixel
-- @negativeallowed false
-- @propbeautiful
-- @propemits true false

--- The separator's shape.
--
--@DOC_wibox_widget_separator_shape_EXAMPLE@
--
-- @property shape
-- @tparam shape|nil shape A valid shape function
-- @propbeautiful
-- @propemits true false
-- @see gears.shape

--- The relative percentage covered by the bar.
--
-- @property span_ratio
-- @tparam[opt=1] number|nil span_ratio
-- @rangestart 0.0
-- @rangestop 1.0
-- @propertyunit A gradient between "small" (0.0) and "full width/height" (1.0).
-- @propbeautiful
-- @propemits true false

--- The separator's color.
-- @property color
-- @tparam color|nil color
-- @propbeautiful
-- @propemits true false
-- @see gears.color

--- The separator's border color.
--
--@DOC_wibox_widget_separator_border_color_EXAMPLE@
--
-- @property border_color
-- @tparam color|nil border_color
-- @propbeautiful
-- @propemits true false
-- @see gears.color

--- The separator's border width.
-- @property border_width
-- @tparam number|nil border_width
-- @propertyunit pixel
-- @negativeallowed false
-- @propbeautiful
-- @propemits true false

--- The separator thickness.
-- @beautiful beautiful.separator_thickness
-- @tparam[opt=1] number separator_thickness
-- @see thickness

--- The separator border color.
-- @beautiful beautiful.separator_border_color
-- @param color
-- @see border_color

--- The separator border width.
-- @beautiful beautiful.separator_border_width
-- @tparam[opt=0] number separator_border_width
-- @see border_width

--- The relative percentage covered by the bar.
-- @beautiful beautiful.separator_span_ratio
-- @tparam[opt=1] number separator_span_ratio A number between 0 and 1.

--- The separator's color.
-- @beautiful beautiful.separator_color
-- @param color
-- @see gears.color

--- The separator's shape.
--
-- @beautiful beautiful.separator_shape
-- @tparam[opt=gears.shape.rectangle] shape shape A valid shape function
-- @see gears.shape

local function draw_shape(self, _, cr, width, height, shape)
    local bw = self._private.border_width or beautiful.separator_border_width or 0
    local bc = self._private.border_color or beautiful.separator_border_color

    cr:translate(bw/2, bw/2)

    shape(cr, width-bw, height-bw)

    if bw == 0 then
        cr:fill()
    elseif bc then
        cr:fill_preserve()
        cr:set_source(color(bc))
        cr:set_line_width(bw)
        cr:stroke()
    end
end

local function draw_line(self, _, cr, width, height)
    local thickness = self._private.thickness or beautiful.separator_thickness or 1

    local orientation = self._private.orientation ~= "auto" and
        self._private.orientation or (width > height and "horizontal" or "vertical")

    local span_ratio = self.span_ratio or 1

    if orientation == "horizontal" then
        local w = width*span_ratio
        cr:rectangle((width-w)/2, height/2 - thickness/2, w, thickness)
    else
        local h = height*span_ratio
        cr:rectangle(width/2 - thickness/2, (height-h)/2, thickness, h)
    end

    cr:fill()
end

local function draw(self, _, cr, width, height)
    -- In case there is a specialized.
    local draw_custom = self._private.draw or beautiful.separator_draw
    if draw_custom then
        return draw_custom(self, _, cr, width, height)
    end

    local col = self._private.color or beautiful.separator_color

    if col then
        cr:set_source(color(col))
    end

    local s = self._private.shape or beautiful.separator_shape

    if s then
        draw_shape(self, _, cr, width, height, s)
    else
        draw_line(self, _, cr, width, height)
    end
end

local function fit(_, _, width, height)
    return width, height
end

for _, prop in ipairs {"orientation", "color", "thickness", "span_ratio",
                       "border_width", "border_color", "shape" } do
    separator["set_"..prop] = function(self, value)
        self._private[prop] = value
        self:emit_signal("property::"..prop, value)
        self:emit_signal("widget::redraw_needed")
    end
    separator["get_"..prop] = function(self)
        return self._private[prop] or beautiful["separator_"..prop]
    end
end

--- Create a new separator.
-- @constructorfct wibox.widget.separator
-- @tparam table args The arguments (all properties are available).
-- @tparam[opt] string args.orientation The separator's orientation.
-- @tparam[opt] number args.thickness The separator's thickness.
-- @tparam[opt] function args.shape The separator's shape.
-- @tparam[opt] number args.span_ratio The relative percentage covered by the bar.
-- @tparam[opt] color args.color The separator's color.
-- @tparam[opt] color args.border_color The separator's border color.
-- @tparam[opt] number args.border_width The separator's border width.

local function new(args)
    local ret = base.make_widget(nil, nil, {
        enable_properties = true,
    })
    gtable.crush(ret, separator, true)
    gtable.crush(ret, args or {})
    ret._private.orientation = ret._private.orientation or "auto"
    rawset(ret, "fit" , fit )
    rawset(ret, "draw", draw)
    return ret
end

return setmetatable(separator, { __call = function(_, ...) return new(...) end })
-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
