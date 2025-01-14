package vampire.feeding.client {

import com.threerings.flashbang.ObjectMessage;
import com.threerings.flashbang.ObjectTask;
import com.threerings.flashbang.GameObject;
import com.threerings.flashbang.components.LocationComponent;

public class AdvancedLocationTask
    implements ObjectTask
{
    public function AdvancedLocationTask (
        x :Number,
        y :Number,
        time :Number,
        xInterpolator :Function,
        yInterpolator :Function)
    {
        _toX = x;
        _toY = y;
        _totalTime = Math.max(time, 0);
        _xInterpolator = xInterpolator;
        _yInterpolator = yInterpolator;
    }

    public function update (dt :Number, obj :GameObject) :Boolean
    {
        var lc :LocationComponent = (obj as LocationComponent);

        if (null == lc) {
            throw new Error("AdvancedLocationTask can only be applied to GameObjects that " +
                            "implement LocationComponent");
        }

        if (0 == _elapsedTime) {
            _fromX = lc.x;
            _fromY = lc.y;
        }

        _elapsedTime += dt;

        if (_totalTime <= 0) {
            lc.x = _toX;
            lc.y = _toY;

        } else {
            var totalMs :Number = _totalTime * 1000;
            var elapsedMs :Number = Math.min(_elapsedTime * 1000, totalMs);

            lc.x = _xInterpolator(elapsedMs, _fromX, (_toX - _fromX), totalMs);
            lc.y = _yInterpolator(elapsedMs, _fromY, (_toY - _fromY), totalMs);
        }

        return (_elapsedTime >= _totalTime);
    }

    public function clone () :ObjectTask
    {
        return new AdvancedLocationTask(_toX, _toY, _totalTime, _xInterpolator, _yInterpolator);
    }

    public function receiveMessage (msg :ObjectMessage) :Boolean
    {
        return false;
    }

    protected var _xInterpolator :Function;
    protected var _yInterpolator :Function;

    protected var _toX :Number;
    protected var _toY :Number;

    protected var _fromX :Number;
    protected var _fromY :Number;

    protected var _totalTime :Number = 0;
    protected var _elapsedTime :Number = 0;
}

}
