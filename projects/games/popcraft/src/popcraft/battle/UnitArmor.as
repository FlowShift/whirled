package popcraft.battle {

import com.threerings.util.HashMap;
import com.threerings.util.Assert;

import core.util.Rand;

/**
 * UnitArmor is a damage filter that modifies the effects of an attack before it's applied to a unit.
 * All units have a UnitArmor.
 */
public class UnitArmor
{
    /**
     * Construct a new new UnitArmor.
     * armorArray is an array of pairs of uints and Numbers - damage types and damage modifiers.
     */
    public function UnitArmor (armorArray :Array = null)
    {
        if (null != armorArray) {

            // array length must be divisible by 2
            Assert.isTrue((armorArray.length % 2) == 0);

            for (var i :int = 0; i < armorArray.length; i += 2) {
                var damageType :uint = armorArray[i];
                var damageMultiplier :Number = armorArray[i + 1];

                _armor.put(damageType, damageMultiplier);
            }
        }
    }

    public function getAttackDamage (attack :UnitAttack) :Number
    {
        var value :* = _armor.get(attack.damageType);
        var damageMultiplier :Number = (undefined !== value ? value : 1);

        return (attack.damageRange.next(Rand.STREAM_GAME) * damageMultiplier);
    }

    protected var _armor :HashMap = new HashMap();
}

}
