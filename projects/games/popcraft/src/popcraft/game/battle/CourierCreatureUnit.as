//
// $Id$

package popcraft.game.battle {

import com.threerings.geom.Vector2;
import com.threerings.util.Assert;
import com.threerings.flashbang.*;

import popcraft.*;
import popcraft.game.*;
import popcraft.game.battle.ai.*;

/**
 * Couriers retrieve spell pickups from the battlefield and bring them back to their
 * owning player's base.
 *
 * Couriers move faster when there are more of them on the playfield.
 */
public class CourierCreatureUnit extends CreatureUnit
{
    public static function getNumPlayerCouriersOnBoard (playerIndex :int) :int
    {
        return GameCtx.netObjects.getObjectRefsInGroup(getGroupName(playerIndex)).length;
    }

    public function CourierCreatureUnit (owningPlayerIndex :int)
    {
        super(owningPlayerIndex, Constants.UNIT_TYPE_COURIER);

        _spawnLoc = _owningPlayerInfo.workshop.unitSpawnLoc;

        _courierAI = new CourierAI(this);
        _groupName = getGroupName(owningPlayerIndex);
    }

    public function pickupSpell (spellObject :SpellDropObject) :void
    {
        Assert.isNull(_carriedSpell);
        _carriedSpell = new CarriedSpellObject(spellObject.spellType);
        GameCtx.netObjects.addObject(_carriedSpell);
        spellObject.destroySelf();
    }

    public function dropCarriedSpell () :void
    {
        if (null != _carriedSpell) {
            // don't play the "new spell" sound when the Courier drops a spell
            SpellDropFactory.createSpellDrop(_carriedSpell.spellType, this.unitLoc, false);
            destroyCarriedSpell();
        }
    }

    public function deliverSpellToBase () :void
    {
        Assert.isNotNull(_carriedSpell);

        GameCtx.gameMode.spellDeliveredToPlayer(_owningPlayerInfo.playerIndex,
            _carriedSpell.spellType);

        destroyCarriedSpell();

        // the courier is destroyed when he delivers the spell
        // (but we don't want to play her death animation when this happens)
        _preventDeathAnimation = true;
        die();
    }

    public function get carriedSpell () :CarriedSpellObject
    {
        return _carriedSpell;
    }

    override protected function addedToDB () :void
    {
        super.addedToDB();
        updateSpeedup();
    }

    override protected function removedFromDB () :void
    {
        destroyCarriedSpell();
        super.removedFromDB();
    }

    protected function destroyCarriedSpell () :void
    {
        if (_carriedSpell != null) {
            _carriedSpell.destroySelf();
            _carriedSpell = null;
        }
    }

    override public function die () :void
    {
        // drop the currently carried spell on the ground when we die.
        dropCarriedSpell();
        super.die();
    }

    override protected function get aiRoot () :AITask
    {
        return _courierAI;
    }

    override public function get objectGroups () :Array
    {
        return [ _groupName ].concat(super.objectGroups);
    }

    override protected function update (dt :Number) :void
    {
        updateSpeedup();
        super.update(dt);
    }

    protected function updateSpeedup () :void
    {
        // the Courier pauses for less time when there are other friendly
        // Couriers on the battlefield
        var numCouriers :int = GameCtx.netObjects.getObjectRefsInGroup(_groupName).length;
        _speedup = numCouriers * CourierSettings.SPEEDUP_PER_COURIER;
        _speedup = Math.max(_speedup, 0);
        _speedup = Math.min(_speedup, CourierSettings.MAX_SPEEDUP);
    }

    public function get speedup () :Number
    {
        return _speedup;
    }

    public function get spawnLoc () :Vector2
    {
        return _spawnLoc; // Courier AI uses this to determine where to move to
    }

    override public function get preventDeathAnimation () :Boolean
    {
        return _preventDeathAnimation;
    }

    protected static function getGroupName (playerIndex :int) :String
    {
        return "CourierCreature_Player" + playerIndex;
    }

    protected var _courierAI :CourierAI;
    protected var _spawnLoc :Vector2;
    protected var _groupName :String;
    protected var _speedup :Number = 1;
    protected var _preventDeathAnimation :Boolean;

    protected var _carriedSpell :CarriedSpellObject;
}

}

import com.threerings.flashbang.*;
import com.threerings.flashbang.util.*;
import flash.geom.Point;

import popcraft.*;
import popcraft.game.*;
import popcraft.game.battle.*;
import popcraft.game.battle.ai.*;
import flash.display.Loader;
import com.threerings.util.Log;
import com.threerings.geom.Vector2;
import com.threerings.util.Name;
import flash.geom.Rectangle;

