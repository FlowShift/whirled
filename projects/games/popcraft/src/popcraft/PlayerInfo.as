package popcraft {

import com.threerings.util.Log;
import com.whirled.contrib.simplegame.SimObjectRef;

import flash.display.DisplayObject;
import flash.events.EventDispatcher;

import popcraft.battle.CreatureSpellSet;
import popcraft.battle.UnitDamageShield;
import popcraft.battle.WorkshopUnit;
import popcraft.battle.view.DeadWorkshopView;
import popcraft.battle.view.WorkshopView;
import popcraft.data.BaseLocationData;
import popcraft.sp.endless.SavedEndlessGame;
import popcraft.sp.endless.SavedPlayerInfo;

/**
 * Encapsulates public information about a player in the game.
 */
public class PlayerInfo extends EventDispatcher
{
    public function PlayerInfo (playerIndex :int, teamId :int, baseLoc :BaseLocationData,
        maxHealth :Number, startHealth :Number, invincible :Boolean,
        handicap :Number, color :uint, displayName :String = null,
        headshot :DisplayObject = null)
    {
        _playerIndex = playerIndex;
        _teamId = teamId;
        _baseLoc = baseLoc;
        _maxHealth = maxHealth;
        _startHealth = startHealth;
        _invincible = invincible;
        _handicap = handicap;
        _color = color;

        _minResourceAmount = GameContext.gameData.minResourceAmount;
        _maxResourceAmount = GameContext.gameData.maxResourceAmount;
        if (_handicap > 1) {
            _maxResourceAmount *= _handicap;
        }

        if (null != displayName) {
            _displayName = displayName;
        } else {
            _displayName = SeatingManager.getPlayerName(_playerIndex);
        }

        if (null != headshot) {
            _headshot = headshot;
        } else {
            _headshot = SeatingManager.getPlayerHeadshot(_playerIndex);
        }
    }

    public function saveData (outData :SavedPlayerInfo = null) :SavedPlayerInfo
    {
        var save :SavedPlayerInfo = (outData != null ? outData : new SavedPlayerInfo());
        var workshop :WorkshopUnit = this.workshop;
        if (null != workshop) {
            save.health = workshop.health;
            save.damageShields = workshop.damageShieldsClone;

        } else {
            save.health = 0;
            save.damageShields = [];
        }

        return save;
    }

    public function restoreSavedPlayerInfo (savedData :SavedPlayerInfo) :void
    {
        this.workshop.health = savedData.health;
        this.workshop.damageShields = savedData.damageShields;
    }

    public function restoreSavedGameData (save :SavedEndlessGame, damageShieldHealth :Number) :void
    {
        var shields :Array = [];
        for (var ii :int = 0; ii < save.multiplier - 1; ++ii) {
            shields.push(new UnitDamageShield(damageShieldHealth));
        }

        this.workshop.health = save.health;
        this.workshop.damageShields = shields;
    }

    public function init () :void
    {
        // create the creature spell set
        _activeSpells = new CreatureSpellSet();
        GameContext.netObjects.addObject(_activeSpells);

        // create the workshop
        var view :WorkshopView = GameContext.unitFactory.createWorkshop(this);
        var workshop :WorkshopUnit = view.workshop;
        workshop.x = _baseLoc.loc.x;
        workshop.y = _baseLoc.loc.y;
        _workshopRef = workshop.ref;
    }

    public function destroy () :void
    {
        // destroy the creature spell set
        _activeSpells.destroySelf();
        _activeSpells = null;

        // destroy the workshop and its views
        var workshop :WorkshopUnit = this.workshop;
        if (workshop != null) {
            workshop.destroySelf();
        }

        var workshopView :WorkshopView = WorkshopView.getForPlayer(_playerIndex);
        if (workshopView != null) {
            workshopView.destroySelf();
        }

        var deadWorkshopView :DeadWorkshopView = DeadWorkshopView.getForPlayer(_playerIndex);
        if (deadWorkshopView != null) {
            deadWorkshopView.destroySelf();
        }
    }

    public function resurrect (newHealth :Number) :void
    {
        this.destroy();
        this.init();
        this.workshop.health = newHealth;
    }

    public function get activeSpells () :CreatureSpellSet
    {
        return _activeSpells;
    }

    public function get minResourceAmount () :int
    {
        return _minResourceAmount;
    }

    public function get maxResourceAmount () :int
    {
        return _maxResourceAmount;
    }

    public function get handicap () :Number
    {
        return _handicap;
    }

    public function get playerIndex () :int
    {
        return _playerIndex;
    }

    public function get teamId () :int
    {
        return _teamId;
    }

    public function get whirledId () :int
    {
        return SeatingManager.getPlayerOccupantId(_playerIndex);
    }

    public function get displayName () :String
    {
        return _displayName;
    }

    public function get headshot () :DisplayObject
    {
        return _headshot;
    }

    public function get color () :uint
    {
        return _color;
    }

    public function get leftGame () :Boolean
    {
        return _leftGame;
    }

    public function set leftGame (val :Boolean) :void
    {
        _leftGame = val;
    }

    public function get baseLoc () :BaseLocationData
    {
        return _baseLoc;
    }

    public function get workshopRef () :SimObjectRef
    {
        return _workshopRef;
    }

    public function get workshop () :WorkshopUnit
    {
        return _workshopRef.object as WorkshopUnit;
    }

    public function get isAlive () :Boolean
    {
        // If this is called before the game has been completely set up,
        // _baseRef will be null and (null != this.base) will NPE. We can
        // assume, in this situation, that the player is alive.
        return (null == _workshopRef || null != this.workshop);
    }

    public function get isInvincible () :Boolean
    {
        return _invincible;
    }

    public function get health () :Number
    {
        var base :WorkshopUnit = this.workshop;
        return (null != base ? base.health : 0);
    }

    public function get maxHealth () :Number
    {
        return _maxHealth;
    }

    public function get startHealth () :Number
    {
        return _startHealth;
    }

    public function get healthPercent () :Number
    {
        return (this.health / _maxHealth);
    }

    public function get targetedEnemy () :PlayerInfo
    {
        if (_targetedEnemy == null) {
            _targetedEnemy = GameContext.findEnemyForPlayer(_playerIndex);
        }

        return _targetedEnemy;
    }

    /*public function get targetedEnemyId () :int
    {
        if (_targetedEnemy == null || !_targetedEnemy.isAlive) {
            _targetedEnemy = GameContext.findEnemyForPlayer(_playerIndex);
        }

        return _targetedEnemyId;
    }*/

    public function set targetedEnemy (playerInfo :PlayerInfo) :void
    {
        _targetedEnemy = playerInfo;
    }

    public function canAffordCreature (unitType :int) :Boolean
    {
        return true;
    }

    public function deductCreatureCost (unitType :int) :void
    {
        // no-op
    }

    public function canCastSpell (spellType :int) :Boolean
    {
        return true;
    }

    public function addSpell (spellType :int, count :int = 1) :void
    {
        // no-op
    }

    public function spellCast (spellType :int) :void
    {
        // no-op
    }

    public function get canResurrect () :Boolean
    {
        var teammate :PlayerInfo = GameContext.findPlayerTeammate(_playerIndex);
        return (teammate != null && teammate.isAlive);
    }

    protected var _playerIndex :int;  // an unsigned integer corresponding to the player's seating position
    protected var _color :uint;
    protected var _teamId :int;
    protected var _maxHealth :Number;
    protected var _startHealth :Number;
    protected var _invincible :Boolean;
    protected var _displayName :String;
    protected var _headshot :DisplayObject;
    protected var _leftGame :Boolean;
    protected var _targetedEnemy :PlayerInfo;
    protected var _workshopRef :SimObjectRef;
    protected var _handicap :Number;
    protected var _minResourceAmount :int;
    protected var _maxResourceAmount :int;
    protected var _baseLoc :BaseLocationData;

    protected var _activeSpells :CreatureSpellSet;

    protected static var log :Log = Log.getLog(PlayerInfo);
}

}
