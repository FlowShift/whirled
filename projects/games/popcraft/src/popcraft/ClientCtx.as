//
// $Id$

package popcraft {

import com.whirled.contrib.LevelPackManager;
import com.threerings.flashbang.*;
import com.threerings.flashbang.audio.*;
import com.threerings.flashbang.resource.*;
import com.whirled.game.GameControl;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.MovieClip;
import flash.display.SimpleButton;

import popcraft.gamedata.*;
import popcraft.game.endless.EndlessLevelManager;
import popcraft.game.story.LevelManager;

public class ClientCtx
{
    public static var mainSprite :PopCraft;
    public static var mainLoop :MainLoop;
    public static var rsrcs :ResourceManager;
    public static var audio :AudioManager;
    public static var gameCtrl :GameControl;
    public static var randStreamPuzzle :uint;
    public static var levelMgr :LevelManager = new LevelManager();
    public static var endlessLevelMgr :EndlessLevelManager = new EndlessLevelManager();
    public static var globalPlayerStats :PlayerStats = new PlayerStats();
    public static var allLevelPacks :LevelPackManager = new LevelPackManager();
    public static var playerLevelPacks :LevelPackManager = new LevelPackManager();
    public static var prizeMgr :PrizeManager = new PrizeManager();
    public static var savedPlayerBits :SavedPlayerBits = new SavedPlayerBits();
    public static var seatingMgr :ClientSeatingManager = new ClientSeatingManager();
    public static var lobbyConfig :LobbyConfig = new LobbyConfig();

    public static var userCookieMgr :UserCookieManager;

    public static function awardTrophy (trophyName :String) :void
    {
        if (ClientCtx.gameCtrl.isConnected()) {
            if (gameCtrl.player.awardTrophy(trophyName)) {
                prizeMgr.awardPrizeForTrophy(trophyName);
            }
        } else {
            PopCraft.log.info("Trophy awarded: " + trophyName);
        }
    }

    public static function hasTrophy (trophyName :String) :Boolean
    {
        return (gameCtrl.isConnected() && gameCtrl.player.holdsTrophy(trophyName));
    }

    public static function get isMpCustomizationUnlocked () :Boolean
    {
        //return (ClientCtx.hasCompleatLevelPack || ClientCtx.hasAcademyLevelPack);
        return true;    // the game is free for everyone
    }

    public static function get isEndlessModeUnlocked () :Boolean
    {
        //return (ClientCtx.hasCompleatLevelPack || ClientCtx.hasAcademyLevelPack);
        return true;    // the game is free for everyone
    }

    public static function get isStoryModeUnlocked () :Boolean
    {
        /*return (ClientCtx.hasCompleatLevelPack || ClientCtx.hasIncidentLevelPack ||
                savedPlayerBits.hasFreeStoryMode);*/
        return true;    // the game is free for everyone
    }

    public static function get hasCompleatLevelPack () :Boolean
    {
        return (Constants.DEBUG_AWARD_COMPLEAT_LEVEL_PACK ||
                playerLevelPacks.getLevelPack(Constants.COMPLEAT_LEVEL_PACK_NAME) != null);
    }

    public static function get hasIncidentLevelPack () :Boolean
    {
        return (Constants.DEBUG_AWARD_INCIDENT_LEVEL_PACK ||
                playerLevelPacks.getLevelPack(Constants.INCIDENT_LEVEL_PACK_NAME) != null);
    }

    public static function get hasAcademyLevelPack () :Boolean
    {
        return (Constants.DEBUG_AWARD_ACADEMY_LEVEL_PACK ||
                playerLevelPacks.getLevelPack(Constants.ACADEMY_LEVEL_PACK_NAME) != null);
    }

    public static function get isMultiplayer () :Boolean
    {
        return (gameCtrl.isConnected() && gameCtrl.game.seating.getPlayerIds().length > 1);
    }

    public static function get defaultGameData () :GameData
    {
        return gameDataResource.gameData;
    }

    public static function get levelProgression () :LevelProgressionData
    {
        return gameDataResource.levelProgression;
    }

    public static function get multiplayerSettings () :Array
    {
        return gameDataResource.multiplayerSettings;
    }

    /*public static function get gameVariants () :Array
    {
        var variantResource :GameVariantsResource =
            GameVariantsResource(ClientContext.rsrcs.getResource(Constants.RSRC_GAMEVARIANTS));
        return variantResource.variants;
    }*/

    public static function showMultiplayerLobby () :void
    {
        if (gameCtrl.isConnected()) {
            gameCtrl.local.showGameLobby(true);
        }
    }

    public static function showCombinedLobby () :void
    {
        if (gameCtrl.isConnected()) {
            gameCtrl.local.showGameLobby(false);
        }
    }

    public static function showIncidentGameShop () :void
    {
        if (gameCtrl.isConnected()) {
            gameCtrl.local.showGameShop(GameControl.LEVEL_PACK_SHOP,
                Constants.INCIDENT_LEVEL_PACK_ID);
        }
    }

    public static function showAcademyGameShop () :void
    {
        if (gameCtrl.isConnected()) {
            gameCtrl.local.showGameShop(GameControl.LEVEL_PACK_SHOP,
                Constants.ACADEMY_LEVEL_PACK_ID);
        }
    }

    public static function reloadLevelPacks () :void
    {
        if (gameCtrl.isConnected()) {
            allLevelPacks.init(gameCtrl.game.getLevelPacks());
            playerLevelPacks.init(gameCtrl.player.getPlayerLevelPacks());

            PopCraft.log.info("Level packs: " + allLevelPacks.getAvailableIdents() +
                "\nPlayer level packs: " + playerLevelPacks.getAvailableIdents());
        }
    }

    public static function instantiateMovieClip (rsrcName :String, className :String,
        disableMouseInteraction :Boolean = false, fromCache :Boolean = false) :MovieClip
    {
        return SwfResource.instantiateMovieClip(
            rsrcs,
            rsrcName,
            className,
            disableMouseInteraction,
            fromCache);
    }

    public static function instantiateButton (rsrcName :String, className :String) :SimpleButton
    {
        return SwfResource.instantiateButton(rsrcs, rsrcName, className);
    }

    public static function getSwfDisplayRoot (rsrcName :String) :DisplayObject
    {
        return SwfResource.getSwfDisplayRoot(rsrcs, rsrcName);
    }

    public static function getSwfBitmapData (rsrcName :String, bitmapName :String, width :int,
        height :int) :BitmapData
    {
        return SwfResource.getBitmapData(rsrcs, rsrcName, bitmapName, width, height);
    }

    public static function instantiateBitmap (rsrcName :String) :Bitmap
    {
        return ImageResource.instantiateBitmap(rsrcs, rsrcName);
    }

    protected static function get gameDataResource () :GameDataResource
    {
        return GameDataResource(rsrcs.getResource(Constants.RSRC_DEFAULTGAMEDATA));
    }
}

}
