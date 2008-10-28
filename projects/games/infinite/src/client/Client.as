package client
{
	import arithmetic.Geometry;
	import arithmetic.GraphicRectangle;
	
	import client.player.Player;
	import client.player.PlayerEvent;
	
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.text.TextField;
	
	import inventory.InventoryDisplay;
		
	import server.Messages.LevelEntered;
	import server.Messages.PathStart;
	
	import sprites.SpriteUtil;
	
	import world.ClientWorld;
	import world.MutableBoard;
	import world.WorldClient;
	import world.board.*;
	import world.level.*;
	
	public class Client extends Sprite implements WorldClient
	{
		public function Client(world:ClientWorld)
		{
			_world = world;
			
			// set the overall size of the game
			SpriteUtil.addBackground(this, GAME_WIDTH, GAME_HEIGHT, SpriteUtil.GREY);
			this.x = 0;
			this.y = 0;			
			
			_viewer = new Viewer(680, 420);
			
			_viewer.x = 10;
			_viewer.y = 10;
			addChild(_viewer);		
			
			_inventory = new InventoryDisplay(680, 50);
			const invView:DisplayObject = _inventory.view;
			invView.x = 10;
			invView.y = 440;			
			addChild(invView);
			
			var frame:GraphicRectangle = GraphicRectangle.fromDisplayObject(this);
			
			const modeView:TextField = new TextField();
			modeView.text = mode + " mode";
			var rect:GraphicRectangle = GraphicRectangle.fromText(modeView).paddedBy(10).alignBottomRightTo(frame);		
			Geometry.position(modeView, rect.origin);
			addChild(modeView);
						
			_frameTimer = new FrameTimer();
			_frameTimer.start();
				
			enterWorld();			
		}
						
		public function enterWorld () :void
		{
			_world.enter(this);
		}
								
		public function startGame () :void 
		{
			if (Config.boardDebug) {
    			_board = new DebugBoard(LEVEL1);
            } else {
			    _board = new SimpleBoard();
            }
            
			//_player = new PlayerCharacter("robin", _inventory);
			_viewer.board = _board;
			//_viewer.player = _player;
			//_controller = new PlayerController(_frameTimer, _viewer, _player, _inventory);
			
			trace("game size at end: "+width+", "+height);
		}
		
		/**
		 * Receive a message that a player has entered a level.
		 */
		public function levelEntered(detail:LevelEntered) :void
		{
			// find the player
			var player:Player = _players.find(detail.userId);
		     
            // if we don't already know about the player, create a new one.
            if (player == null)
            {
            	player = newPlayer(detail.userId);
            }
            
            /**
             * Move the player to the appropriate level.
             */ 
            player.enterLevel(detail.level, detail.position);
		}
		
		/**
		 * Create a new player.
		 */
		protected function newPlayer(id:int) :Player
		{
			const player:Player = new Player(this, id);
            if (id == _world.clientId) {
            	_localPlayer = player;
            }
			player.addEventListener(PlayerEvent.CHANGED_LEVEL, handleChangedLevel);			
		    return player;
		}
		
		protected function handleChangedLevel(event:PlayerEvent) :void
		{
			// if it's the local player, then switch level to the player's new
			// level.
			if (event.player == _localPlayer) {
    			selectLevel (event.player.level);
    			_objective.addLocalPlayer(event.player);
            } else {
            	// otherwise, if the player has entered the level that the local
            	// player is on, then 
            	if (event.player.level == _level) {
            		_objective.addPlayer(event.player);
            	} else {
            		_objective.removePlayer(event.player);
            	}
            }
		}
		
		/**
		 * Cause the client to start displaying a new level.
		 */
		public function selectLevel (level:int) :void
		{
			trace(this+" selecting level "+level);
			
			// if the client is already displaying the requested level, return.
			if (_level == level) {
				return;
			}
			
			// we can start off with the default blank board.
			_board = new MutableBoard(new BlankBoard);
            trace(this+" created "+_board);            
			
			// and assign a new board to the view.
			_viewer.board = _board;
            _controller = new PlayerController(_world, _viewer, _localPlayer, _inventory);
            
			_level = level;
		}
		
		public function get mode () :String 
		{
			return _world.worldType;
		}
		
		public function startPath (detail:PathStart) :void
		{
            const player:Player = _players.find(detail.userId);
//            player.dispatchEvent(new MoveEvent(MoveEvent.PATH_START, 
		}
		
		protected var _localPlayer:Player;
		protected var _world:ClientWorld;
		protected var _objective:Objective;		
		protected var _players:PlayerRegister = new PlayerRegister();
		protected var _level:int = NO_LEVEL;
		
		protected var _controller:PlayerController;
		protected var _board:Board;
		protected var _viewer:Viewer;
		protected var _inventory:InventoryDisplay;
		protected var _frameTimer:FrameTimer;		
		
		protected const GAME_WIDTH:int = 700;
		protected const GAME_HEIGHT:int = 500;
		
		protected const LEVEL1:Level = new Level(1, 50, new SimpleBoard());
		
		protected static const NO_LEVEL:int = -1;
	}	
}