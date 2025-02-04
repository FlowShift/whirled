package redrover.game {

import com.threerings.flashbang.GameObject;
import com.threerings.flashbang.tasks.*;

import redrover.*;

public class GemSpawner extends GameObject
{
    public static function getAll () :Array
    {
        return GameCtx.gameMode.getObjectsInGroup(GROUP_NAME);
    }

    public function GemSpawner (board :Board, gemType :int, gridX :int, gridY :int)
    {
        _board = board;
        _gemType = gemType;
        _gridX = gridX;
        _gridY = gridY;
    }

    public function get board () :Board
    {
        return _board;
    }

    public function get gemType () :int
    {
        return _gemType;
    }

    public function get gridX () :int
    {
        return _gridX;
    }

    public function get gridY () :int
    {
        return _gridY;
    }

    override public function getObjectGroup (groupNum :int) :String
    {
        if (groupNum == 0) {
            return GROUP_NAME;
        } else {
            return super.getObjectGroup(groupNum - 1);
        }
    }

    override protected function update (dt :Number) :void
    {
        if (!_createdFirstGem) {
            createGem();
            _createdFirstGem = true;

        } else if (!_gemScheduled && !_board.getCell(_gridX, _gridY).hasGem) {
            scheduleGem();
        }
    }

    protected function scheduleGem () :void
    {
        removeAllTasks();

        var spawnTime :Number = GameCtx.levelData.gemSpawnTime.next();
        addTask(After(spawnTime, new FunctionTask(
            function () :void {
                createGem();
                _gemScheduled = false;
            })));

        _gemScheduled = true;
    }

    protected function createGem () :void
    {
        GameCtx.gameMode.createGem(_board.teamId, _gridX, _gridY, _gemType);
    }

    protected var _board :Board;
    protected var _gemType :int;
    protected var _gridX :int;
    protected var _gridY :int;

    protected var _createdFirstGem :Boolean;
    protected var _gemScheduled :Boolean;

    protected static const GROUP_NAME :String = "GemSpawner";
}

}
