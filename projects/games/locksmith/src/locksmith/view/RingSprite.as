//
// $Id$

package locksmith.view {

import flash.display.MovieClip;
import flash.display.Sprite;
import flash.events.Event;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.utils.getTimer;

import com.threerings.util.ArrayUtil;
import com.threerings.util.HashMap;
import com.threerings.util.Log;

import com.whirled.contrib.EventHandlers;

import locksmith.model.Marble;
import locksmith.model.Ring;

public class RingSprite extends Sprite 
{
    public static const RINGS_SIZE :int = 500;
    public static const SIZE_PER_RING :int = 34;

    public static const STATIONARY :int = 0;
    public static const CLOCKWISE :int = -1;
    public static const COUNTER_CLOCKWISE :int = 1;

    public function RingSprite (ring :Ring, clock :Clock = null) 
    {
        _ring = ring;
        _clock = clock;
        _marbles = new HashMap();

        _ringMovie = _ring.id == 2 ? null : new RingSprite["RING_" + _ring.id]() as MovieClip;
        if (_ringMovie != null) {
            _ringMovie.gotoAndStop(1);
            _ringMovie.cacheAsBitmap = true;
            addChild(_ringMovie);
        }

        var channelMovie :MovieClip;
        for each (var hole :int in _ring.holes) {
            addChild(channelMovie = new RingSprite["CHANNEL_" + _ring.id]() as MovieClip);
            channelMovie.cacheAsBitmap = true;
            _channels.push(new Channel(channelMovie, hole));
        }

//        EventHandlers.registerListener(this, Event.ENTER_FRAME, enterFrame);
    }

    public function rotate (direction :int) :void
    {
//        _rotationStart = getTimer();
//        _rotationDirection = direction;
//        var stages :Array = [ { percent: 0.25, stage: DoLater.ROTATION_25 },
//            { percent: 0.5, stage: DoLater.ROTATION_50 }, 
//            { percent: 0.75, stage: DoLater.ROTATION_75 },
//            { percent: 1, stage: DoLater.ROTATION_END } ];
//        for (var curStage :int = 0; curStage < stages.length; curStage++) {
//            var boundAngle :int = (_baseRotation + Math.round(stages[curStage].percent * 90 * 
//                direction) + 360) % 360;
//            // call an anonymous function to create our DoLater function in order to bind boundAngle
//            // properly.
//            DoLater.instance.registerAt(stages[curStage].stage, function(angle :int) :Function {
//                return function (currentStage :int) :void {
//                    // check if any marbles in this ring need to move on
//                    for each (var hole :int in _marbles.keys()) {
//                        var marble :Marble = _marbles.get(hole);
//                        marble.pos = (marble.pos + _rotationDirection + 16) % 16;
//                        if (marble.launch()) {
//                            _marbles.remove(hole);
//                        }
//                    }
//                    // check if any marbles in the ring above need to move in
//                    if (_outer != null) {
//                        for each (hole in _ring.holes) {
//                            var offset :int = (_baseRotation / 360) * 16 +
//                                DoLater.getPercent(currentStage) * 4 * _rotationDirection;
//                            var pos :int = (hole + offset + 16) % 16;
//                            _outer.launchFrom(pos);
//                        }
//                    }
//                }
//            }(boundAngle));
//        }
//        DoLater.instance.trigger(DoLater.ROTATION_BEGIN);
    }

    public function isRotating () :Boolean
    {
        return _rotationDirection != STATIONARY;
    }

    /** 
     * Called when the win condition has been met and the animation should stop
     */
    public function stopRotation () :void
    {
        _rotationDirection = STATIONARY;
    }

    public function getHoleAt (pos :int) :int 
    {
//        var offset :int = 
//            (_baseRotation / 360) * 16 + DoLater.getPercent() * 4 * _rotationDirection;
//        var hole :int = (pos - offset + 16) % 16;
//
//        return ArrayUtil.contains(_ring.holes, hole) ? hole : -1;
        return 0;
    }

    public function holeIsEmpty (hole :int) :Boolean
    {
        return ArrayUtil.contains(_ring.holes, hole) && _marbles.get(hole) == null;
    }

    public function putMarbleInHole (marble :Marble, hole :int) :void
    {
        if (holeIsEmpty(hole)) {
            _marbles.put(hole, marble);
        } else {
            throw new ArgumentError("attempted to put marble into non-empty hole: " + hole);
        }
    }

    public function getHoleLocation (hole :int, rotationAngle :Number = NaN) :Point
    {
        if (isNaN(rotationAngle)) {
            rotationAngle = _rotationAngle;
        }
        var angle :Number = ((hole / 16) * 360 + _baseRotation + rotationAngle) * Math.PI / 180;
        var trans :Matrix = new Matrix();
        trans.translate((_ring.id + 0.5) * SIZE_PER_RING, 0);
        trans.rotate(-angle);
        return trans.transformPoint(new Point(0, 0));
    }

    /** 
     * Returns the target location for a marble that is falling into this hole.  If this ring is 
     * currently rotating, that is taken into account.
     */
    public function getHoleTargetLocation (hole :int) :Point
    {
        if (Math.abs(_rotationAngle) > 85) {
            // if we're almost done with the rotation, don't try to predict a location, it will be
            // wrong.
            return getHoleLocation(hole);
        }
        return getHoleLocation(hole, 
            _rotationAngle + _rotationDirection * MarbleSprite.ROLL_FRAMES);
    }

    public function get num () :int
    {
        return _ring.id;
    }

    /** 
     * Rings implement a doubly-linked list, so that anybody who has a reference to one can get
     * at them all.
     */
    public function get inner () :RingSprite
    {
        return _inner;
    }

    public function set inner (ring :RingSprite) :void
    {
        _inner = ring;
    }

    public function get outer () :RingSprite
    {
        return _outer;
    }
     
    public function set outer (ring :RingSprite) :void
    {
        _outer = ring;
    }

    public function get largest () :RingSprite
    {
        return _outer != null ? _outer.largest : this;
    }

    public function get smallest () :RingSprite
    {
        return _inner != null ? _inner.smallest : this;
    }

    // For debugging
    public override function toString () :String
    {
        return "[RingSprite num=" + _ring.id + ", baseRotation=" + _baseRotation + 
            ", rotationAngle=" + _rotationAngle + "]";
    }

    protected function launchFrom (pos :int) :void
    {
//        var hole :int = getHoleAt(pos);
//        var marble :Marble = _marbles.get(hole) as Marble;
//        if (marble != null) {
//            if (marble.launch()) {
//                _marbles.remove(hole);
//                if (_outer != null && ArrayUtil.contains(_ring.holes, hole)) {
//                    _outer.launchFrom(pos);
//                }
//            }
//        } 
    }

    protected function enterFrame (evt :Event) :void
    {
//        if (_rotationDirection != STATIONARY) {
//            DoLater.instance.atPercent(Math.abs(_rotationAngle) / 90);
//            var angle :int;
//            if (Math.abs(_rotationAngle) == 89) {
//                DoLater.instance.trigger(DoLater.ROTATION_END);
//                angle = _baseRotation = (_baseRotation + 90 * _rotationDirection + 360) % 360;
//                _rotationDirection = STATIONARY;
//                if (_clock != null) {
//                    _clock.setRotationAngle(90 * (_rotationAngle < 0 ? 1 : -1), true);
//                }
//                _rotationAngle = 0;
//                DoLater.instance.trigger(DoLater.ROTATION_AFTER_END);
//            } else {
//                _rotationAngle += _rotationDirection;
//                angle = (_baseRotation + _rotationAngle + 360) % 360;
//                if (_clock != null) {
//                    _clock.setRotationAngle(-_rotationAngle);
//                }
//            }
//
//            if (_ringMovie != null) {
//                var frame :int = (-angle + 360) % 360;
//                _ringMovie.gotoAndStop(frame + 1);
//            }
//            for each (var channel :Channel in _channels) {
//                channel.setAngle(angle);
//            }
//
//            for each (var hole :int in _marbles.keys()) {
//                var pos :Point = getHoleLocation(hole);
//                var marble :Marble = _marbles.get(hole);
//                marble.x = pos.x;
//                marble.y = pos.y;
//            }
//        }
    }

    /** RingSprite movies - There is no movie for RingSprite 3 */
    [Embed(source="../../../rsrc/locksmith_art.swf#ring_1")]
    protected static const RING_0 :Class;
    [Embed(source="../../../rsrc/locksmith_art.swf#ring_2")]
    protected static const RING_1 :Class;
    [Embed(source="../../../rsrc/locksmith_art.swf#ring_4")]
    protected static const RING_3 :Class;

    /** Channel movies */
    [Embed(source="../../../rsrc/locksmith_art.swf#ring_1_channel")]
    protected static const CHANNEL_0 :Class;
    [Embed(source="../../../rsrc/locksmith_art.swf#ring_2_channel")]
    protected static const CHANNEL_1 :Class;
    [Embed(source="../../../rsrc/locksmith_art.swf#ring_3_channel")]
    protected static const CHANNEL_2 :Class;
    [Embed(source="../../../rsrc/locksmith_art.swf#ring_4_channel")]
    protected static const CHANNEL_3 :Class;

    protected var _ring :Ring;
    protected var _marbles :HashMap;
    protected var _holeSprites :Sprite;
    protected var _baseRotation :int = 0;
    protected var _rotationAngle :int = 0;
    protected var _rotationDirection :Number = STATIONARY;
    protected var _rotationStart :int = 0;
    protected var _inner :RingSprite;
    protected var _outer :RingSprite;
    protected var _clock :Clock;

    protected var _ringMovie :MovieClip;
    protected var _channels :Array = [];

    private static const log :Log = Log.getLog(RingSprite);
}
}

import flash.display.MovieClip;

import locksmith.model.RingManager;

class Channel
{
    public function Channel (movie :MovieClip, holeNumber :int) 
    {
        _channel = movie;
        _baseAngle = Math.round((360 / Math.pow(2, RingManager.NUM_RINGS)) * holeNumber) as int;
        setAngle(0);
    }

    public function setAngle (angle :int) :void
    {
        var frame :int = (_baseAngle + angle) % 360;
        frame = (-frame + 360 + 90) % 360;
        _channel.gotoAndStop(frame + 1);
    }

    protected var _channel :MovieClip;
    protected var _baseAngle :int;
}
