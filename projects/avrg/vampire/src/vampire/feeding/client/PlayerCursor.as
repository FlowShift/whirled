package vampire.feeding.client {

import vampire.feeding.*;

import com.threerings.flash.MathUtil;
import com.threerings.flash.Vector2;
import com.whirled.contrib.simplegame.SimObjectRef;

public class PlayerCursor extends CollidableObj
{
    public function PlayerCursor (playerType :int)
    {
        _radius = Constants.CURSOR_RADIUS;
        _playerType = playerType;
    }

    public function set moveTarget (val :Vector2) :void
    {
        _moveDirection = val.subtract(_loc).normalizeLocal();
    }

    override protected function update (dt :Number) :void
    {
        super.update(dt);

        // update location
        var moveDist :Number = this.speed * dt;
        _loc.x += (_moveDirection.x * moveDist);
        _loc.y += (_moveDirection.y * moveDist);
        _loc = GameCtx.clampLoc(_loc);

        // collide with cells
        var cell :Cell = Cell.getCellCollision(this);
        if (cell != null) {
            if (cell.type == Constants.CELL_WHITE) {
                //_whiteCellCount++;
                //dispatchEvent(new GameEvent(GameEvent.ATTACHED_CELL, cell));
                cell.attachToCursor(this);
                _attachedWhiteCells.push(cell.ref);

            } else {
                // create a cell burst
                GameObjects.createRedBurst(cell);
            }
        }

        // collide with the arteries
        var crossedCtr :Boolean =
            (_loc.x >= Constants.GAME_CTR.x && _lastLoc.x < Constants.GAME_CTR.x) ||
            (_loc.x < Constants.GAME_CTR.x && _lastLoc.x >= Constants.GAME_CTR.x);

        var artery :int = -1;
        if (crossedCtr) {
            if (_loc.y < Constants.GAME_CTR.y && canCollideArtery(Constants.ARTERY_TOP)) {
                artery = Constants.ARTERY_TOP;
            } else if (_loc.y >= Constants.GAME_CTR.y && canCollideArtery(Constants.ARTERY_BOTTOM)) {
                artery = Constants.ARTERY_BOTTOM;
            }

            if (artery != -1) {
                collideArtery(artery);
            } else {
                // we're prevented from crossing the artery
                _loc.x = (_loc.x >= Constants.GAME_CTR.x ?
                            Constants.GAME_CTR.x - 1 : Constants.GAME_CTR.x);
            }
        }

        _lastLoc = _loc.clone();
    }

    public function offsetSpeedPenalty (offset :Number) :void
    {
        _speedPenalty = Math.max(_speedPenalty + offset, 0);
    }

    public function offsetSpeedBonus (offset :Number) :void
    {
        _speedBonus = Math.max(_speedBonus + offset, 0);
    }

    public function get playerType () :int
    {
        return _playerType;
    }

    public function get numWhiteCells () :int
    {
        return _attachedWhiteCells.length;
    }

    protected function collideArtery (arteryType :int) :void
    {
        // get rid of cells
        var hadWhiteCell :Boolean;
        for each (var cellRef :SimObjectRef in _attachedWhiteCells) {
            if (!cellRef.isNull) {
                hadWhiteCell = true;
                cellRef.object.destroySelf();
            }
        }

        _attachedWhiteCells = [];
        //dispatchEvent(new GameEvent(GameEvent.DETACHED_ALL_CELLS));

        _lastArtery = arteryType;

        // Deliver a white cell to the heart
        if (hadWhiteCell) {
            dispatchEvent(new GameEvent(GameEvent.WHITE_CELL_DELIVERED));
        }

        // animate the white cell delivery
        /*var sprite :Sprite = SpriteUtil.createSprite();
        sprite.addChild(ClientCtx.createCellBitmap(Constants.CELL_WHITE));
        var animationObj :SceneObject = new SimpleSceneObject(sprite);
        animationObj.x = Constants.GAME_CTR.x;
        animationObj.y = this.y;
        animationObj.addTask(ScaleTask.CreateSmooth(2, 2, 1));
        animationObj.addTask(new SerialTask(
            LocationTask.CreateEaseIn(Constants.GAME_CTR.x, Constants.GAME_CTR.y, 1),
            new SelfDestructTask()));
        GameCtx.gameMode.addObject(animationObj, GameCtx.cellLayer);*/
    }

    protected function canCollideArtery (arteryType :int) :Boolean
    {
        return true;
    }

    protected function get speed () :Number
    {
        return MathUtil.clamp(
            Constants.CURSOR_SPEED_BASE + _speedBonus - _speedPenalty,
            Constants.CURSOR_SPEED_MIN,
            Constants.CURSOR_SPEED_MAX);
    }

    protected var _playerType :int;

    protected var _moveDirection :Vector2 = new Vector2();
    protected var _speedPenalty :Number = 0;
    protected var _speedBonus :Number = 0;

    protected var _attachedWhiteCells :Array = [];

    protected var _lastLoc :Vector2 = new Vector2();
    protected var _lastArtery :int = -1;
}

}