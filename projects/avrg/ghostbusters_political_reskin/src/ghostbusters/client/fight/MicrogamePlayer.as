package ghostbusters.client.fight {

import com.threerings.util.ArrayUtil;
import com.whirled.contrib.simplegame.*;
import com.whirled.contrib.simplegame.audio.AudioManager;
import com.whirled.contrib.simplegame.resource.*;
import com.whirled.contrib.simplegame.util.*;

import flash.display.Sprite;
import flash.geom.Rectangle;

import ghostbusters.client.fight.common.*;
import ghostbusters.client.fight.lantern.*;
import ghostbusters.client.fight.ouija.*;
import ghostbusters.client.fight.plasma.*;
import ghostbusters.client.fight.potions.*;

public class MicrogamePlayer extends Sprite
{
    public function MicrogamePlayer (context :MicrogameContext)
    {
        _context = context;

        // clip games to the bounds of the player
        this.scrollRect = new Rectangle(0, 0, MicrogameConstants.GAME_WIDTH, MicrogameConstants.GAME_HEIGHT);

        if (null != MainLoop.instance) {
            MainLoop.instance.reset(this);
        } else {
            new MainLoop(this);
        }

        MainLoop.instance.run();

        Resources.instance.loadAll(resourcesLoaded);
    }

    public function shutdown () :void
    {
        MainLoop.instance.stop();
//        AudioManager.instance.stopAllSounds();
    }

    public function get weaponType () :WeaponType
    {
        return _weaponType;
    }

    public function set weaponType (type :WeaponType) :void
    {
        if (!type.equals(_weaponType)) {
            _weaponType = type;
            this.cancelCurrentGame();
        }
    }

    public function beginNextGame ( rotateToNextGame :Boolean = false) :Microgame
    {
        if (null == _weaponType) {
            throw new Error("weaponType must be set before the games can begin!");
        }
        
        if(rotateToNextGame) {
            nextWeaponType();
        }

        if (null != _currentGame) {
            _currentGame.end();
            _currentGame = null;
        }

        _currentGame = this.generateGame();

        if (!Resources.instance.isLoading) {
            _currentGame.begin();
        } else {
            // postpone the game beginning until loading has completed
            trace("pending game start until resources have completed loading");
            _gameStartPendingResourceLoad = true;
        }

        return _currentGame;
    }

    protected function resourcesLoaded () :void
    {
        if (_gameStartPendingResourceLoad) {
            _currentGame.begin();
        }
    }

    public function get currentGame () :Microgame
    {
        return _currentGame;
    }

    protected function generateGame () :MicrogameMode
    {
        var validDescriptors :Array = GAME_DESCRIPTORS.filter(isValidDescriptor);

        if (validDescriptors.length == 0) {
            throw new Error("No valid games for " + _weaponType);
        }

        var desc :MicrogameDescriptor = validDescriptors[Rand.nextIntRange(0, validDescriptors.length, Rand.STREAM_COSMETIC)];
        return desc.instantiateGame(_weaponType.level, _context);

        function isValidDescriptor(desc :MicrogameDescriptor, index :int, array :Array) :Boolean
        {
            return (desc.weaponTypeName == _weaponType.name && desc.baseDifficulty <= _weaponType.level);
        }
    }

    public function cancelCurrentGame () :void
    {
        MainLoop.instance.popAllModes();
        _currentGame = null;
    }
    
    /**
    * Rotates the weapons, to avoid repitition
    */
    public function nextWeaponType() :void
    {
        if( _weaponType == null) {
            _weaponType = new WeaponType(WeaponType.WEAPONS[0], 1);
            return;
        }
        
        var index :int = ArrayUtil.indexOf( WeaponType.WEAPONS, _weaponType.name);
        
        index++;
        if(index >= WeaponType.WEAPONS.length) {
            index = 0;
        }
        _weaponType = new WeaponType(WeaponType.WEAPONS[index], 1);
    }

    protected var _context :MicrogameContext;
    protected var _weaponType :WeaponType;
    protected var _running :Boolean;
    protected var _currentGame :MicrogameMode;
    protected var _gameStartPendingResourceLoad :Boolean;

    protected static const GAME_DESCRIPTORS :Array = [

        new MicrogameDescriptor(WeaponType.NAME_QUOTE,    0, HeartOfDarknessGame),
        //SKIN
//        new MicrogameDescriptor(WeaponType.NAME_VOTE,      0, GhostWriterGame),
        new MicrogameDescriptor(WeaponType.NAME_IRAQ,      0, PictoGeistGame),
        new MicrogameDescriptor(WeaponType.NAME_VOTE,      0, SpiritGuideGame),

        new MicrogameDescriptor(WeaponType.NAME_PRESS,     0, SpiritShellGame)

//        new MicrogameDescriptor(WeaponType.NAME_POTIONS,    0, HueAndCryGame),

    ];
}

}
