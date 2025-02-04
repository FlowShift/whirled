package ghostbusters.client.fight {
    
public class WeaponType
{
    public static const NAME_QUOTE :String = "Quote";
    public static const NAME_VOTE :String = "Vote";
    public static const NAME_IRAQ :String = "Iraq";
    public static const NAME_PRESS :String = "Press";
    
    public static const WEAPONS :Array = [NAME_QUOTE, NAME_IRAQ, NAME_PRESS, NAME_VOTE];
    
    public var name :String;
    public var level :int;
    
    public function WeaponType (name :String, level :int)
    {
        this.name = name;
        this.level = level;
    }
    
    public function equals (rhs :WeaponType) :Boolean
    {
        if (null == rhs) {
            return false;
        }
        
        if (this == rhs) {
            return true;
        }
        
        return (name == rhs.name && level == rhs.level);
    }
    
    public function toString () :String
    {
        return name + " [level " + level + "]";
    }
    
    
}

}