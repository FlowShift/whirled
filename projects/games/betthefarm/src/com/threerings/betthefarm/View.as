//
// $Id$
//
// TODO:
//  - Display a CORRECT / INCORRECT heading on the barn door for either kind of
//    question. When the right answer comes in, display it along with who got it
//    right, and possibly the 'info' field.
//  - Implement the 'category choice' widget.
//  - Implement the entire wager round!

package com.threerings.betthefarm {

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.DisplayObject;
import flash.display.DisplayObjectContainer;
import flash.display.Loader;
import flash.display.LoaderInfo;
import flash.display.SimpleButton;
import flash.display.Shape;
import flash.display.Sprite;

import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;

import flash.filters.GlowFilter;

import flash.geom.Point;
import flash.geom.Matrix;
import flash.geom.Rectangle;

import flash.media.Sound;

import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.AntiAliasType;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;

import flash.ui.Keyboard;

import flash.utils.Dictionary;
import flash.utils.getTimer;
import flash.utils.setInterval;
import flash.utils.clearInterval;
import flash.utils.setTimeout;

import com.whirled.WhirledGameControl;

/**
 * Manages the whole game view and user input.
 */
public class View extends Sprite
{
    public function debug (str :String) :void
    {
        if (BetTheFarm.DEBUG) {
            trace(str);
            _control.localChat(str);
        }
    }

    public function View (control :WhirledGameControl, model :Model)
    {
        _control = control;
        _model = model;
        _model.setView(this);

        var background :DisplayObject = new Content.BACKGROUND();
        addChild(background);

        if (_control.isConnected()) {
            _playing = _control.seating.getMyPosition() != -1;

            doorSetup();
            roundSetup();
//        addDebugFrames();

            _endTime = 0;

            debug("View created [playing=" + _playing + "]");
        }
    }

    public function gameDidStart () :void
    {
        var players :Array = _control.seating.getPlayerIds();
        debug("Players: " + players);
        _plaqueTexts = new Dictionary();
        _headshots = new Dictionary();
        for (var ii :int = 0; ii < players.length; ii ++) {
            addPlaque(players[ii], ii);
            requestHeadshot(players[ii], ii);
        }
        _updateTimer = setInterval(updateTimer, 100);
        debug("Game started.");
    }

    public function gameDidEnd () :void
    {
        debug("Game ended!");
    }

    public function roundDidStart () :void
    {
        debug("Beginning round: " + _control.getRound());
        _roundText.text = Content.ROUND_NAMES[_control.getRound()-1];
        if (_model.getCurrentRoundType() == Model.ROUND_LIGHTNING) {
            _endTime = getTimer()/1000 + Content.ROUND_DURATIONS[_control.getRound()-1];
        }
        _sndRound.play();
    }

    public function roundDidEnd () :void
    {
        _endTime = 0;
        doorClear();
        doorHeader("Round Over!");

        _question = null;
    }

    public function shutdown () :void
    {
        clearInterval(_updateTimer);
    }

    public function newQuestion (question :Question) :void
    {
        _question = question;

        for each (var shot :Sprite in _headshots) {
            shot.filters = [
                new GlowFilter(0xFFFFFF, 1, 10, 10)
                ];
        }
        _answered = false;

        doorClear();

        addTextField(question.question, _doorArea, 0, 0, Content.QUESTION_RECT.width,
                     Content.QUESTION_RECT.height, true, 14);

        if (_question is MultipleChoice) {
            var answers :Array = (_question as MultipleChoice).incorrect.slice();
            var ix : int = int((1 + answers.length) * Math.random());
            answers.splice(ix, 0, (_question as MultipleChoice).correct);
            if (answers.length > 4) {
                throw new Error("Too many answers: " + _question.question);
            }
            for (var ii :int = 0; ii < 4; ii ++) {
                var button :SimpleButton = addTextButton(
                    answers[ii], _doorArea, Content.ANSWER_RECTS[ii].left,
                    Content.ANSWER_RECTS[ii].top, Content.ANSWER_RECTS[ii].width,
                    Content.ANSWER_RECTS[ii].height);
                addMultiAnswerClickHandler(button, ii == ix);
                button.enabled = _playing;
            }

        } else {
            if (_playing) {
                var buzzButton :SimpleButton = addTextButton(
                    "Buzz!", _doorArea, Content.BUZZBUTTON_RECT.x, Content.BUZZBUTTON_RECT.y);
                buzzButton.addEventListener(MouseEvent.CLICK, buzzClick);

                _freeArea = new Sprite();
                _freeArea.x = Content.FREE_RESPONSE_RECT.left;
                _freeArea.y = Content.FREE_RESPONSE_RECT.top;
                _freeArea.graphics.drawRect(
                    0, 0, Content.FREE_RESPONSE_RECT.width, Content.FREE_RESPONSE_RECT.height);
                _freeArea.width = Content.FREE_RESPONSE_RECT.width;
                _freeArea.height = Content.FREE_RESPONSE_RECT.height;
                _freeArea.visible = false;

                var field :TextField = addTextField(
		     "Enter your answer here:", _freeArea, 10, 0,
		     Content.FREE_RESPONSE_RECT.width - 20, 40);

                _freeField = addTextField(
		     "", _freeArea, 10, 50, Content.FREE_RESPONSE_RECT.width - 20, 40);
                _freeField.border = true;
                _freeField.borderColor = 0x000000;
                _freeField.type = TextFieldType.INPUT;
                _freeField.addEventListener(KeyboardEvent.KEY_DOWN, freeInput);

                _doorArea.addChild(_freeArea);
            }

        }
    }

    public function questionDone (winner :int) :void
    {
        doorClear();

        if (winner == _control.getMyId()) {
            doorHeader("Correct!");
            _sndWin.play();
            if (_model.getCurrentRoundType() == Model.ROUND_BUZZ) {
                setTimeout(chooseCategory, 1000);
            }

        } else if (_answered) {
            doorHeader("Incorrect!");
            _sndLose.play();

        } else {
            // show anything if we didn't answer?
        }

        if (winner) {
            doorBody("The correct answer was given by " +
                     _control.getOccupantName(winner) + ":\n\n" +
                     "\"" + _question.getCorrectAnswer() + "\"");
        } else {
            doorBody("The correct answer was:\n\n" +
                     "\"" + _question.getCorrectAnswer() + "\"");
        }
    }

    public function questionAnswered (player :int, correct :Boolean) :void
    {
        _headshots[player].filters = [
            new GlowFilter(correct ? 0x00FF00 : 0xFF0000, 1, 10, 10)
        ];
    }

    public function gainedBuzzControl (player :int) :void
    {
        _headshots[player].filters = [
            new GlowFilter(0xFF00FF, 1, 10, 10)
        ];
        if (player == _control.getMyId()) {
            // our buzz won!
            _freeArea.visible = true;
            stage.focus = _freeField;
        }
    }

    protected function addPlaque (oid :int, ii :int) :void
    {
        var format :TextFormat = new TextFormat();
        format.size = 64;
        format.font = Content.FONT_NAME;
        format.color = Content.FONT_COLOR;
        format.align = TextFormatAlign.CENTER;

        _plaqueTexts[oid] = new TextField();
        _plaqueTexts[oid].autoSize = TextFieldAutoSize.CENTER;
        _plaqueTexts[oid].defaultTextFormat = format;
        _plaqueTexts[oid].text = _control.getOccupantName(oid);
        _plaqueTexts[oid].x = (320 - _plaqueTexts[oid].width) / 2;

        var plaque :Sprite = new Sprite();
        plaque.width = 320;
        plaque.height = 200;
        plaque.addChild(_plaqueTexts[oid]);

        var pixels :BitmapData = new BitmapData(320, 200, true, 0x000000);
        pixels.draw(plaque, null, null, null, null, true);

        var matrix :Matrix = new Matrix();
        var scale :Number = 0.21;
        matrix.tx = (Content.PLAQUE_LOCS[ii] as Point).x - 160*scale;
        matrix.ty = (Content.PLAQUE_LOCS[ii] as Point).y - 100*scale;
        matrix.a = matrix.d = scale;
        matrix.b = 0.035;

        var bitmap :Bitmap = new Bitmap(pixels);
        bitmap.transform.matrix = matrix;
        addChild(bitmap);
    }

    protected function requestHeadshot (oid :int, ii :int) :void
    {
        var callback :Function = function (headshot :DisplayObject, success :Boolean) :void {
            var scale :Number = Math.min(90/headshot.width, 90/headshot.height);
            headshot.scaleX = headshot.scaleY = scale;
            headshot.x = (Content.HEADSHOT_LOCS[ii] as Point).x - headshot.width/2;
            headshot.y = (Content.HEADSHOT_LOCS[ii] as Point).y - headshot.height/2;
            addChild(headshot);
            debug("Setting headshot for OID " + oid);
            _headshots[oid] = headshot;
            headshot.filters = [
                new GlowFilter(0xFFFFFF, 1, 10, 10)
            ]
        };
        _control.getHeadShot(oid, callback);
    }

    protected function roundSetup () :void
    {
        _roundText = addTextField(
	      "", this, Content.ROUND_RECT.left, Content.ROUND_RECT.top,
	      Content.ROUND_RECT.width, Content.ROUND_RECT.height, false, 20);
    }

    protected function doorSetup () :void
    {
        _doorArea = new Sprite();
        _doorArea.x = Content.QUESTION_RECT.left;
        _doorArea.y = Content.QUESTION_RECT.top;
        addChild(_doorArea);
    }

    protected function doorClear () :void
    {
        while (_doorArea.numChildren > 0) {
            _doorArea.removeChildAt(0);
        }
    }

    protected function doorHeader (header :String) :void
    {
        addTextField(header, _doorArea, 0, 0, Content.ANSWER_RECT.width,
                     Content.ANSWER_RECT.height, true, 24);
    }

    protected function doorBody (body :String) :void
    {
        addTextField(body, _doorArea, 0, 60, Content.ANSWER_RECT.width,
                     Content.ANSWER_RECT.height, true, 16);
    }

    protected function chooseCategory () :void
    {
        var categories :Array = _model.getQuestions().getCategories();

        doorClear();

        var y :uint = 20;
        var x :uint = Content.QUESTION_RECT.width/2;
        for (var ii :int = 0; ii < categories.length; ii ++) {
            var button :SimpleButton = addTextButton(categories[ii], _doorArea, x, y);
            addCategoryClickHandler(button, categories[ii]);
            button.x -= button.width/2;
            y += button.height + 5;
        }
    }

    protected function addDebugFrames () :void
    {
        addFrame(Content.QUESTION_RECT);
        addFrame(Content.ROUND_RECT);
        for (var ii :int = 0; ii < 4; ii ++) {
//            addFrame(Content.ANSWER_RECTS[ii], _questionArea);
        }
    }

    protected function addFrame (rect :Rectangle, to :DisplayObjectContainer = null) :void
    {
        var bit :Sprite = new Sprite();
        bit.graphics.lineStyle(2, 0xFF0000);
        bit.graphics.drawRect(rect.x, rect.y, rect.width, rect.height);
        (to != null ? to : this).addChild(bit);
    }

    protected function addCategoryClickHandler (button :SimpleButton, category :String) :void
    {
        button.addEventListener(MouseEvent.CLICK, function (event :MouseEvent) :void {
            _control.sendMessage(Model.MSG_CHOOSE_CATEGORY, category);
        });
    }

    protected function addMultiAnswerClickHandler (button :SimpleButton, correct :Boolean) :void
    {
        button.addEventListener(MouseEvent.CLICK, function (event :MouseEvent) :void {
            if (_answered) {
                return;
            }
            _answered = true;
            _control.sendMessage(
                Model.MSG_ANSWER_MULTI, { player: _control.getMyId(), correct: correct });
        });
    }

    protected function buzzClick (event :MouseEvent) :void
    {
        _control.sendMessage(Model.MSG_BUZZ, { player: _control.getMyId() });
    }

    protected function freeInput (event :KeyboardEvent) :void
    {
        if (_answered || event.keyCode != Keyboard.ENTER || _question == null) {
            return;
        }
        _answered = true;

        var answer :String = _freeField.text.toLowerCase();
        _freeArea.visible = false;

        var answers :Array = (_question as FreeResponse).correct;
        var correct :Boolean = false;
        for (var ii :int = 0; ii < answers.length; ii ++) {
            debug("Comparing '" + answer + "' to '" + answers[ii].toLowerCase() + "'");
            if (answers[ii].toLowerCase() == answer) {
                _control.sendMessage(
                    Model.MSG_ANSWER_FREE, { player: _control.getMyId(), correct: true });
                return;
            }
        }
        _control.sendMessage(
            Model.MSG_ANSWER_FREE, { player: _control.getMyId(), correct: false });
    }

    protected function updateTimer () :void
    {
        if (_endTime == 0) {
            return;
        }
        _roundText.text = Content.ROUND_NAMES[_control.getRound()-1] + 
            " (" + Math.max(0, _endTime - uint(getTimer()/1000)) + ")";
    }

    protected function addTextField(
        txt :String, parent :DisplayObjectContainer, x :Number, y :Number, width :Number = 0,
        height :Number = 0, wordWrap :Boolean = true, fontSize :int = 16) :TextField
    {
        var field :TextField = new TextField();
        field.x = x;
        field.y = y;
        if (width > 0 && height > 0) {
            field.width = width;
            field.height = height;
            field.autoSize = TextFieldAutoSize.NONE;
        } else {
            field.autoSize = TextFieldAutoSize.CENTER;
        }
        field.wordWrap = wordWrap;

        var format :TextFormat = new TextFormat();
        format.size = fontSize;
        format.font = Content.FONT_NAME;
        format.color = Content.FONT_COLOR;
        field.defaultTextFormat = format;

        field.text = txt;
        if (parent != null) {
            parent.addChild(field);
        }
        return field;
    }

    protected function addTextButton(
        txt :String, parent :DisplayObjectContainer, x :Number, y :Number, width :Number = 0,
        height :Number = 0, wordWrap :Boolean = true, fontSize :int = 16,
        foreground :uint = 0x003366, background :uint = 0x6699CC,
        highlight :uint = 0x0066Ff, padding :Number = 5) :SimpleButton
    {
        var button :SimpleButton = new SimpleButton();
        button.upState = makeButtonFace(
            makeButtonLabel(txt, width, height, wordWrap, fontSize, foreground),
            foreground, background, padding);
        button.overState = makeButtonFace(
            makeButtonLabel(txt, width, height, wordWrap, fontSize, highlight),
            highlight, background, padding);
        button.downState = makeButtonFace(
            makeButtonLabel(txt, width, height, wordWrap, fontSize, background),
            background, highlight, padding);
        button.hitTestState = button.upState;
        parent.addChild(button);
        button.x = x;
        button.y = y;

        return button;
    }

    protected function makeButtonLabel (
        txt :String, width :Number, height :Number, wordWrap :Boolean, fontSize :int,
        foreground :uint) :TextField
    {
        var field :TextField = new TextField();
        field.x = x;
        field.y = y;
        if (width > 0 && height > 0) {
            field.width = width;
            field.height = height;
            field.autoSize = TextFieldAutoSize.NONE;
        } else {
            field.autoSize = TextFieldAutoSize.CENTER;
        }
        field.wordWrap = wordWrap;

        var format :TextFormat = new TextFormat();
        format.size = fontSize;
        format.color = foreground;
        field.defaultTextFormat = format;

        field.text = txt;
        return field;
    }

    protected function makeButtonFace (
        label :TextField, foreground :uint, background :uint, padding :int) :Sprite
    {
        var face :Sprite = new Sprite();

        var w :Number = label.textWidth + 2 * padding;
        var h :Number = label.textHeight + 2 * padding;

        // create our button background (and outline)
        var button :Shape = new Shape();
        button.graphics.beginFill(background);
        button.graphics.drawRoundRect(0, 0, w, h, padding, padding);
        button.graphics.endFill();
        button.graphics.lineStyle(1, foreground);
        button.graphics.drawRoundRect(0, 0, w, h, padding, padding);

        face.addChild(button);

        label.x = padding;
        label.y = padding;
        face.addChild(label);

        return face;
    }

    protected var _control :WhirledGameControl;
    protected var _model :Model;

    protected var _playing :Boolean;
    protected var _updateTimer :uint;

    protected var _answered :Boolean;

    protected var _endTime :uint;

    protected var _question :Question;

    protected var _headshots :Dictionary;
    protected var _plaqueTexts :Dictionary;

    protected var _doorArea :Sprite;

    protected var _freeArea :Sprite;
    protected var _freeField :TextField;

    protected var _roundText :TextField;

    protected var _sndRound :Sound = (new Content.SND_ROUND() as Sound);
    protected var _sndWin :Sound = (new Content.SND_WIN() as Sound);
    protected var _sndLose :Sound = (new Content.SND_LOSE() as Sound);
}
}
