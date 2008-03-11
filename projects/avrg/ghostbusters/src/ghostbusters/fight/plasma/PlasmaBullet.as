package ghostbusters.fight.plasma {

import com.whirled.contrib.core.*;
import com.whirled.contrib.core.objects.SceneObject;
import com.whirled.contrib.core.resource.*;

import flash.display.DisplayObject;

import ghostbusters.fight.common.*;

public class PlasmaBullet extends SceneObject
{
    public static const RADIUS :Number = 6;
    public static const GROUP_NAME :String = "PlasmaBullet";

    public function PlasmaBullet (displayClass :Class)
    {
        _displayObject = new displayClass();
    }

    override public function get displayObject () :DisplayObject
    {
        return _displayObject;
    }

    override public function get objectGroups () :Array
    {
        return [ GROUP_NAME ];
    }

    protected var _displayObject :DisplayObject;
}

}