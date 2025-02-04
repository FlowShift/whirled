//
// $Id$

package popcraft.game.battle.ai {

import popcraft.game.battle.CreatureUnit;

public class AITimerTask extends AITask
{
    public function AITimerTask (time :Number, taskName :String = "AITimerTask")
    {
        _totalTime = time;
        _name = taskName;
    }

    override public function update (dt :Number, unit :CreatureUnit) :AITaskStatus
    {
        _elapsedTime += dt;
        return (_elapsedTime >= _totalTime ? AITaskStatus.COMPLETE : AITaskStatus.INCOMPLETE);
    }

    override public function get name () :String
    {
        return _name;
    }

    override public function clone () :AITask
    {
        return new AITimerTask(_totalTime, _name);
    }

    protected var _totalTime :Number = 0;
    protected var _elapsedTime :Number = 0;

    protected var _name :String;

}

}
