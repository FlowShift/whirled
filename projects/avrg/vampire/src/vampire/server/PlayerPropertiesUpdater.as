package vampire.server
{
import com.threerings.util.ArrayUtil;
import com.threerings.util.HashMap;
import com.threerings.util.HashSet;
import com.whirled.avrg.PlayerSubControlServer;
import com.whirled.contrib.simplegame.Updatable;

import flash.utils.ByteArray;

/**
 * Copies the player data into player props only on the update loop.
 * This can be controlled by the server for bundled updates.
 *
 */
public class PlayerPropertiesUpdater
    implements Updatable
{
    public function PlayerPropertiesUpdater(ctrl :PlayerSubControlServer, propsKeys :Array = null)
    {
        _ctrl = ctrl;
        for each (var propKey :String in propsKeys) {
            var currentValue :Object = ctrl.props.get(propKey);
            _data.put(propKey, currentValue);
        }
    }

    public function get (key :Object) :*
    {
        return _data.get(key);
    }

    public function put (key :String, value :Object) :*
    {
        _needsUpdate.add(key);
        return _data.put(key, value);
    }

    public function update (dt :Number) :void
    {
        if (_needsUpdate.size() > 0) {
            var updateValue :Boolean = false;
            _needsUpdate.forEach(function (key :String) :void {

                updateValue = false;
                var oldValue :Object = _ctrl.props.get(key);
                var newValue :Object = _data.get(key);

                if (newValue is ByteArray) {
                    updateValue = isByteArraysDifferent(oldValue as ByteArray, newValue as ByteArray);
                }
                else if (newValue is Array) {
                    updateValue = isArraysDifferent(oldValue as Array, newValue as Array);
                }
                else if (newValue != oldValue) {
                    updateValue = true;
                }

                if (updateValue) {
                    _ctrl.props.set(key, newValue, true);
                }
            });
            _needsUpdate.clear();
        }
    }

    protected function isByteArraysDifferent (b1 :ByteArray, b2 :ByteArray) :Boolean
    {
        if ((b1 == null && b2 != null) || (b1 != null && b2 == null)) {
            return true;
        }
        if (b1 == null && b2 == null) {
            return false;
        }

        if (b1.length != b2.length) {
            return true;
        }
        b1.position = 0;
        b2.position = 0;
        for (var ii :int = 0; ii < b1.length; ++ii) {
            if (b1[ii] != b2[ii]) {
                return true;
            }
        }
        return false;
    }

    protected function isArraysDifferent (a1 :Array, a2 :Array) :Boolean
    {
        return !ArrayUtil.equals(a1, a2);
    }

    public function isNeedingUpdate (key :String) :Boolean
    {
        return _needsUpdate.contains(key);
    }


    /**The player data*/
    protected var _data :HashMap = new HashMap();
    protected var _needsUpdate :HashSet = new HashSet();
    protected var _ctrl :PlayerSubControlServer;

}
}