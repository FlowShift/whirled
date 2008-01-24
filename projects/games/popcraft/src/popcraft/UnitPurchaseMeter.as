package popcraft {

import com.whirled.contrib.core.*;
import com.whirled.contrib.core.objects.*;

import popcraft.battle.*;

import flash.display.*;
import mx.controls.Text;

public class UnitPurchaseMeter extends SceneObject
{
    public function UnitPurchaseMeter (unitType :uint)
    {
        _unitType = unitType;

        var data :UnitData = Constants.UNIT_DATA[_unitType];

        var yOffset :Number = 0;

        // how much does it cost?
        for (var resType :uint = 0; resType < Constants.RESOURCE__LIMIT; ++resType) {
            var resData :ResourceType = Constants.getResource(resType);
            var resCost :int = data.getResourceCost(resType);

            if (resCost == 0) {
                continue;
            }

            // create a new meter
            var rectMeter :RectMeter = new RectMeter();
            rectMeter.width = METER_WIDTH;
            rectMeter.height = METER_HEIGHT;
            rectMeter.minValue = 0;
            rectMeter.maxValue = resCost;
            rectMeter.value = resCost;
            rectMeter.foregroundColor = resData.color;
            rectMeter.backgroundColor = 0xFFFFFF;
            rectMeter.outlineColor = 0x000000;
            rectMeter.displayObject.y = yOffset;

            var textMeter :IntTextMeter = new IntTextMeter();
            textMeter.minValue = 0;
            textMeter.maxValue = resCost;
            textMeter.value = 0;
            textMeter.textColor = 0x000000;
            textMeter.displayObject.x = 2;
            textMeter.displayObject.y = yOffset - 8; // @TODO - why isn't this lining up?

            yOffset += METER_HEIGHT + METER_YOFFSET;

            GameMode.instance.addObject(rectMeter, _sprite);
            GameMode.instance.addObject(textMeter, _sprite);
            _meters.push(rectMeter);
            _meters.push(textMeter);
        }

        updateDisplay();
    }

    override protected function destroyed () :void
    {
        for each (var meter :AppObject in _meters) {
            meter.destroySelf();
        }
    }

    override protected function update (dt :Number) :void
    {
        updateDisplay();
    }

    protected function updateDisplay () :void
    {
        var data :UnitData = Constants.UNIT_DATA[_unitType];

        var meterIndex :uint = 0;
        for (var resType :uint = 0; resType < Constants.RESOURCE__LIMIT; ++resType) {

            var resCost :int = data.getResourceCost(resType);

            if (resCost == 0) {
                continue;
            }

            var rectMeter :RectMeter = (_meters[meterIndex] as RectMeter);
            var textMeter :IntTextMeter = (_meters[meterIndex + 1] as IntTextMeter);
            meterIndex += 2;

            var resAmount :int = GameMode.instance.playerData.getResourceAmount(resType);

            rectMeter.value = Math.max(0, resCost - resAmount);
            textMeter.value = Math.min(resCost, resAmount);
        }
    }

    override public function get displayObject () :DisplayObject
    {
        return _sprite;
    }

    protected var _sprite :Sprite = new Sprite();
    protected var _meters :Array = new Array();
    protected var _unitType :uint;

    protected static const METER_WIDTH :int = 30;
    protected static const METER_HEIGHT :int = 9;
    protected static const METER_YOFFSET :int = 4;
}

}
