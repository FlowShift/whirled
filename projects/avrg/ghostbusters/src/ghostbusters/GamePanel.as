//
// $Id$

package ghostbusters {

import flash.display.DisplayObject;
import flash.display.Graphics;
import flash.display.MovieClip;
import flash.display.Shape;
import flash.display.SimpleButton;
import flash.display.Sprite;
import flash.geom.Rectangle;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.AntiAliasType;
import flash.text.TextFormat;

import flash.events.Event;
import flash.events.MouseEvent;

import flash.utils.ByteArray;

import mx.controls.Button;
import mx.events.FlexEvent;

import com.whirled.AVRGameControl;
import com.whirled.AVRGameControlEvent;
import com.threerings.flash.SimpleTextButton;
import com.whirled.MobControl;

import com.threerings.flash.AnimationManager;
import com.threerings.flash.TextFieldUtil;

import com.threerings.util.ArrayUtil;
import com.threerings.util.CommandEvent;

import ghostbusters.fight.FightPanel;
import ghostbusters.seek.SeekPanel;

public class GamePanel extends Sprite
{
    public var hud :HUD;

    public function GamePanel ()
    {
        hud = new HUD();
        this.addChild(hud);

        _frame = new GameFrame();

        _splash.addEventListener(MouseEvent.CLICK, handleClick);

        Game.control.state.addEventListener(
            AVRGameControlEvent.ROOM_PROPERTY_CHANGED, roomPropertyChanged);

        Game.control.addEventListener(AVRGameControlEvent.COINS_AWARDED, coinsAwarded);

        _ppp = new PerPlayerProperties(handlePlayerPropertyUpdate);
    }

    public function shutdown () :void
    {
        hud.shutdown();
    }

    override public function hitTestPoint (
        x :Number, y :Number, shapeFlag :Boolean = false) :Boolean
    {
        for (var ii :int = 0; ii < this.numChildren; ii ++) {
            if (this.getChildAt(ii).hitTestPoint(x, y, shapeFlag)) {
                return true;
            }
        }
        return false;
    }

    public function get ghost () :Ghost
    {
        return _ghost;
    }

    public function get subPanel () :DisplayObject
    {
        return _panel;
    }

    public function get seeking () :Boolean
    {
        return _seeking;
    }

    public function set seeking (seeking :Boolean) :void
    {
        _seeking = seeking;
        updateState();
    }

    public function unframeContent () :void
    {
        _frame.frameContent(null);
        this.removeChild(_frame);
    }

    public function frameContent (content :DisplayObject) :void
    {
        _frame.frameContent(content);

        this.addChild(_frame);

        _frame.x = (Game.stageSize.width - 100 - _frame.width) / 2;
        _frame.y = (Game.stageSize.height - _frame.height) / 2 - FRAME_DISPLACEMENT_Y;
    }

    public function reloadView () :void
    {
        hud.reloadView();
        if (Game.model.isPlayerDead(Game.ourPlayerId)) {
            weAreDead();
        }
    }

    public function newGhost () :void
    {
        _ghost = null;
        if (Game.model.ghostId != null) {
            new Ghost(function (g :Ghost) :void {
                _ghost = g;
                updateState();
            });
        }
    }

    protected function coinsAwarded (evt :AVRGameControlEvent) :void
    {
        var panel :GamePanel = this;
        var flourish :CoinFlourish = new CoinFlourish(evt.value as int, function () :void {
            AnimationManager.stop(flourish);
            panel.removeChild(flourish);
        });

        flourish.x = (Game.stageSize.width - flourish.width) / 2;
        flourish.y = 20;
        this.addChild(flourish);

        AnimationManager.start(flourish);
    }

    protected function handlePlayerPropertyUpdate (playerId :int, name :String, value :Object) :void
    {
        if (name == Codes.PROP_PLAYER_CUR_HEALTH) {
            if (playerId == Game.ourPlayerId) {
                if (Game.model.isPlayerDead(playerId)) {
                    weAreDead();
                }
            }
        }
    }

    protected function weAreDead () :void
    {
        if (_revivePopup != null) {
            Game.log.debug("Hrm, _revivePopup != null");
        }
        // TODO: make the button enable/disable depending on phase
        var panel :GamePanel = this;
        _revivePopup = popup(
            "Alas, you are dead. When you are out of combat, you can revive.",
            "Revive me!", function (event :Event) :void {
              Game.log.debug("like yo, I'm running");
              CommandEvent.dispatch(panel, GameController.REVIVE)
              unframeContent();
              _revivePopup = null;
            });

        frameContent(_revivePopup);
    }

    protected function roomPropertyChanged (evt :AVRGameControlEvent) :void
    {
        if (evt.name == Codes.PROP_STATE) {
            _seeking = false;
            updateState();

        } else if (evt.name == Codes.PROP_GHOST_ID) {
            newGhost();
        }
    }

    protected function popup (text :String, btnText :String, callback :Function) :Sprite
    {
        var frameBounds :Rectangle = _frame.getContentBounds();

        var popup :Sprite = new Sprite();
        popup.opaqueBackground = 0x000000;

        var format :TextFormat = TextFieldUtil.createFormat({
              font: "Arial", size: 16, color: 0xFFD700
        });

        var textField :TextField = TextFieldUtil.createField(
            text, { antiAliasType: AntiAliasType.ADVANCED, autoSize: TextFieldAutoSize.NONE,
                    defaultTextFormat: format });

        popup.addChild(textField);
        textField.width = frameBounds.width - 20;
        textField.height = frameBounds.height - 20;
        textField.x = textField.y = 10;

        var button :SimpleButton = new SimpleTextButton(
            btnText, true, 0x003366, 0x6699CC, 0x0066FF, 5, format);
        button.addEventListener(MouseEvent.CLICK, callback);

        popup.addChild(button);
        button.x = frameBounds.width - button.width - 10;
        button.y = frameBounds.height - button.height - 5;

        return popup;
    }


    protected function updateState () :void
    {
        var avatarState :String = Codes.ST_PLAYER_DEFAULT;
        var fightPanel :Boolean = false;
        var seekPanel :Boolean = false;

        if (Game.model.state == GameModel.STATE_SEEKING) {
            if (_seeking) {
                avatarState = Codes.ST_PLAYER_FIGHT;
                seekPanel = true;

            } else {
                avatarState = Codes.ST_PLAYER_DEFAULT;
            }

        } else if (Game.model.state == GameModel.STATE_APPEARING) {
            seekPanel = true;

        } else if (Game.model.state == GameModel.STATE_FIGHTING) {
            fightPanel = true;
            avatarState = Codes.ST_PLAYER_FIGHT;

        } else if (Game.model.state == GameModel.STATE_GHOST_TRIUMPH ||
                   Game.model.state == GameModel.STATE_GHOST_DEFEAT) {
            fightPanel = true;
            // don't mess with the avatar's state here

        } else {
            Game.log.warning("Unknown state requested [state=" + Game.model.state + "]");
        }

        setPanel(seekPanel ? SeekPanel : (fightPanel ? FightPanel : null));

        Game.setAvatarState(avatarState);
    }

    protected function setPanel (pClass :Class) :void
    {
        if (pClass != null && _panel is pClass) {
            return;
        }
        if (_panel != null) {
            this.removeChild(_panel);
            _panel = null;
        }
        if (pClass != null) {
            _panel = new pClass(_ghost);
            this.addChildAt(_panel, 0);
        }
    }

    protected function showHelp () :void
    {
        if (_box) {
            this.removeChild(_box);
        }
        var bits :TextBits = new TextBits("HELP HELP HELP HELP");
        bits.addButton("Whatever", true, function () :void {
            showSplash();
        });
        _box = new Box(bits);
        _box.x = 100;
        _box.y = 100;
        _box.scaleX = _box.scaleY = 0.5;
        this.addChild(_box);
    }

    protected function showSplash () :void
    {
        if (_box) {
            this.removeChild(_box);
        }
        _box = new Box(_splash);
        _box.x = 100;
        _box.y = 100;
        _box.scaleX = _box.scaleY = 0.5;
        this.addChild(_box);
    }

    protected function handleClick (evt :MouseEvent) :void
    {
        if (evt.target.name == "help") {
            CommandEvent.dispatch(this, GameController.HELP);

        } else if (evt.target.name == "playNow") {
            _box.hide();
            CommandEvent.dispatch(this, GameController.PLAY);
            hud.visible = true;

        } else {
            Game.log.debug("Clicked on: " + evt.target + "/" + (evt.target as DisplayObject).name);
        }
    }

    protected var _ppp :PerPlayerProperties;

    protected var _seeking :Boolean = false;

    protected var _panel :DisplayObject;

    protected var _revivePopup :Sprite;

    protected var _ghost :Ghost;

    protected var _frame :GameFrame;

    protected var _box :Box;

    protected var _splash :MovieClip = MovieClip(new Content.SPLASH());

    protected static const FRAME_DISPLACEMENT_Y :int = 20;
}
}
