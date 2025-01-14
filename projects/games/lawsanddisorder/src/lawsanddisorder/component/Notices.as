﻿package lawsanddisorder.component {

import com.whirled.contrib.card.graphics.Text;

import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.geom.Point;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;

import lawsanddisorder.*;

/**
 * Displays in-game messages to the player
 */
public class Notices extends Component
{
    /** Message sent when broadcasting in-game to all players in the chat */
    public static const BROADCAST :String = "broadcast";
    
    /** Message sent when sending in-game to all players that will appear in their notice area */
    public static const BROADCAST_NOTICE :String = "broadcastNotice";

    /**
     * Constructor
     */
    public function Notices (ctx :Context)
    {
        //notices = new Array();
        super(ctx);
        ctx.eventHandler.addMessageListener(BROADCAST, gotBroadcast);
        ctx.eventHandler.addMessageListener(BROADCAST_NOTICE, gotBroadcast);
        addEventListener(MouseEvent.CLICK, viewHistoryButtonClicked);
    }

    /**
     * Draw the job area
     */
    override protected function initDisplay () :void
    {
        var background :Sprite = new NOTICES_BACKGROUND();
        addChild(background);

        // main notice area
        currentNotice = Content.defaultTextField();
        currentNotice.height = 35;
        currentNotice.width = 300;
        currentNotice.x = 40;
        currentNotice.y = 10;
        addChild(currentNotice);
        
        // history area and text
        history = new Sprite();
        history.graphics.beginFill(0xB9B9B9);
        history.graphics.drawRect(0, 0, 355, 380);
        history.x = 15;
        history.y = -380;
        historyText = Content.defaultTextField(1.0, "left");
        historyText.multiline = true;
        historyText.width = 320;
        historyText.x = 20;
        
        history.addChild(historyText);
        addEventListener(MouseEvent.ROLL_OUT, historyRollOut);
        history.addEventListener(MouseEvent.ROLL_OUT, historyRollOut);
    }

    /**
     * Update the job name
     */
    override protected function updateDisplay () :void
    {
        historyText.height = historyText.textHeight + 10;
        historyText.y = 375 - historyText.height;
    }

    /**
     * When a new game notice comes in, add it to the list of notices and display it.
     */
    public function addNotice (notice :String, lessImportant :Boolean = false) :void
    {
        // if blank, just clear the current notice but do not log to history
        if (notice == null || notice.length == 0) {
            if (_ctx.board.players.isMyTurn()) {
                currentNotice.htmlText = "It's your turn."
            } else {
                currentNotice.htmlText = "It's " + _ctx.board.players.turnHolder.name + "'s turn."
            }
            return;
        }

        notice = notice.replace("\n", "");
        // less important notices like opponent activities are displayed in grey
        if (lessImportant) {
            notice = "<font color='#333333'>" + notice + "</font>";
        }
        currentNotice.htmlText = notice;
        historyText.htmlText += notice + "\n";

        updateDisplay();
    }

    /**
     * When a message broadcast to all players is received
     */
    protected function gotBroadcast (event :MessageEvent) :void
    {
        if (event.name == Notices.BROADCAST_NOTICE) {
            _ctx.notice(event.value as String);
        } else {
            _ctx.log(event.value as String);
        }
    }

    /**
     * History button was clicked; toggle history display
     */
    protected function viewHistoryButtonClicked (event :MouseEvent) :void
    {
        if (contains(history)) {
            showHistory = false;
        }
        else {
            showHistory = true;
        }
    }

    /**
     * Triggered by the mouse exiting the notices history area.  Hide the notices history area.
     */
    protected function historyRollOut (event :MouseEvent) :void
    {
        if (contains(history)) {
            showHistory = false;
        }
    }

    /**
     * Display or hide the history area.  If displaying, update the history text first.
     */
    protected function set showHistory (value :Boolean) :void
    {
        if (value && !contains(history)) {
            addChildAt(history, 0);
            updateDisplay();
        }
        else if (!value && contains(history)) {
            removeChild(history);
        }
    }

    /** Displays text of the most recent notice. */
    protected var currentNotice :TextField;

    /** Full display of notices history. */
    protected var history :Sprite;

    /** Full display of notices history text. */
    protected var historyText :TextField;

    /** Press this button to view the history */
    protected var viewHistoryButton :TextField;

    /** Background image for the notices */
    [Embed(source="../../../rsrc/components.swf#notices")]
    protected static const NOTICES_BACKGROUND :Class;
}
}