class CourierSettings
{
    // @TODO - load these from XML
    public static const MOVEMENT_TIME :Number = 0.7;
    public static const BASE_PAUSE_TIME :Number = 1.5;
    public static const SPEEDUP_PER_COURIER :Number = 1.5;
    public static const MAX_SPEEDUP :Number = 8;
    public static const MOVE_FUDGE_FACTOR :Number = 5;
    public static const WANDER_BOUNDS_BORDER :int = 120;
    public static const ENEMY_BASE_WANDER_RADIUS :NumRange =
        new NumRange(150, 300, Rand.STREAM_GAME);
    public static const ENEMY_BASE_WANDER_ANGLE :NumRange =
        new NumRange(-Math.PI / 3, Math.PI / 3, Rand.STREAM_GAME);
}

class CourierAI extends AITaskTree
{
    public static const NAME :String = "CourierAI";

    public function CourierAI (unit :CourierCreatureUnit)
    {
        _unit = unit;
        addSubtask(new ScanForSpellPickupsTask(_unit));
    }

    override protected function receiveSubtaskMessage (task :AITask, messageName :String, data :Object) :void
    {
        if (messageName == ScanForSpellPickupsTask.MSG_DETECTEDSPELL) {
            var spell :SpellDropObject = data as SpellDropObject;
            //log.info("detected spell - attempting pickup");
            clearSubtasks();
            addSubtask(new PickupSpellTask(_unit, spell));
        } else if (messageName == PickupSpellTask.MSG_SPELL_GONE) {
            // we were trying to get to a spell, but somebody else got to it first.
            // resume wandering
            clearSubtasks();
            addSubtask(new ScanForSpellPickupsTask(_unit));
        } else if (messageName == PickupSpellTask.MSG_SPELL_RETRIEVED) {
            // we picked up a spell!
            //log.info("retrieved spell");
            _unit.pickupSpell(data as SpellDropObject);
            // let's try to go home and deliver it
            var base :WorkshopUnit = _unit.owningPlayerInfo.workshop;
            if (null != base) {
                addSubtask(new CourierMoveTask(_unit, base.unitLoc));
            }
        } else if (messageName == AITaskTree.MSG_SUBTASKCOMPLETED && task.name == CourierMoveTask.NAME) {
            // we've arrived at the base. deliver the goods
            _unit.deliverSpellToBase();
        }
    }

    override public function update (dt :Number, creature :CreatureUnit) :AITaskStatus
    {
        super.update(dt, creature);

        // when the owning player dies, just wander forever - never pickup an infusion
        if (!_ownerIsDead && !_unit.owningPlayerInfo.isAlive) {
            clearSubtasks();
            addSubtask(new WanderTask(_unit));
            _ownerIsDead = true;
        }

        return AITaskStatus.INCOMPLETE;
    }

    override public function get name () :String
    {
        return NAME;
    }

    protected var _unit :CourierCreatureUnit;
    protected var _ownerIsDead :Boolean;

    protected static const log :Log = Log.getLog(CourierAI);
}

// The Courier skitters around, like an insect
class CourierMoveTask extends AITaskTree
{
    public static const NAME :String = "CourierMoveTask";

    public function CourierMoveTask (unit :CourierCreatureUnit, loc :Vector2)
    {
        _unit = unit;
        _loc = loc;

        moveToNextLoc();
    }

    protected function moveToNextLoc () :void
    {
        var dist :Number = CourierSettings.MOVEMENT_TIME * _unit.movementSpeed;

        var curLoc :Vector2 = _unit.unitLoc;

        var d :Vector2 = _loc.subtract(curLoc);

        var nextLoc :Vector2;
        if (d.lengthSquared < dist * dist) {
            nextLoc = _loc;
        } else {
            d.length = dist;
            d.addLocal(curLoc);
            nextLoc = d;
        }

        addSubtask(new MoveToLocationTask(MOVE_SUBTASK_NAME, nextLoc, CourierSettings.MOVE_FUDGE_FACTOR));
    }

    override protected function receiveSubtaskMessage (subtask :AITask, messageName :String, data :Object) :void
    {
        if (messageName == AITaskTree.MSG_SUBTASKCOMPLETED) {
            if (subtask.name == MOVE_SUBTASK_NAME) {
                // are we at our destination?
                if (_unit.unitLoc.similar(_loc, CourierSettings.MOVE_FUDGE_FACTOR)) {
                    _complete = true;
                } else {
                    // pause for a moment
                    var pauseTime :Number = CourierSettings.BASE_PAUSE_TIME / _unit.speedup;
                    addSubtask(new AITimerTask(pauseTime, PAUSE_SUBTASK_NAME));
                }
            } else if (subtask.name == PAUSE_SUBTASK_NAME) {
                // start moving again
                moveToNextLoc();
            }
        }
    }

    override public function update (dt :Number, creature :CreatureUnit) :AITaskStatus
    {
        if (_complete) {
            return AITaskStatus.COMPLETE;
        } else {
            super.update(dt, creature);
            return AITaskStatus.INCOMPLETE;
        }
    }

    override public function get name () :String
    {
        return NAME;
    }

    protected var _unit :CourierCreatureUnit;
    protected var _loc :Vector2;
    protected var _complete :Boolean;

    protected static const MOVE_SUBTASK_NAME :String = "MoveSubtask";
    protected static const PAUSE_SUBTASK_NAME :String = "PauseSubtask";
}

