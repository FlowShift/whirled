//
// $Id$

package dictattack {

import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.Event;

/**
 * Would you believe, utility functions?
 */
public class Explosion extends Sprite
{
    public function Explosion (movie :MovieClip)
    {
        addChild(_movie = movie);
        _movie.x = Content.TILE_SIZE/2;
        _movie.y = Content.TILE_SIZE/2;
        addEventListener(Event.ENTER_FRAME, onEnterFrame);
    }

    protected function onEnterFrame (event :Event) :void
    {
        if (_movie.currentFrame == _movie.totalFrames) {
            removeEventListener(Event.ENTER_FRAME, onEnterFrame);
            parent.removeChild(this);
        }
    }

    protected var _movie :MovieClip;
}

}
