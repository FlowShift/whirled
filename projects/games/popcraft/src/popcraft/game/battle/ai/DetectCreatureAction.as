//
// $Id$

package popcraft.game.battle.ai {

import com.threerings.flashbang.*;

import popcraft.*;
import popcraft.game.*;
import popcraft.game.battle.*;

public class DetectCreatureAction extends AITask
{
    public static const MSG_CREATUREDETECTED :String = "CreatureDetected";

    public function DetectCreatureAction (detectPredicate :Function, taskName :String = null)
    {
        _detectPredicate = detectPredicate;
        _taskName = taskName;
    }

    override public function update (dt :Number, unit :CreatureUnit) :AITaskStatus
    {
        var creatureRefs :Array = GameCtx.netObjects.getObjectRefsInGroup(CreatureUnit.GROUP_NAME);
        var detectedCreature :CreatureUnit;

        for each (var ref :GameObjectRef in creatureRefs) {
            var creature :CreatureUnit = ref.object as CreatureUnit;
            if (null != creature && unit != creature && _detectPredicate(unit, creature)) {
                detectedCreature = creature;
                break;
            }
        }

        handleDetectedCreature(unit, detectedCreature);

        return AITaskStatus.COMPLETE;
    }

    protected function handleDetectedCreature (thisCreature :CreatureUnit,
        detectedCreature :CreatureUnit) :void
    {
        if (null != detectedCreature) {
            sendParentMessage(MSG_CREATUREDETECTED, detectedCreature);
        }
    }

    override public function get name () :String
    {
        return _taskName;
    }

    override public function clone () :AITask
    {
        return new DetectCreatureAction(_detectPredicate, _taskName);
    }

    protected var _taskName :String;
    protected var _detectPredicate :Function;

}

}
