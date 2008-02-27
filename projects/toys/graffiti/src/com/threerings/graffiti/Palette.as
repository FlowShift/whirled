// $Id$

package com.threerings.graffiti {

import flash.display.GradientType;
import flash.display.Graphics;
import flash.display.Sprite;

import flash.events.MouseEvent;

import flash.geom.Matrix;
import flash.geom.Point;

import com.threerings.util.Log;

public class Palette extends Sprite
{
    public static const PALETTE_WIDTH :int = 100;
    public static const PALETTE_HEIGHT :int = 
        PADDING * 4 + INDICATOR_HEIGHT + WHEEL_RADIUS * 2 + MANIPULATOR_HEIGHT;

    public function Palette (toolbox :ToolBox, initialColor :uint)
    {
        _toolbox = toolbox;

        buildIndicator(initialColor);
        buildWheel();
        displayManipulator(initialColor);
    }

    protected function buildIndicator (initialColor :int) :void
    {
        _selectedColor = initialColor;
        addChild(_indicator = new Sprite());
        _indicator.x = (PALETTE_WIDTH - INDICATOR_WIDTH) / 2;
        _indicator.y = PADDING;
        var g :Graphics = _indicator.graphics;
        g.beginFill(initialColor);
        drawIndicatorBorder();
        g.endFill();
    }

    protected function drawIndicatorBorder () :void
    {
        var g :Graphics = _indicator.graphics;
        g.lineStyle(3, COMPONENT_BORDER_COLOR);
        g.drawRoundRect(0, 0, INDICATOR_WIDTH, INDICATOR_HEIGHT, 2, 2);
    }

    protected function pickColor (color :int) :void
    {
        _selectedColor = color;
        _toolbox.pickColor(color);

        // the right half of the indicator is for the currently selected color
        var g :Graphics = _indicator.graphics;
        g.lineStyle(0, color);
        g.beginFill(color);
        g.drawRect(INDICATOR_WIDTH / 2, 1, INDICATOR_WIDTH / 2 - 2, INDICATOR_HEIGHT - 1);
        g.endFill();
        drawIndicatorBorder();
    }

    protected function hoverColor (color :int) :void
    {
        // the left half of the indicator is for the hover color
        var g :Graphics = _indicator.graphics;
        g.lineStyle(0, color);
        g.beginFill(color);
        g.drawRect(1, 1, INDICATOR_WIDTH / 2, INDICATOR_HEIGHT - 1);
        g.endFill();
        drawIndicatorBorder();
        displayManipulator(color);
    }

    protected function buildWheel () :void
    {
        addChild(_wheel = new Sprite());
        _wheel.x = WHEEL_RADIUS + (PALETTE_WIDTH - WHEEL_RADIUS * 2) / 2;
        _wheel.y = WHEEL_RADIUS + PADDING * 2 + INDICATOR_HEIGHT;
        var g :Graphics = _wheel.graphics;

        // start by drawing a color wheel...
        for (var ii :int = 0; ii < 360; ii++) {
            g.lineStyle(1, colorForAngle(ii));
            g.moveTo(0, 0);
            var end :Point = Point.polar(WHEEL_RADIUS, ii * Math.PI / 180);
            g.lineTo(-end.x, end.y);
        }

        _wheel.addEventListener(MouseEvent.MOUSE_OUT, function (event :MouseEvent) :void {
            hoverColor(_selectedColor);
        });
        _wheel.addEventListener(MouseEvent.MOUSE_MOVE, function (event :MouseEvent) :void {
            giveColorAtMouse(event, hoverColor);
        });
        _wheel.addEventListener(MouseEvent.CLICK, function (event :MouseEvent) :void {
            giveColorAtMouse(event, pickColor);
        });
    }

    protected function giveColorAtMouse (event :MouseEvent, func :Function) :void
    {
        var p :Point = _wheel.globalToLocal(new Point(event.stageX, event.stageY));
        var angle :int = Math.round(Math.atan2(p.y, -p.x) * 180 / Math.PI); 
        func(colorForAngle(angle));
    }

    protected function colorForAngle (angle :int) :int
    {
        var color :int = 0;
        var shifts :Array = [0, -120, -240];
        for (var ii :int = 0; ii < 3; ii++) {
            color = color << 8;
            var adjustedAngle :int = ((angle + shifts[ii] + 360) % 360) - 180;
            if (adjustedAngle > -60 && adjustedAngle < 60) {
                // 120 degrees surrounding the base area for this color, paint the full color value
                color += 0xFF;
            } else if (adjustedAngle > -120 && adjustedAngle < 120) {
                // for the area -60 - -120 and 60 - 120 degrees away from the base area, gradually
                // reduce the value for this color 
                var percent :Number = 1 - (Math.abs(adjustedAngle) - 60) / 60;
                color += percent * 0xFF;
            }
        }
        return color;
    }

    protected function displayManipulator (color :uint) :void
    {
        addChild(_manipulator = new Sprite());
        _manipulator.x = (PALETTE_WIDTH - MANIPULATOR_WIDTH) / 2;
        _manipulator.y = PADDING * 3 + INDICATOR_HEIGHT + WHEEL_RADIUS * 2;

        var g :Graphics = _manipulator.graphics;
        g.clear();
        g.lineStyle(1);
        var m :Matrix = new Matrix();
        m.createGradientBox(MANIPULATOR_WIDTH, 1);
        for (var ii :int = 0; ii < MANIPULATOR_HEIGHT; ii++) {
            var rr :int = (color & 0xFF0000) >> 16;
            var gg :int = (color & 0x00FF00) >> 8;
            var bb :int = (color & 0x0000FF);
            var percent :Number = 1 - (ii / MANIPULATOR_HEIGHT);
            // find the color heading towards black for this row;
            var gradedColor :uint = (Math.round(rr * percent) << 16) + 
                                    (Math.round(gg * percent) << 8) + Math.round(bb * percent);
            var channel :int = Math.round(percent * 0xFF);
            var gradedBlack :uint = (channel << 16) + (channel << 8) + channel;
            g.lineGradientStyle(
                GradientType.LINEAR, [gradedBlack, gradedColor], [1, 1], [0, 255], m);
            g.moveTo(0, ii);
            g.lineTo(MANIPULATOR_WIDTH, ii);
        }
    }

    private static const log :Log = Log.getLog(Palette);

    protected static const WHEEL_RADIUS :int = 40;
    protected static const INDICATOR_HEIGHT :int = 30;
    protected static const INDICATOR_WIDTH :int = 60;
    protected static const COMPONENT_BORDER_COLOR :int = 0;
    protected static const MANIPULATOR_WIDTH :int = 60;
    protected static const MANIPULATOR_HEIGHT :int = 60;
    protected static const PADDING :int = 5;

    protected var _toolbox :ToolBox;
    protected var _indicator :Sprite;
    protected var _wheel :Sprite;
    protected var _manipulator :Sprite;
    protected var _selectedColor :int;
}
}
