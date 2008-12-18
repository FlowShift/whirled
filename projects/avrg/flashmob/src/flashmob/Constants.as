package flashmob {

public class Constants
{
    public static const GAME_SIZE_ANY :int = -1;
    public static const GAME_SIZE_SMALL :int = 0;
    public static const GAME_SIZE_LARGE :int = 1;

    // Min players, Max players
    public static const GAME_SIZE_PARAMS :Array = [
        [ 2, 6 ],       // Small
        [ 7, 999 ],     // Large
    ];

    public static const MIN_SPECTACLE_PATTERNS :int = 2;
    public static const MAX_SPECTACLE_PATTERNS :int = 10;

    // Time that has to elapse between multiple snapshots
    public static const MIN_SNAPSHOT_TIME :Number = 1;

    // Game states
    public static const STATE_INVALID :int = 0;
    public static const STATE_SPECTACLE_CHOOSER :int = 1;
    public static const STATE_SPECTACLE_CREATOR :int = 2;
    public static const STATE_SPECTACLE_PLAY :int = 3;

    // Properties
    public static const PROP_GAMESTATE :String          = "gs";
    public static const PROP_PLAYERS :String            = "pl";
    public static const PROP_WAITINGFORPLAYERS :String  = "wp";
    public static const PROP_SPECTACLE :String          = "sp";

    // Messages
    public static const MSG_RESETGAME :String           = "rg";
    public static const MSG_SNAPSHOT :String            = "ss";
    public static const MSG_SNAPSHOTACK :String         = "sa";
    public static const MSG_SNAPSHOTERR :String         = "se";
    public static const MSG_DONECREATING :String        = "dc"; // value=name of spectacle
}

}
