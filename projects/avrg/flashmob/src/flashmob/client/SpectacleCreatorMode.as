package flashmob.client {

import com.whirled.avrg.*;
import com.whirled.net.MessageReceivedEvent;

import flash.display.Graphics;
import flash.display.SimpleButton;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.text.TextField;
import flash.text.TextFormatAlign;

import flashmob.*;
import flashmob.client.view.*;
import flashmob.data.*;

public class SpectacleCreatorMode extends GameDataMode
{
    override protected function setup () :void
    {
        _tf = new TextField();
        _modeSprite.addChild(_tf);

        if (ClientContext.isPartyLeader) {
            _startButton = UIBits.createButton("Start!", 1.2);
            _snapshotButton = UIBits.createButton("Snapshot!", 1.2);
            _doneButton = UIBits.createButton("Done!", 1.2);

            registerListener(_startButton, MouseEvent.CLICK, onSnapshotClicked);
            registerListener(_snapshotButton, MouseEvent.CLICK, onSnapshotClicked);
            registerListener(_doneButton, MouseEvent.CLICK, onDoneClicked);

            _modeSprite.addChild(_snapshotButton);
            _modeSprite.addChild(_doneButton);
        }

        setText("Everybody! Arrange yourselves.");
        updateButtons();
    }

    override public function update (dt :Number) :void
    {
        updateButtons();
    }

    protected function get canSnapshot () :Boolean
    {
        if (ClientContext.waitingForPlayers) {
            return false;
        } else if (_spectacle.numPatterns >= Constants.MAX_SPECTACLE_PATTERNS) {
            return false;
        } else if (_spectacle.numPatterns > 0 &&
                   ClientContext.timeNow - _lastSnapshotTime < Constants.MIN_SNAPSHOT_TIME) {
            return false;
        }

        return true;
    }

    protected function get canFinish () :Boolean
    {
        return (!_done && _spectacle.numPatterns >= Constants.MIN_SPECTACLE_PATTERNS);
    }

    protected function onSnapshotClicked (...ignored) :void
    {
        if (!this.canSnapshot) {
            return;
        }

        var now :Number = ClientContext.timeNow;
        var dt :Number = now - _lastSnapshotTime;

        // capture the locations of all the players
        var pattern :Pattern = new Pattern();
        pattern.timeLimit = (_spectacle.numPatterns == 0 ? 0 : Math.ceil(dt));
        for each (var playerId :int in ClientContext.playerIds) {
            var roomLoc :Point = ClientContext.getPlayerRoomLoc(playerId);
            pattern.locs.push(new PatternLoc(roomLoc.x, roomLoc.y));
        }

        _spectacle.patterns.push(pattern);
        _lastSnapshotTime = now;

        updateButtons();
    }

    protected function onDoneClicked (...ignored) :void
    {
        if (!this.canFinish) {
            return;
        }

        _spectacle.name = "A Spectacle!";
        ClientContext.sendAgentMsg(Constants.MSG_DONECREATING, _spectacle.toBytes());
        _done = true;
        updateButtons();
    }

    protected function updateButtons () :void
    {
        _doneButton.visible = this.canFinish;
        _snapshotButton.visible = this.canSnapshot;
    }

    protected function setText (text :String) :void
    {
        UIBits.initTextField(_tf, text, 1.2, WIDTH - 10, 0xFFFFFF, TextFormatAlign.LEFT);

        var g :Graphics = _modeSprite.graphics;
        g.clear();
        g.beginFill(0);
        g.drawRect(0, 0, WIDTH, Math.max(_tf.height + _snapshotButton.height + 10, MIN_HEIGHT));
        g.endFill();

        _tf.x = (_modeSprite.width - _tf.width) * 0.5;
        _tf.y = (_modeSprite.height - _tf.height) * 0.5;

        if (_snapshotButton != null && _doneButton != null) {
            _snapshotButton.x = _modeSprite.width - _snapshotButton.width - 10;
            _snapshotButton.y = _modeSprite.height - _snapshotButton.height - 10;
            _doneButton.x = _snapshotButton.x - _doneButton.width - 5;
            _doneButton.y = _modeSprite.height - _doneButton.height - 10;
        }
    }

    protected var _startButton :SimpleButton;
    protected var _snapshotButton :SimpleButton;
    protected var _doneButton :SimpleButton;
    protected var _tf :TextField;

    protected var _spectacle :Spectacle = new Spectacle();
    protected var _lastSnapshotTime :Number = 0;

    protected var _done :Boolean;

    protected static const WIDTH :Number = 400;
    protected static const MIN_HEIGHT :Number = 200;
}

}
