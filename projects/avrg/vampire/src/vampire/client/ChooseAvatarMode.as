package vampire.client
{
    import com.whirled.contrib.simplegame.AppMode;

    import flash.display.MovieClip;
    import flash.events.MouseEvent;

    import vampire.data.Codes;
    import vampire.data.VConstants;

    public class ChooseAvatarMode extends AppMode
    {
        public function ChooseAvatarMode()
        {
            super();
        }

        override protected function setup():void
        {
            modeSprite.visible = false;

            var infoPanel :MovieClip = ClientContext.instantiateMovieClip("HUD", "popup_avatar", false);
            modeSprite.addChild( infoPanel );

            registerListener( infoPanel["choose_female"], MouseEvent.CLICK, function(...ignored) :void {
                ClientContext.ctrl.agent.sendMessage( VConstants.NAMED_MESSAGE_CHOOSE_FEMALE);
                ClientContext.game.ctx.mainLoop.popMode();
            });

            registerListener( infoPanel["choose_male"], MouseEvent.CLICK, function(...ignored) :void {
                ClientContext.ctrl.agent.sendMessage( VConstants.NAMED_MESSAGE_CHOOSE_FEMALE);
                ClientContext.game.ctx.mainLoop.popMode();
            });

            registerListener( infoPanel["avatar_close"], MouseEvent.CLICK, function(...ignored) :void {
                ClientContext.ctrl.player.deactivateGame();
            });


            infoPanel.gotoAndStop(1);
            infoPanel.x = ClientContext.ctrl.local.getRoomBounds()[0]/2;
            infoPanel.y = ClientContext.ctrl.local.getRoomBounds()[1]/2;
        }
        override protected function enter():void
        {
            if( !isFirstTimePlayer() ) {
                //Push the main game mode
                ClientContext.game.ctx.mainLoop.popMode();
            }
            else {
                modeSprite.visible = true;
            }
        }

        protected function isFirstTimePlayer() :Boolean
        {
            var lastTimeAwake :Number = Number(ClientContext.ctrl.player.props.get(
                Codes.PLAYER_PROP_LAST_TIME_AWAKE ) );

            if( isNaN( lastTimeAwake ) || lastTimeAwake == 0 ) {
                return true;
            }
            return false;
        }

    }
}