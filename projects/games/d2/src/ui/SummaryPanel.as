package ui {

import flash.events.MouseEvent;

import mx.containers.HBox;
import mx.containers.TitleWindow;
import mx.controls.Button;
import mx.controls.Text;

import game.Board;
import game.Controller;


public class SummaryPanel extends TitleWindow
{
    public function SummaryPanel (
        main :Main, controller :Controller, playFn :Function, quitFn :Function)
    {
        _main = main;
        _controller = controller;
        _playFn = playFn;
        _quitFn = quitFn;

        this.showCloseButton = false;
        this.x = 220;
        this.y = 180;
    }

    public function addFlowScore (amount :Number) :void
    {
        var text :String = _title.htmlText;
        text += "<br>" + Messages.get("you_won") + amount + " " + Messages.get("flow");
        _title.htmlText = text;
    }
    
    override protected function createChildren () :void
    {
        super.createChildren();

        var count :uint = _main.playerCount;
        var names :Array = _main.playerNames;
        var scores :Array = _controller.getScores();
        
        _title = new Text();
        _title.styleName = "summaryPanelText";
        addChild(_title);

        if (_main.isSinglePlayer) {
            var text :String =
                Messages.get("your_score") + scores[_main.myIndex] + Messages.get("points");
        } else {
            text = Messages.get("your_scores") + "<br>";
            for (var ii :int = 0; ii < count; ii++) {
                text += names[ii] + ": " + scores[ii] + Messages.get("pts") + "<br>";
            }
        }
        _title.htmlText = text;
        
        var buttons :HBox = new HBox();
        addChild(buttons);
        
        var replay :Button = new Button();
        replay.width = 120;
        replay.label = Messages.get("play_again");
        replay.addEventListener(MouseEvent.CLICK,
                                function (event :MouseEvent) :void { _playFn(); });
        buttons.addChild(replay);

        var quit :Button = new Button();
        quit.width = 120;
        quit.label = Messages.get("quit");
        quit.addEventListener(MouseEvent.CLICK,
                              function (event :MouseEvent) :void { _quitFn(); });
        buttons.addChild(quit);
    }

    protected var _main :Main;
    protected var _controller :Controller;
    protected var _playFn :Function;
    protected var _quitFn :Function;
    protected var _title :Text;
}
}
    
