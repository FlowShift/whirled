//
// $Id$

package popcraft.game.battle.view {

import com.threerings.flashbang.resource.*;

import flash.display.MovieClip;

import popcraft.*;
import popcraft.game.battle.*;
import popcraft.gamedata.*;

public class CourierCreatureUnitView extends CreatureUnitView
{
    public function CourierCreatureUnitView (courier :CourierCreatureUnit)
    {
        super(courier);
        _courier = courier;
    }

    override protected function update (dt :Number) :void
    {
        // if the Courier is carrying a spell, display it
        var carriedSpell :CarriedSpellObject = _courier.carriedSpell;
        if (null != carriedSpell && null == _carriedSpellIcon) {
            _carriedSpellIcon = ClientCtx.instantiateMovieClip(
                "infusions",
                carriedSpell.spellData.iconName,
                true);

            _carriedSpellIcon.cacheAsBitmap = true;
            _sprite.addChild(_carriedSpellIcon);
        } else if (null == carriedSpell && null != _carriedSpellIcon) {
            _sprite.removeChild(_carriedSpellIcon);
            _carriedSpellIcon = null;
        }

        super.update(dt);
    }

    protected var _courier :CourierCreatureUnit;
    protected var _carriedSpellIcon :MovieClip;

}

}