class PickupSpellTask extends AITaskTree
{
    public static const NAME :String = "PickupSpellTask";
    public static const MSG_SPELL_RETRIEVED :String = "SpellRetrieved";
    public static const MSG_SPELL_GONE :String = "SpellGone";

    public function PickupSpellTask (unit :CourierCreatureUnit, spell :SpellDropObject)
    {
        _unit = unit;
        _spellRef = spell.ref;

        addSubtask(new CourierMoveTask(_unit, new Vector2(spell.x, spell.y)));
    }

    override protected function receiveSubtaskMessage (subtask :AITask, messageName :String, data :Object) :void
    {
        if (messageName == AITaskTree.MSG_SUBTASKCOMPLETED && subtask.name == CourierMoveTask.NAME) {
            if (!_spellRef.isNull) {
                var spell :SpellDropObject = _spellRef.object as SpellDropObject;
                sendParentMessage(MSG_SPELL_RETRIEVED, spell);
                _retrieved = true;
            }
        }
    }

    override public function update (dt :Number, creature :CreatureUnit) :AITaskStatus
    {
        // does the spell object still exist?
        if (_spellRef.isNull) {
            if (!_retrieved) {
                sendParentMessage(MSG_SPELL_GONE);
            }
            return AITaskStatus.COMPLETE;
        } else {
            super.update(dt, creature);
            return AITaskStatus.INCOMPLETE;
        }
    }

    protected var _retrieved :Boolean;
    protected var _unit :CourierCreatureUnit;
    protected var _spellRef :GameObjectRef;
}

class WanderTask extends AITaskTree
{
    public function WanderTask (unit :CourierCreatureUnit)
    {
        _unit = unit;
        wander();
    }

    override protected function receiveSubtaskMessage (task :AITask, messageName :String, data :Object) :void
    {
        if (messageName == AITaskTree.MSG_SUBTASKCOMPLETED && task.name == CourierMoveTask.NAME) {
            // wander again
            wander();
        }
    }

    protected function wander () :void
    {
        // When Couriers aren't picking up spells, they wander around
        // outside an opponent's base.
        if (_wanderBaseRef.isNull) {
            _wanderBaseRef = _unit.getEnemyBaseToAttack();
            if (_wanderBaseRef.isNull) {
                return;
            }
        }

        var wanderBase :WorkshopUnit = _wanderBaseRef.object as WorkshopUnit;

        // pick a location to wander to outside the enemy player's base
        var wanderLoc :Vector2 = _unit.spawnLoc.subtract(wanderBase.unitLoc);
        wanderLoc.length = CourierSettings.ENEMY_BASE_WANDER_RADIUS.next();
        wanderLoc.rotateLocal(CourierSettings.ENEMY_BASE_WANDER_ANGLE.next());
        wanderLoc.addLocal(wanderBase.unitLoc);

        // clamp
        wanderLoc.x = Math.max(wanderLoc.x, CourierSettings.WANDER_BOUNDS_BORDER);
        wanderLoc.x = Math.min(wanderLoc.x,
            GameCtx.gameMode.battlefieldWidth - CourierSettings.WANDER_BOUNDS_BORDER);

        wanderLoc.y = Math.max(wanderLoc.y, CourierSettings.WANDER_BOUNDS_BORDER);
        wanderLoc.y = Math.min(wanderLoc.y,
            GameCtx.gameMode.battlefieldHeight - CourierSettings.WANDER_BOUNDS_BORDER);

        // commence wandering!
        addSubtask(new CourierMoveTask(_unit, wanderLoc));
    }

    protected var _unit :CourierCreatureUnit;
    protected var _wanderBaseRef :GameObjectRef = GameObjectRef.Null();
}

class ScanForSpellPickupsTask extends WanderTask
{
    public static const NAME :String = "ScanForSpellPickupsTask";
    public static const MSG_DETECTEDSPELL :String = "DetectedSpell";

    public function ScanForSpellPickupsTask (unit :CourierCreatureUnit)
    {
        super(unit);

        // scan for spell pickups twice/second
        var scanSequence :AITaskSequence = new AITaskSequence(true);
        scanSequence.addSequencedTask(new DetectSpellDropAction());
        scanSequence.addSequencedTask(new AITimerTask(0.5));
        addSubtask(scanSequence);
    }

    override protected function receiveSubtaskMessage (task :AITask, messageName :String, data :Object) :void
    {
        if (messageName == AITaskSequence.MSG_SEQUENCEDTASKMESSAGE) {
            var msg :SequencedTaskMessage = data as SequencedTaskMessage;
            var spells :Array = msg.data as Array;
            // choose a spell at random
            var spell :SpellDropObject = Rand.nextElement(spells, Rand.STREAM_GAME);
            sendParentMessage(MSG_DETECTEDSPELL, spell);
        } else {
            super.receiveSubtaskMessage(task, messageName, data);
        }
    }

    override public function get name () :String
    {
        return NAME;
    }
}
