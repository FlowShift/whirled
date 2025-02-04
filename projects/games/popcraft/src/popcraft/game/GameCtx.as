//
// $Id$

package popcraft.game {

import com.threerings.util.ArrayUtil;
import com.threerings.flashbang.audio.AudioChannel;
import com.threerings.flashbang.audio.AudioControls;
import com.threerings.flashbang.audio.AudioManager;

import flash.display.Sprite;

import popcraft.*;
import popcraft.game.battle.*;
import popcraft.game.battle.geom.ForceParticleContainer;
import popcraft.game.battle.view.*;
import popcraft.gamedata.*;
import popcraft.game.puzzle.*;
import popcraft.ui.DashboardView;

public class GameCtx
{
    public static const GAME_TYPE_BATTLE_MP :int = 0;
    public static const GAME_TYPE_STORY :int = 1;
    public static const GAME_TYPE_ENDLESS_SP :int = 2;
    public static const GAME_TYPE_ENDLESS_MP :int = 3;

    public static function get isStoryGame () :Boolean
    {
        return gameType == GAME_TYPE_STORY;
    }

    public static function get isEndlessGame () :Boolean
    {
        return (gameType == GAME_TYPE_ENDLESS_SP || gameType == GAME_TYPE_ENDLESS_MP);
    }

    public static function get isMultiplayerGame () :Boolean
    {
        return (gameType == GAME_TYPE_BATTLE_MP || gameType == GAME_TYPE_ENDLESS_MP);
    }

    public static function get isSinglePlayerGame () :Boolean
    {
        return !isMultiplayerGame;
    }

    /* Frequently-used values that are cached here for performance reasons */
    public static var mapScaleXInv :Number;
    public static var mapScaleYInv :Number;
    public static var scaleSprites :Boolean;

    public static var gameType :int;
    public static var gameData :GameData;
    public static var playerStats :PlayerStats;

    public static var gameMode :GameMode;
    public static var netObjects :NetObjectDB;
    public static var battleBoardView :BattleBoardView;
    public static var diurnalCycle :DiurnalCycle;
    public static var dashboard :DashboardView;
    public static var puzzleBoard :PuzzleBoard;
    public static var forceParticleContainer :ForceParticleContainer;
    public static var unitFactory :UnitFactory;

    public static var overlayLayer :Sprite;
    public static var dashboardLayer :Sprite;
    public static var battleLayer :Sprite;

    public static var playAudio :Boolean;
    public static var musicControls :AudioControls;
    public static var sfxControls :AudioControls;

    public static var playerInfos :Array;
    public static var localPlayerIndex :int;

    public static var winningTeamId :int;

    public static function getTeamSize (teamId :int) :int
    {
        var size :int;
        for each (var playerInfo :PlayerInfo in playerInfos) {
            if (playerInfo.teamId == teamId) {
                size += 1;
            }
        }

        return size;
    }

    public static function get canResurrect () :Boolean
    {
        return (gameType == GAME_TYPE_ENDLESS_MP);
    }

    public static function get localPlayerInfo () :LocalPlayerInfo
    {
        return playerInfos[localPlayerIndex];
    }

    public static function get numPlayers () :int
    {
        return playerInfos.length;
    }

    public static function getActiveSpellSet (playerIndex :int) :CreatureSpellSet
    {
        return PlayerInfo(playerInfos[playerIndex]).activeSpells;
    }

    public static function getPlayerByName (playerName :String) :PlayerInfo
    {
        return ArrayUtil.findIf(
            playerInfos,
            function (info :PlayerInfo) :Boolean { return info.playerName == playerName; });
    }

    public static function isEnemy (playerIndex :int, otherPlayerIndex :int) :Boolean
    {
        return PlayerInfo(playerInfos[playerIndex]).teamId !=
            PlayerInfo(playerInfos[otherPlayerIndex]).teamId;
    }

    public static function isTargetableEnemy (player :PlayerInfo, otherPlayer :PlayerInfo) :Boolean
    {
        return (player.teamId != otherPlayer.teamId && otherPlayer.isAlive &&
                !otherPlayer.isInvincible);
    }

    public static function findEnemyForPlayer (playerInfo :PlayerInfo) :PlayerInfo
    {
        var playerIdx :int = playerInfo.playerIndex;

        // find the first player after this one that is on an opposing team
        for (var ii :int = 0; ii < playerInfos.length - 1; ++ii) {
            var otherPlayerIdx :int = (playerIdx + ii + 1) % playerInfos.length;
            var otherPlayer :PlayerInfo = playerInfos[otherPlayerIdx];
            if (isTargetableEnemy(playerInfo, otherPlayer)) {
                return otherPlayer;
            }
        }

        return null;
    }

    public static function getNextEnemyForPlayer (playerInfo :PlayerInfo) :PlayerInfo
    {
        var curEnemy :PlayerInfo = playerInfo.targetedEnemy;
        if (curEnemy == null) {
            return null;
        }

        var curEnemyIdx :int = curEnemy.playerIndex;

        for (var ii :int = 0; ii < playerInfos.length - 1; ++ii) {
            var otherPlayerIdx :int = (curEnemyIdx + ii + 1) % playerInfos.length;
            var otherPlayer :PlayerInfo = playerInfos[otherPlayerIdx];
            if (isTargetableEnemy(playerInfo, otherPlayer)) {
                return otherPlayer;
            }
        }

        return null;
    }

    public static function findPlayerTeammate (playerIndex :int) :PlayerInfo
    {
        var thisPlayer :PlayerInfo = playerInfos[playerIndex];
        for each (var otherPlayer :PlayerInfo in playerInfos) {
            if (otherPlayer != thisPlayer && otherPlayer.teamId == thisPlayer.teamId) {
                return otherPlayer;
            }
        }

        return null;
    }

    public static function playGameSound (soundName :String) :AudioChannel
    {
        return (playAudio ? ClientCtx.audio.playSoundNamed(soundName, sfxControls) :
            new AudioChannel());
    }

    public static function playGameMusic (musicName :String) :AudioChannel
    {
        return (playAudio ?
            ClientCtx.audio.playSound(Resources.getMusic(musicName), musicControls, AudioManager.LOOP_FOREVER) :
            new AudioChannel());
    }
}

}
