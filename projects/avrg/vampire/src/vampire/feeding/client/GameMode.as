package vampire.feeding.client {

import com.threerings.flashbang.*;
import com.threerings.flashbang.audio.AudioChannel;
import com.threerings.flashbang.objects.SimpleSceneObject;
import com.threerings.flashbang.tasks.*;
import com.threerings.flashbang.util.*;
import com.threerings.geom.Vector2;
import com.threerings.util.Log;
import com.threerings.util.Map;
import com.threerings.util.Maps;
import com.whirled.avrg.AVRGameControlEvent;
import com.whirled.contrib.messagemgr.*;

import flash.display.MovieClip;
import flash.display.Sprite;
import flash.text.TextField;

import vampire.client.SpriteUtil;
import vampire.feeding.*;
import vampire.feeding.net.*;
import vampire.server.Trophies;

public class GameMode extends AppMode
{
    public function GameMode ()
    {
        GameCtx.init();
        GameCtx.gameMode = this;
    }

    public function sendMultiplier (multiplier :int, x :int, y :int) :void
    {
        if (GameCtx.gameOver) {
            return;
        }

        if (GameCtx.isMultiplayer) {
            ClientCtx.msgMgr.sendMessage(CreateMultiplierMsg.create(
                ClientCtx.localPlayerId,
                x, y,
                multiplier));

        } else {
            // In single-player games, there's nobody else to volley our multipliers back
            // to us, so we fake it by occasionally sending fake multipliers to ourselves
            if (Rand.nextNumber(Rand.STREAM_GAME) < Constants.SP_MULTIPLIER_RETURN_CHANCE) {
                var sendMultiplierObj :GameObject = new GameObject();
                var loc :Vector2 = new Vector2(x, y);
                loc.x += Rand.nextNumberInRange(5, 25, Rand.STREAM_COSMETIC);
                loc.y += Rand.nextNumberInRange(5, 25, Rand.STREAM_COSMETIC);
                sendMultiplierObj.addTask(new SerialTask(
                    new TimedTask(Constants.SP_MULTIPLIER_RETURN_TIME.next()),
                    new FunctionTask(function () :void {
                        onCreateMultiplier(CreateMultiplierMsg.create(
                            Constants.NULL_PLAYER,
                            loc.x, loc.y,
                            Math.min(multiplier, Constants.MAX_MULTIPLIER)));
                    }),
                    new SelfDestructTask()));
                addObject(sendMultiplierObj);
            }
        }
    }

    public function onHeartbeat () :void
    {
        // spawn new red cells
        spawnCells(Constants.CELL_RED, Constants.BEAT_CELL_BIRTH_COUNT.next());
    }

    public function onWhiteCellBurst () :void
    {
        GameCtx.gotCorruption = true;
    }

    override protected function setup () :void
    {
        super.setup();

        if (!ClientCtx.clientSettings.spOnly) {
            registerListener(ClientCtx.msgMgr, ClientMsgEvent.MSG_RECEIVED, onMsgReceived);
        }

        if (!Constants.DEBUG_DISABLE_ROOM_OVERLAY) {
            addSceneObject(new RoomOverlay(), _modeSprite);
        }

        // Setup display layers
        var gameParent :Sprite = new Sprite();
        _modeSprite.addChild(gameParent);

        GameCtx.helpLayer = new Sprite();
        _modeSprite.addChild(GameCtx.helpLayer);

        GameCtx.bgLayer = SpriteUtil.createSprite(false, true);
        GameCtx.cellBirthLayer = SpriteUtil.createSprite();
        GameCtx.heartLayer = SpriteUtil.createSprite();
        GameCtx.burstLayer = SpriteUtil.createSprite();
        GameCtx.cellLayer = SpriteUtil.createSprite();
        GameCtx.cursorLayer = SpriteUtil.createSprite();
        GameCtx.effectLayer = SpriteUtil.createSprite();
        GameCtx.uiLayer = SpriteUtil.createSprite(true, false);
        gameParent.addChild(GameCtx.bgLayer);
        gameParent.addChild(GameCtx.cellBirthLayer);
        gameParent.addChild(GameCtx.heartLayer);
        gameParent.addChild(GameCtx.burstLayer);
        gameParent.addChild(GameCtx.cellLayer);
        gameParent.addChild(GameCtx.cursorLayer);
        gameParent.addChild(GameCtx.effectLayer);
        gameParent.addChild(GameCtx.uiLayer);

        if (Constants.DEBUG_SHOW_STATS) {
            var statView :StatView = new StatView();
            statView.x = 0;
            statView.y = 460;
            addSceneObject(statView, GameCtx.effectLayer);
        }

        // Setup game objects
        GameCtx.tipFactory = new TipFactory();

        var isCorruption :Boolean = ClientCtx.isCorruption;

        var bg :MovieClip = ClientCtx.instantiateMovieClip("blood",
            (isCorruption ? "background_corruption" : "background"));
        bg.cacheAsBitmap = true;
        bg.x = Constants.GAME_CTR.x;
        bg.y = Constants.GAME_CTR.y;
        GameCtx.bgLayer.addChild(bg);

        GameCtx.heart = new Heart();
        GameCtx.heart.x = Constants.GAME_CTR.x;
        GameCtx.heart.y = Constants.GAME_CTR.y;
        addSceneObject(GameCtx.heart, GameCtx.heartLayer);

        // spawn white cells on a timer separate from the heartbeat
        if (ClientCtx.variantSettings.boardCreatesWhiteCells) {
            var whiteCellSpawner :GameObject = new GameObject();
            whiteCellSpawner.addTask(new RepeatingTask(
                new VariableTimedTask(
                    ClientCtx.variantSettings.boardWhiteCellCreationTime.min,
                    ClientCtx.variantSettings.boardWhiteCellCreationTime.max,
                    Rand.STREAM_GAME),
                new FunctionTask(function () :void {
                    spawnCells(Constants.CELL_WHITE,
                        ClientCtx.variantSettings.boardWhiteCellCreationCount.next());
                })));
            addObject(whiteCellSpawner);
        }

        var timerView :TimerView = new TimerView();
        timerView.x = Constants.GAME_CTR.x;
        timerView.y = Constants.GAME_CTR.y;
        addSceneObject(timerView, GameCtx.effectLayer);

        GameCtx.score = new ScoreHelpQuitView();
        GameCtx.score.x = Constants.GAME_CTR.x;
        GameCtx.score.y = Constants.GAME_CTR.y;
        addSceneObject(GameCtx.score, GameCtx.uiLayer);

        var showStrainTallyView :Boolean = (!ClientCtx.isPrey && ClientCtx.preyBloodType >= 0);

        GameCtx.sentMultiplierIndicator = new SentMultiplierIndicator(
            showStrainTallyView ? BONUS_INDICATOR_STRAIN_LOC : BONUS_INDICATOR_NOSTRAIN_LOC);
        addSceneObject(GameCtx.sentMultiplierIndicator, GameCtx.effectLayer);

        if (showStrainTallyView) {
            GameCtx.specialStrainTallyView = new SpecialStrainTallyView(
                ClientCtx.preyBloodType,
                ClientCtx.playerData.getStrainCount(ClientCtx.preyBloodType));
            GameCtx.specialStrainTallyView.x = Constants.GAME_CTR.x;
            GameCtx.specialStrainTallyView.y = Constants.GAME_CTR.y;
            addSceneObject(GameCtx.specialStrainTallyView, GameCtx.effectLayer);

            // this will handle spawning the special Blood Hunt cells
            GameCtx.specialCellSpawner = new SpecialCellSpawner();
            addObject(GameCtx.specialCellSpawner);
        }

        GameCtx.cursor = GameObjects.createPlayerCursor();

        // create some non-interactive debris that floats around the heart
        for (var ii :int = 0; ii < Constants.DEBRIS_COUNT; ++ii) {
            addSceneObject(new Debris(), GameCtx.bgLayer);
        }

        ClientCtx.playerData.incrementTimesPlayed();

        // ThreadTheNeedleWatcher continuously checks whether the player has won
        // the Thread The Needle trophy
        if (!ClientCtx.hasAwardedTrophies([ Trophies.THREAD_THE_NEEDLE ])) {
            addObject(new ThreadTheNeedleWatcher());
        }

        // (Since the game now covers the room with an opaque backdrop when a feeding is
        // happening, it doesn't really make sense to allow the game to be dragged)
        // Add draggability
        //addObject(new RoomDragger(ClientCtx.gameCtrl, GameCtx.bgLayer, gameParent));

        // Center the game in the room
        ClientCtx.centerInRoom(gameParent);
        // and re-center it if the paintable area changes
        if (ClientCtx.isConnected) {
            registerListener(ClientCtx.gameCtrl.local, AVRGameControlEvent.SIZE_CHANGED,
                function (...ignored) :void {
                    ClientCtx.centerInRoom(gameParent);
                });
        }
    }

    override protected function enter () :void
    {
        super.enter();
        if (_musicChannel == null) {
            var musicName :String =
                (ClientCtx.isCorruption ? "mus_corruption_theme" : "mus_main_theme");
            _musicChannel = ClientCtx.audio.playSoundNamed(musicName, null, -1);
        }
    }

    override protected function destroy () :void
    {
        if (_musicChannel != null) {
            _musicChannel.audioControls.fadeOutAndStop(0.5);
            _musicChannel = null;
        }
    }

    protected function onMsgReceived (e :ClientMsgEvent) :void
    {
        log.info("onMsgReceived", "name", e.msg.name);

        if (e.msg is CreateMultiplierMsg) {
            onCreateMultiplier(e.msg as CreateMultiplierMsg);

        } else if (e.msg is GetRoundScores) {
            // When our blood collecting animations have completed, send our final
            // score to the server.
            GameCtx.gameOver = true;

        } else if (e.msg is RoundOverMsg) {
            onRoundOver(e.msg as RoundOverMsg);
        }
    }

    protected function onRoundOver (results :RoundOverMsg) :void
    {
        ClientCtx.lastRoundResults = results;
        if (ClientCtx.clientSettings.spOnly) {
            ClientCtx.mainLoop.changeMode(new LobbyMode(LobbyMode.LOBBY, results));
        }

        ClientCtx.clientSettings.roundCompleteCallback();
    }

    protected function onCreateMultiplier (msg :CreateMultiplierMsg) :void
    {
        if (msg.playerId != ClientCtx.localPlayerId) {
            // make sure the cell is spawning far enough way from the heart
            var loc :Vector2 = new Vector2(msg.x, msg.y);
            var requiredDist :NumRange = Constants.CELL_BIRTH_DISTANCE[Constants.CELL_MULTIPLIER];
            var dist :Number = loc.subtract(Constants.GAME_CTR).length;
            if (dist < requiredDist.min || dist > requiredDist.max) {
                loc = loc.subtract(Constants.GAME_CTR);
                loc.length = requiredDist.next();
                loc.addLocal(Constants.GAME_CTR);
            }

            // animate the bonus into the game, and call addMultiplierToBoard
            // when the anim completes
            var anim :GetMultiplierAnim = new GetMultiplierAnim(
                msg.multiplier,
                loc,
                function () :void { addMultiplierToBoard(msg.multiplier, loc, msg.playerId); });

            addSceneObject(anim, GameCtx.effectLayer);
        }
    }

    protected function addMultiplierToBoard (multiplier :int, loc :Vector2, playerId :int) :void
    {
        if (GameCtx.gameOver) {
            return;
        }

        var cell :Cell = GameObjects.createCell(Constants.CELL_MULTIPLIER, true, multiplier);
        cell.x = loc.x;
        cell.y = loc.y;

        if (!GameCtx.isSinglePlayer) {
            // show a little animation showing who gave us the multiplier
            var playerName :String = ClientCtx.getPlayerName(playerId);
            var tfName :TextField = TextBits.createText(playerName, 1.4, 0, 0xffffff,
                                                        "center", TextBits.FONT_GARAMOND);
            tfName.cacheAsBitmap = true;
            var sprite :Sprite = SpriteUtil.createSprite();
            sprite.addChild(tfName);
            var animName :SimpleSceneObject = new SimpleSceneObject(sprite);
            var animX :Number = loc.x - (animName.width * 0.5);
            var animY :Number = loc.y - animName.height;
            animName.x = animX;
            animName.y = animY;
            animName.addTask(new SerialTask(
                new TimedTask(1),
                new AlphaTask(0, 0.5)));
            animName.addTask(new SerialTask(
                new TimedTask(0.5),
                LocationTask.CreateEaseIn(animX, animY - 50, 1),
                new SelfDestructTask()));
            addSceneObject(animName, GameCtx.effectLayer);
        }
    }

    override public function update (dt :Number) :void
    {
        if (Constants.DEBUG_STANDARD_UPDATE_INTERVAL) {
            dt = 1 / 30;
        }

        GameCtx.timeLeft = Math.max(GameCtx.timeLeft - dt, 0);

        // In singleplayer, the game is considered over when our local timer ends
        if (ClientCtx.clientSettings.spOnly && GameCtx.timeLeft == 0) {
            GameCtx.gameOver = true;
        }

        super.update(dt);

        // If the game is over, wait for animations to complete before actually ending things
        if (GameCtx.gameOver && !_performedEndGameLogic && this.canEndGameNow) {

            // End the game manually if we're in standalone mode;
            // otherwise we'll wait for the actual RoundOverMsg to come in
            if (ClientCtx.clientSettings.spOnly) {
                var scores :Map = Maps.newMapOf(int);
                scores.put(ClientCtx.localPlayerId, GameCtx.score.bloodCount);
                onRoundOver(RoundOverMsg.create(scores, 1));

            } else {
                // send our scores
                ClientCtx.msgMgr.sendMessage(RoundScoreMsg.create(GameCtx.score.bloodCount));
            }

            // award trophies
            if (!GameCtx.gotCorruption) {
                ClientCtx.awardTrophy(Trophies.PUREBLOOD);
            }

            _performedEndGameLogic = true;
        }

        //Cheat check
        ClientCtx.cheatDetector.update(dt);
    }

    protected function get canEndGameNow () :Boolean
    {
        return (!BurstCascade.cascadeExists &&
                !GameCtx.score.isPlayingScoreAnim &&
                !RoomOverlay.exists);
    }

    protected function spawnCells (cellType :int, count :int) :void
    {
        count = Math.min(count, Constants.MAX_CELL_COUNT[cellType] - Cell.getCellCount(cellType));
        for (var ii :int = 0; ii < count; ++ii) {
            GameObjects.createCell(cellType, true);
        }
    }

    protected var _playerType :int;
    protected var _musicChannel :AudioChannel;
    protected var _performedEndGameLogic :Boolean;

    protected static var log :Log = Log.getLog(GameMode);

    protected static const BONUS_INDICATOR_STRAIN_LOC :Vector2 = new Vector2(267, 276);
    protected static const BONUS_INDICATOR_NOSTRAIN_LOC :Vector2 = new Vector2(267, 304);
}

}
