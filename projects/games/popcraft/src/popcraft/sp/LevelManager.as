package popcraft.sp {

import com.whirled.contrib.simplegame.resource.*;

import popcraft.*;
import popcraft.data.*;
import popcraft.util.*;

public class LevelManager
{
    public function LevelManager ()
    {
        _levelRsrcMgr.addEventListener(ResourceLoadEvent.LOADED, onResourcesLoaded);
        _levelRsrcMgr.addEventListener(ResourceLoadEvent.ERROR, onResourceLoadErr);
    }

    public function playLevel (forceReload :Boolean = false) :void
    {
        if (forceReload) {
            _loadedLevel = null;
        }

        if (null != _loadedLevel) {
            this.startGame();
        } else {
            // load the level
            if (null == _loadedLevel) {
                var loadParams :Object = (Constants.DEBUG_LOAD_LEVELS_FROM_DISK ?
                    { url: "levels/level" + String(_curLevelNum + 1) + ".xml" } :
                    { embeddedClass: LEVELS[_curLevelNum] });

                _levelRsrcMgr.unload("level");
                _levelRsrcMgr.pendResourceLoad("level", "level", loadParams);
            }

            _levelRsrcMgr.load();
        }
    }

    public function get curLevelNum () :int
    {
        return _curLevelNum;
    }

    public function set curLevelNum (val :int) :void
    {
        val %= LEVELS.length;

        if (_curLevelNum != val) {
            _curLevelNum = val;
            _loadedLevel = null;
        }
    }

    public function incrementLevelNum () :void
    {
        this.curLevelNum = _curLevelNum + 1;
    }

    public function get numLevels () :int
    {
        return LEVELS.length;
    }

    protected function onResourcesLoaded (...ignored) :void
    {
        _loadedLevel = (_levelRsrcMgr.getResource("level") as LevelResourceLoader).levelData;

        this.startGame();
    }

    protected function onResourceLoadErr (e :ResourceLoadEvent) :void
    {
        AppContext.mainLoop.unwindToMode(new LevelLoadErrorMode(e.data as String));
    }

    protected function startGame () :void
    {
        GameContext.gameType = GameContext.GAME_TYPE_SINGLEPLAYER;
        GameContext.spLevel = _loadedLevel;
        AppContext.mainLoop.unwindToMode(new GameMode());
    }

    protected var _levelRsrcMgr :ResourceManager = new ResourceManager();
    protected var _curLevelNum :int = 0;
    protected var _loadedLevel :LevelData;

    // Embedded level data
    [Embed(source="../../../levels/level1.xml", mimeType="application/octet-stream")]
    protected static const LEVEL_1 :Class;
    [Embed(source="../../../levels/level2.xml", mimeType="application/octet-stream")]
    protected static const LEVEL_2 :Class;
    [Embed(source="../../../levels/level3.xml", mimeType="application/octet-stream")]
    protected static const LEVEL_3 :Class;

    protected static const LEVELS :Array = [ LEVEL_1, LEVEL_2, LEVEL_3 ];

}

}
