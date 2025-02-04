package vampire.quest {

public class Constants
{
    public static const DEBUG_ENABLE_QUESTS :Boolean = false;

    // 24 hours between each quest juice refresh
    public static const JUICE_REFRESH_MS :Number = 24 * 60 * 60 * 1000;

    // The amount of juice we give players, each refresh
    public static const JUICE_REFRESH_AMOUNT :int = 1;

    // The max amount of juice a player can be refreshed to (they can have more
    // than this, they just won't get any more than this from a refresh)
    public static const JUICE_REFRESH_MAX :int = int.MAX_VALUE;
}

}
