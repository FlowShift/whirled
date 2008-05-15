package popcraft.battle.ai {

import popcraft.battle.CreatureUnit;

public class DelayUntilTask extends AITask
{
    public static function notAttackingPredicate (dt :Number, creature :CreatureUnit) :Boolean
    {
        return !creature.isAttacking;
    }

    public function DelayUntilTask (name :String, pred :Function)
    {
        _name = name;
        _pred = pred;
    }

    override public function update (dt :Number, creature :CreatureUnit) :uint
    {
        return (_pred(dt, creature) ? AITaskStatus.COMPLETE : AITaskStatus.ACTIVE);
    }

    override public function get name () :String
    {
        return _name;
    }

    override public function clone () :AITask
    {
        return new DelayUntilTask(_name, _pred);
    }

    protected var _name :String;
    protected var _pred :Function;
}

}
