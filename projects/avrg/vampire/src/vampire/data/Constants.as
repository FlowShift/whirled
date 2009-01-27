package vampire.data
{
public class Constants
{
    /** 
    * The hourly loss of blood as a fraction of the maximum amount of blood of a vampire.
    */
    public static const BLOOD_LOSS_HOURLY_RATE :Number = 1.0 / 48;//After two days you lose all your blood

    /** 
    * The level when you are allowed to 'turn' (become a vampire) and also the 
    * level cap of a non-vampire.  That means vampires start at this level++,
    * because you go up a level when you become a vampire.
    */
    public static const MAXIMUM_LEVEL_FOR_NON_VAMPIRE :int = 5;
    
    /**
    * After a vampire awakes (starts the game after some time),
    * her blood is reduced proportionally to the time sleeping, 
    * to a minimum needed to move around.
    */
    public static const MINMUM_BLOOD_AFTER_SLEEPING :int = 5;
    
    public static function get MINIMUM_VAMPIRE_LEVEL() :int
    {
        return MAXIMUM_LEVEL_FOR_NON_VAMPIRE + 1;
    }
    
    public static const GAME_MODE_NOTHING :String = "Nothing";
    public static const GAME_MODE_FEED :String = "Feed";
    public static const GAME_MODE_EAT_ME :String = "EatMe";
    public static const GAME_MODE_FIGHT :String = "Fight";
    public static const GAME_MODE_BLOODBOND :String = "BloodBond";
    public static const GAME_MODE_HIERARCHY :String = "Hierarchy";
    
    public static const GAME_MODES :Array = [
                                        GAME_MODE_FEED, 
                                        GAME_MODE_EAT_ME,
                                        GAME_MODE_FIGHT, 
                                        GAME_MODE_BLOODBOND, 
                                        GAME_MODE_HIERARCHY
                                        ];
                                        
    
    
    
    public static const NAMED_EVENT_BLOOD_UP :String = "BloodUp";//Only for testing purposes
    public static const NAMED_EVENT_BLOOD_DOWN :String = "BloodDown";//Only for testing purposes
    public static const NAMED_EVENT_FEED :String = "Feed";//Only for testing purposes
        
    public static var LOCAL_DEBUG_MODE :Boolean = false;
    
    public static function MAX_BLOOD_FOR_LEVEL( level :int ) :Number
    {
        return level * 100;
    }
    
    public static const TIME_INTERVAL_PROXIMITY_CHECK :int = 1000;
}
}