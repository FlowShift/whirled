package flashmob.server {

import com.whirled.avrg.*;

import flash.utils.getTimer;

public class ServerCtx
{
    public static var gameCtrl :AVRServerGameControl;
    public static var spectacleDb :SpectacleDb = new SpectacleDb();

    public static function getPlayerRoom (playerId :int) :int
    {
        var ctrl :PlayerSubControlBase = gameCtrl.getPlayer(playerId);
        return (ctrl != null ? ctrl.getRoomId() : 0);
    }

    public static function getAvatarInfo (playerId :int) :AVRGameAvatar
    {
        return gameCtrl.getRoom(getPlayerRoom(playerId)).getAvatarInfo(playerId);
    }

    public static function get timeNow () :Number
    {
        return flash.utils.getTimer() / 1000;
    }
}

}
