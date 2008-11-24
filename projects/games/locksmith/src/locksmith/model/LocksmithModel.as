//
// $Id$

package locksmith.model {

import com.whirled.contrib.EventHandlerManager;

public class LocksmithModel
{
    public function LocksmithModel (gameCtrl :GameControl, eventMgr :EventHandlerManager)
    {
        _gameCtrl = gameCtrl;
        _eventMgr  = eventMgr;

        _ringMgr = new RingManager(gameCtrl, _eventMgr);
        _turnMgr = new TurnManager(gameCtrl, _eventMgr);
    }

    public function get ringMgr () :RingManager
    {
        return _ringMgr;
    }

    public function get turnMgr () :TurnManager
    {
        return _turnMgr;
    }

    protected var _eventMgr :EventHandlerManager;
    protected var _ringMgr :RingManager;
    protected var _turnMgr :TurnManager;
}
}