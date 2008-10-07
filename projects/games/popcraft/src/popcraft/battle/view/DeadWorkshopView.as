package popcraft.battle.view {

import com.whirled.contrib.ColorMatrix;
import com.whirled.contrib.simplegame.resource.SwfResource;

import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.text.TextField;

import popcraft.*;
import popcraft.battle.WorkshopUnit;

public class DeadWorkshopView extends BattlefieldSprite
{
    public static function getForPlayer (playerIndex :int) :DeadWorkshopView
    {
        return GameContext.netObjects.getObjectNamed(NAME_PREFIX + playerIndex) as DeadWorkshopView;
    }

    public function DeadWorkshopView (unit :WorkshopUnit)
    {
        _movie = SwfResource.instantiateMovieClip("workshop", "base");
        _owningPlayerIndex = unit.owningPlayerIndex;

        // player name
        var owningPlayer :PlayerInfo = unit.owningPlayerInfo;
        var nameText :TextField = _movie["player_name"];
        nameText.text = owningPlayer.playerName;

        // remove the "target" badge
        var targetBadge :MovieClip = _movie["target"];
        _movie.removeChild(targetBadge);

        // swap in the rubble movie for the workshop
        var workshop :MovieClip = _movie["workshop"];
        var rubble :MovieClip = SwfResource.instantiateMovieClip("workshop", "workshop_rubble");
        var index :int = _movie.getChildIndex(workshop);
        _movie.removeChildAt(index);
        _movie.addChildAt(rubble, index);

        // mirror horizontally if we're on the left side of the battlefield
        rubble.scaleX = (unit.x < GameContext.gameMode.battlefieldWidth * 0.5 ? -1 : 1);

        // recolor
        var playerColor :uint = GameContext.gameData.playerColors[unit.owningPlayerIndex];
        var recolor :MovieClip = rubble["recolor"];
        recolor.filters = [ ColorMatrix.create().colorize(playerColor).createFilter() ];

        this.updateLoc(unit.x, unit.y);
    }

    override public function get objectName () :String
    {
        return NAME_PREFIX + _owningPlayerIndex;
    }

    override public function get displayObject () :DisplayObject
    {
        return _movie;
    }

    protected var _movie :MovieClip;
    protected var _owningPlayerIndex :int;

    protected static const NAME_PREFIX :String = "DeadWorkshopView_";
}

}
