package {

import flash.display.BitmapData;
import flash.events.Event;
import flash.geom.Point;

import com.threerings.util.HashMap;

import com.whirled.WhirledGameControl;

import maps.GroundMap;
import maps.Map;
import maps.PathMap;

import units.Tower;

/**
 * Game board, which can be queried for information about static board definition,
 * as well as positions of the different pieces.
 */
public class Board
{
    public static const WIDTH :int = 23;
    public static const HEIGHT :int = 24;

    public static const SQUARE_WIDTH :int = 30;
    public static const SQUARE_HEIGHT :int = 20;
    public static const PIXEL_WIDTH :int = 690;  // WIDTH * SQUARE_WIDTH
    public static const PIXEL_HEIGHT :int = 480; // HEIGHT * SQUARE_HEIGHT

    public static const PLAYER_COLORS :Array = [ 0x000000ff /* player 0 */,
                                                 0x0000ff00 /* player 1 */ ];

    public function Board (whirled :WhirledGameControl)
    {
        _whirled = whirled;

        _allmaps = new Array();

        _groundmap = new GroundMap();
        _allmaps.push(_groundmap);

        var count :int = getPlayerCount();
        _pathmaps = new Array(count);
        for (var ii :int = 0; ii < count; ii++) {
            _pathmaps[ii] = new PathMap(this, ii);
            _allmaps.push(_pathmaps[ii]);
        }

        for each (var m :Map in _allmaps) {
            m.clear();
        }
    }

    public function getMyPlayerIndex () :int
    {
        return _whirled.seating.getMyPosition();
    }

    public function getMyColor () :uint
    {
        return PLAYER_COLORS[getMyPlayerIndex()];
    }

    public function getPlayerCount () :uint
    {
        return _whirled.seating.getPlayerIds().length;
    }
    
    public function handleUnload (event : Event) :void
    {
        trace("BOARD UNLOAD");
    }

    public function processMaps () :void
    {
        for each (var map :Map in _allmaps) {
            map.update();
        }
    }
    
    public function reset () :void
    {
        var mapId :int = 1; // todo

        // reset everything
        for each (var m :Map in _allmaps) {
            m.clear();
        }

        // initialize the ground map
        _groundmap.loadDefinition(mapId, getPlayerCount());

        // and based on that, the pathfinding maps
        for (var ii :int = 0; ii < getPlayerCount(); ii++) {
            var t :Point = getPlayerTarget(ii);
            (_pathmaps[ii] as PathMap).setTarget(t.x, t.y);
        }
    }
    
    // Functions used by game logic to mark / clear towers on the board

    public function markAsOccupied (tower :Tower) :void
    {
        // mark the main map
        _groundmap.fillAllTowerCells(tower, tower.player);
        // ... and force all pathing maps to get recalculated
        for each (var m :PathMap in _pathmaps) {
            m.fillAllTowerCells(tower, tower.player);
        }
    }
    
    public function isUnoccupied (tower :Tower) :Boolean
    {
        return _groundmap.isEachTowerCellEqual(tower, Map.UNOCCUPIED);
    }

    public function isOnBoard (tower :Tower) :Boolean
    {
        return (tower.x >= 0 && tower.y >= 0 &&
                tower.x + tower.width <= WIDTH && tower.y + tower.height <= HEIGHT);
    }

    public function getPlayerSource (playerIndex :int) :Point
    {
        return _groundmap.getPlayerSource(playerIndex).clone();
    }
    
    public function getPlayerTarget (playerIndex :int) :Point
    {
        return _groundmap.getPlayerTarget(playerIndex).clone();
    }

    public function towerIndexToPosition (index :int) :Point
    {
        return new Point(int(index / HEIGHT), int(index % HEIGHT));
    }

    public function towerPositionToIndex (x :int, y :int) :int
    {
        return x * HEIGHT + y;
    }


    public function getMapOccupancy () :GroundMap
    {
        return _groundmap;
    }

    public function getPathMap (player :int) :PathMap
    {
        return _pathmaps[player];
    }
    
    /**
     * Converts screen coordinates (relative to the upper left corner of the board)
     * to logical coordinates in board space. Rounds results down to integer coordinates.
     */
    public static function screenToLogicalPosition (x :Number, y :Number) :Point
    {
        return new Point(int(Math.floor(x / SQUARE_WIDTH)), int(Math.floor(y / SQUARE_HEIGHT)));
    }

    /**
     * Converts board coordinates to screen coordinates (relative to upper left corner).
     */
    public static function logicalToScreenPosition (x :Number, y :Number) :Point
    {
        return new Point(x * SQUARE_WIDTH, y * SQUARE_HEIGHT);
    }


    /** Various game-related maps. */
    protected var _groundmap :GroundMap;
    protected var _pathmaps :Array; // of PathMap, indexed by player
    protected var _allmaps :Array; // of Map;
    
    /** Hash map of all towers, indexed by their id. */
    protected var _towers :HashMap = new HashMap();

    /** This is where we get game settings from. */
    protected var _whirled :WhirledGameControl;
}
}
