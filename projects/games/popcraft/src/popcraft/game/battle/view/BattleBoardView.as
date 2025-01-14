//
// $Id$

package popcraft.game.battle.view {

import com.threerings.display.DisplayUtil;
import com.threerings.flashbang.audio.AudioManager;
import com.threerings.flashbang.objects.*;
import com.threerings.flashbang.resource.*;

import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.MovieClip;
import flash.display.Sprite;

import popcraft.*;
import popcraft.game.*;
import popcraft.game.battle.*;
import popcraft.net.*;
import popcraft.util.*;

public class BattleBoardView extends SceneObject
{
    public function BattleBoardView (width :int, height :int)
    {
        _width = width;
        _height = height;

        _bgName = GameCtx.gameMode.mapSettings.backgroundName;

        _bg = ClientCtx.instantiateMovieClip("bg", _bgName, true, true);
        _bg.x = Constants.SCREEN_SIZE.x * 0.5;
        _bg.y = Constants.SCREEN_SIZE.y * 0.5;
        _bg.mouseEnabled = false;
        _bg.mouseChildren = false;

        _parent = SpriteUtil.createSprite(true, false);
        _parent.addChild(_bg);

        var attach :MovieClip = _bg["attachment"];

        _diurnalMeterParent = SpriteUtil.createSprite();
        _diurnalMeterParent.x = -_bg.x;
        _diurnalMeterParent.y = -_bg.y;
        attach.addChild(_diurnalMeterParent);

        _unitViewParent = SpriteUtil.createSprite();
        _unitViewParent.x = -_bg.x;
        _unitViewParent.y = -_bg.y;
        attach.addChild(_unitViewParent);

        _lastDayPhase = (DiurnalCycle.isDisabled ? Constants.PHASE_NIGHT : GameCtx.gameData.initialDayPhase);

        _bg.gotoAndStop(DiurnalCycle.isNight(_lastDayPhase) ? "night" : "day");
        _bg.cacheAsBitmap = true;
    }

    override protected function cleanup () :void
    {
        _diurnalMeterParent.parent.removeChild(_diurnalMeterParent);
        _unitViewParent.parent.removeChild(_unitViewParent);
        SwfResource.releaseMovieClip(_bg);

        super.cleanup();
    }

    override protected function addedToDB () :void
    {
        // if this is the Tesla background, create an object that will play a sound
        // when the Tesla lightning animation plays.
        if (_bgName == "tesla") {
            _teslaSoundPlayer = new TeslaSoundPlayer(_bg, GameCtx.playGameSound);
            GameCtx.gameMode.addObject(_teslaSoundPlayer);
        }
    }

    override protected function removedFromDB () :void
    {
        if (_teslaSoundPlayer != null) {
            _teslaSoundPlayer.destroySelf();
        }
    }

    override protected function update (dt :Number) :void
    {
        var newDayPhase :int = GameCtx.diurnalCycle.phaseOfDay;
        if (newDayPhase != _lastDayPhase) {
            animateDayPhaseChange(newDayPhase);
            _lastDayPhase = newDayPhase;
        }
    }

    protected function animateDayPhaseChange (phase :int) :void
    {
        var animName :String;
        if (DiurnalCycle.isDay(phase)) {
            animName = "nighttoday";
        } else if (DiurnalCycle.isNight(phase) && !DiurnalCycle.isEclipse(_lastDayPhase)) {
            animName = "daytonight";
        }

        if (null != animName) {
            _bg.gotoAndPlay(animName);
        }
    }

    override public function get displayObject () :DisplayObject
    {
        return _parent;
    }

    public function get clickableObjectParent () :DisplayObjectContainer
    {
        return _parent;
    }

    public function get unitViewParent () :DisplayObjectContainer
    {
        return _unitViewParent;
    }

    public function get diurnalMeterParent () :DisplayObjectContainer
    {
        return _diurnalMeterParent;
    }

    public function sortUnitDisplayChildren () :void
    {
        DisplayUtil.sortDisplayChildren(_unitViewParent, displayObjectYSort);
    }

    protected static function displayObjectYSort (a :DisplayObject, b :DisplayObject) :int
    {
        var ay :Number = a.y;
        var by :Number = b.y;

        if (ay < by) {
            return -1;
        } else if (ay > by) {
            return 1;
        } else {
            return 0;
        }
    }

    protected var _bgName :String;
    protected var _width :int;
    protected var _height :int;
    protected var _parent :Sprite;
    protected var _unitViewParent :Sprite;
    protected var _diurnalMeterParent :Sprite;
    protected var _lastDayPhase :int;
    protected var _bg :MovieClip;

    protected var _teslaSoundPlayer :TeslaSoundPlayer;
}

}
