package popcraft {

import core.AppMode;
import core.MainLoop;
import core.ResourceManager;
import core.util.Rand;

import popcraft.net.TickedMessageManager;
import popcraft.net.Message;
import popcraft.net.CreateUnitMessage;

import com.threerings.util.Assert;
import com.threerings.flash.DisablingButton;

import flash.display.SimpleButton;
import flash.display.DisplayObjectContainer;
import flash.events.MouseEvent;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.Sprite;
import flash.text.TextField;
import flash.display.DisplayObject;
import flash.events.Event;

public class GameMode extends AppMode
{
    public static function get instance () :GameMode
    {
        var instance :GameMode = (MainLoop.instance.topMode as GameMode);

        Assert.isNotNull(instance);

        return instance;
    }

    public function GameMode ()
    {
    }

    // from core.AppMode
    override public function setup () :void
    {
        var myPosition :int = PopCraft.instance.gameControl.seating.getMyPosition();
        var isAPlayer :Boolean = (myPosition >= 0);

        // only players get puzzles
        if (isAPlayer) {
            _playerData = new PlayerData(uint(myPosition));

            var resourceDisplay :ResourceDisplay = new ResourceDisplay();
            resourceDisplay.displayObject.x = GameConstants.RESOURCE_DISPLAY_LOC.x;
            resourceDisplay.displayObject.y = GameConstants.RESOURCE_DISPLAY_LOC.y;

            this.addObject(resourceDisplay, this);

            _puzzleBoard = new PuzzleBoard(
                GameConstants.PUZZLE_COLS,
                GameConstants.PUZZLE_ROWS,
                GameConstants.PUZZLE_TILE_SIZE);

            _puzzleBoard.displayObject.x = GameConstants.PUZZLE_LOC.x;
            _puzzleBoard.displayObject.y = GameConstants.PUZZLE_LOC.y;

            this.addObject(_puzzleBoard, this);

            // create the creature purchase buttons
            var meleeButton :SimpleButton = createUnitPurchaseButton(Content.MELEE, GameConstants.UNIT_MELEE);

            meleeButton.x = GameConstants.MELEE_BUTTON_LOC.x;
            meleeButton.y = GameConstants.MELEE_BUTTON_LOC.y;
            this.addChild(meleeButton);

            meleeButton.addEventListener(MouseEvent.CLICK,
                function (e :Event) :void {
                   purchaseUnit(GameConstants.UNIT_MELEE);
                });

            _creaturePurchaseButtons[GameConstants.UNIT_MELEE] = meleeButton;

            updateUnitPurchaseButtons();
       }

        // everyone gets to see the BattleBoard
        _battleBoard = new BattleBoard(
            GameConstants.BATTLE_COLS,
            GameConstants.BATTLE_ROWS,
            GameConstants.BATTLE_TILE_SIZE);

        _battleBoard.displayObject.x = GameConstants.BATTLE_LOC.x;
        _battleBoard.displayObject.y = GameConstants.BATTLE_LOC.y;

        this.addObject(_battleBoard, this);

        _messageMgr = new TickedMessageManager(PopCraft.instance.gameControl);
        _messageMgr.addMessageFactory(CreateUnitMessage.messageName, CreateUnitMessage.createFactory());
        _messageMgr.setup((0 == _playerData.playerId), TICK_INTERVAL_MS);

        // create a special AppMode for all objects that are synchronized over the network.
        // we will manage this mode ourselves.
        _netObjects = new AppMode();
    }

    override public function update(dt :Number) :void
    {
        // don't start doing anything until the messageMgr is ready
        if (!_gameIsRunning && _messageMgr.isReady) {
            trace("Starting game. randomSeed=" + _messageMgr.randomSeed);
            Rand.seedStream(Rand.STREAM_GAME, _messageMgr.randomSeed);
            _gameIsRunning = true;
        }

        if (!_gameIsRunning) {
            return;
        }

        // update the network
        _messageMgr.update(dt);
        while (_messageMgr.hasUnprocessedTicks) {

            // process all messages from this tick
            var messageArray: Array = _messageMgr.getNextTick();
            for each (var msg :Message in messageArray) {
                handleMessage(msg);
            }

            // run the simulation the appropriate amount
            // (our network update time is unrelated to the application's update time.
            // network timeslices are always the same distance apart)
            _netObjects.update(TICK_INTERVAL_S);
        }


        // update all non-net objects
        updateUnitPurchaseButtons();
        super.update(dt);
    }

    protected function handleMessage (msg :Message) :void
    {
        switch (msg.name) {
        case CreateUnitMessage.messageName:
            var createUnitMsg :CreateUnitMessage = (msg as CreateUnitMessage);
            _netObjects.addObject(
                UnitFactory.createUnit(createUnitMsg.unitType, createUnitMsg.owningPlayer),
                _battleBoard.displayObjectContainer);
            break;
        }

    }

    protected function updateUnitPurchaseButtons () :void
    {
        for (var creatureType :uint = 0; creatureType < GameConstants.UNIT__LIMIT; ++creatureType) {
            var button :SimpleButton = _creaturePurchaseButtons[creatureType];
            button.enabled = canPurchaseUnit(creatureType);
        }
    }

    public function canPurchaseUnit (creatureType :uint) :Boolean
    {
        var creatureCosts :Array = (GameConstants.UNIT_DATA[creatureType] as UnitData).resourceCosts;
        for (var resourceType:uint = 0; resourceType < creatureCosts.length; ++resourceType) {
            if (_playerData.getResourceAmount(resourceType) < creatureCosts[resourceType]) {
                return false;
            }
        }

        return true;
    }

    public function purchaseUnit (creatureType :uint) :void
    {
        Assert.isTrue(canPurchaseUnit(creatureType));

        // deduct the cost of the unit from the player's holdings
        var creatureCosts :Array = (GameConstants.UNIT_DATA[creatureType] as UnitData).resourceCosts;
        for (var resourceType:uint = 0; resourceType < creatureCosts.length; ++resourceType) {
            _playerData.offsetResourceAmount(resourceType, -creatureCosts[resourceType]);
        }

        // send a message!
        _messageMgr.sendMessage(new CreateUnitMessage(creatureType, _playerData.playerId));
    }

    // from core.AppMode
    override public function destroy() :void
    {
        if (null != _messageMgr) {
            _messageMgr.shutdown();
            _messageMgr = null;
        }
    }

    public function get playerData () :PlayerData
    {
        return _playerData;
    }

    protected static function createUnitPurchaseButton (iconClass :Class, creatureType :uint) :DisablingButton
    {
        var data :UnitData = GameConstants.UNIT_DATA[creatureType];

        // how much does it cost?
        var costString :String = new String();
        for (var resType :uint = 0; resType < GameConstants.RESOURCE__LIMIT; ++resType) {
            var resData :ResourceType = GameConstants.getResource(resType);
            var resCost :int = data.getResourceCost(resType);

            if (resCost == 0) {
                continue;
            }

            if (costString.length > 0) {
                costString += " ";
            }

            costString += (resData.name + " (" + data.getResourceCost(resType) + ")");
        }

        var button :DisablingButton = new DisablingButton();
        var foreground :int = uint(0xFFFFFF);
        var background :int = uint(0xCDC9C9);
        var rolloverBackground :int = uint(0xFFD800);
        var disabledBackground :int = uint(0x838383);

        button.upState = makeButtonFace(iconClass, costString, foreground, background);
        button.overState = makeButtonFace(iconClass, costString, foreground, rolloverBackground);
        button.downState = makeButtonFace(iconClass, costString, foreground, rolloverBackground);
        button.downState.x = -1;
        button.downState.y = -1;
        button.disabledState = makeButtonFace(iconClass, costString, foreground, disabledBackground);
        button.hitTestState = button.upState;

        return button;
    }

    protected static function makeButtonFace (iconClass :Class, costString :String, foreground :uint, background :uint) :Sprite
    {
        var face :Sprite = new Sprite();

        var icon :DisplayObject = new iconClass();

        face.addChild(icon);

        var costText :TextField = new TextField();
        costText.text = costString;
        costText.textColor = 0;
        costText.height = costText.textHeight + 2;
        costText.width = costText.textWidth + 3;
        costText.y = icon.height + 5;

        face.addChild(costText);

        var padding :int = 5;
        var w :Number = icon.width + 2 * padding;
        var h :Number = icon.height + 2 * padding;

        // draw our button background (and outline)
        face.graphics.beginFill(background);
        face.graphics.lineStyle(1, foreground);
        face.graphics.drawRect(0, 0, w, h);
        face.graphics.endFill();

        icon.x = padding;
        icon.y = padding;

        return face;
    }

    protected var _gameIsRunning :Boolean;

    protected var _creaturePurchaseButtons :Array = new Array();

    protected var _messageMgr :TickedMessageManager;
    protected var _puzzleBoard :PuzzleBoard;
    protected var _battleBoard :BattleBoard;
    protected var _playerData :PlayerData;

    protected var _netObjects :AppMode;

    protected static const TICK_INTERVAL_MS :int = 100; // 1/10 of a second
    protected static const TICK_INTERVAL_S :Number = (Number(TICK_INTERVAL_MS) / Number(1000));
}

}
