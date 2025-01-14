package bingo.client {

import com.whirled.contrib.simplegame.objects.*;
import com.whirled.contrib.simplegame.resource.*;

import flash.display.DisplayObject;
import flash.display.InteractiveObject;
import flash.display.MovieClip;
import flash.geom.Rectangle;
import flash.events.MouseEvent;

public class InGameHelpView extends SceneObject
{
    public function InGameHelpView ()
    {
        _screen = SwfResource.instantiateMovieClip(ClientCtx.rsrcs, "help", "help_screen");

        // center the help screen
        var screenBounds :Rectangle = ClientCtx.getScreenBounds();
        _screen.x = (screenBounds.width * 0.5);
        _screen.y = (screenBounds.height * 0.5);

        // wire up buttons
        var exitButton :InteractiveObject = _screen["x_button"];
        registerListener(exitButton, MouseEvent.CLICK, handleExitButtonClick);
    }

    override public function get displayObject () :DisplayObject
    {
        return _screen;
    }

    protected function handleExitButtonClick (...ignored) :void
    {
        var gameMode :GameMode = (this.db as GameMode);

        gameMode.hideHelpScreen();
    }

    protected var _screen :MovieClip;

}

}
