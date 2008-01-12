package ghostbusters.fight.ouija {

import flash.geom.Matrix;
import flash.geom.Point;
import flash.display.InteractiveObject;

public class SpiritCursor extends Cursor
{
    public function SpiritCursor (board :InteractiveObject, locTransform :Matrix)
    {
        super(board);
        _locTransform = locTransform;
        _boardCenter = new Point(board.width / 2, board.height / 2);
    }

    override protected function updateLocation (localX :Number, localY :Number) :void
    {
        // distance from center of screen
        var d :Point = new Point(localX - _boardCenter.x, localY - _boardCenter.y);

        // transform
        var dTrans :Point = _locTransform.transformPoint(d);

        // apply
        super.updateLocation(_boardCenter.x + dTrans.x, _boardCenter.y + dTrans.y);
    }

    protected var _locTransform :Matrix;
    protected var _boardCenter :Point;

}

}
