package world.level
{
	import arithmetic.BoardCoordinates;
	import arithmetic.BreadcrumbTrail;
	import arithmetic.CellIterator;
	import arithmetic.Vector;
	
	import client.ClientLevel;
	
	import com.whirled.game.NetSubControl;
	
	import flash.events.EventDispatcher;
	
	import server.Messages.LevelUpdate;
	import server.Messages.PlayerPosition;
	
	import world.Cell;
	import world.Chronometer;
	import world.MasterBoard;
	import world.Player;
	import world.PlayerMap;
	import world.World;
	import world.arbitration.BoardArbiter;
	import world.board.Board;
	import world.board.BoardInteractions;
	
	public class Level extends EventDispatcher implements BoardInteractions, Chronometer
	{		
		public function Level(world:World, height:int, starting:Board, control:NetSubControl) 
		{
			_world = world;
			_height = height;
            _clientLevel = new ClientLevel(control, starting.levelNumber);
            _clientLevel.height = height;
			_board = new MasterBoard(starting.levelNumber, height, starting, control);
			_arbiter = new BoardArbiter(_board);
			_mapMaker = new MapMaker(this, _explored);
		}

		public function get height () :int
		{
			return _height;
		}

        /**
         * Return the row that the player must land on to finish a level.
         */ 
        public function get exitRow () :int
        {
            return (-_height) +1;
        }
        
        public function get finish () :int
        {
            return -_height;
        }

        /**
         * A player enters this level.
         */
        public function playerEnters (player:Player) :void
        {
        	// blow up if the player has already entered.
            if (_players.find(player.id) != null) {
            	throw new Error(player + " is already in "+this);
            }
            
            if (! _players.occupying(_board.startingPosition)) {
            	// if the starting position for the board is unoccupied, put the player there.
            	player.cell = _board.cellAt(_board.startingPosition);
            } else {            
            	// otherwise iterate from there until we find a suitable cell
	        	var iterator:CellIterator =
	        	   _board.cellAt(_board.startingPosition).iterator(_board, Vector.LEFT);
	        	   
	        	var cell:Cell;
	            do {
	            	cell = iterator.next();
	            	trace ("considering "+cell+" as starting point for "+player);
	            } 
	            while (!cell.canBeStartingPosition || _players.occupying(cell.position))
	            
	            player.cell = cell;
            }
            
            // now that we've established the starting position, track the player.
             map(player.cell.position);
            _players.trackPlayer(player);        	   
        }
                
        public function proposeMove (player:Player, coords:BoardCoordinates) :void
        {
        	_arbiter.proposeMove(player, _board.cellAt(coords));
        }
                
        public override function toString () :String
        {
        	return "level "+levelNumber;
        }
        
        /**
         * Return a list of the players on this level.
         */
        public function get players () :Array
        {
        	return _players.list;
        }
        
        public function makeUpdate () :LevelUpdate
        {
        	const update:LevelUpdate = new LevelUpdate();
        	for each (var player:Player in players) {
        		update.add(new PlayerPosition(player.id, levelNumber, player.position));
        	} 
        	return update;
        }
                
        /**
         * Make sure that we have a map for the given coordinates.
         */ 
        public function map (coords:BoardCoordinates) :void
        {
        	_explored.map(coords);
        }
        
        /**
         * Compute the consequences of a player arriving at a particular position in a level.
		 */
		public function arriveAt (player:Player, coords:BoardCoordinates) :void
		{
			player.cell = _board.cellAt(coords);
			Log.debug(this + " setting player position to "+coords+" which is "+player.cell);
			player.cell.playerHasArrived(this, player);
		}
		
		public function distributeState (cell:Cell) :void
		{
			_world.distributeState(this, cell);
		}
         
        public function cellAt (coords:BoardCoordinates) :Cell
        {
        	return _board.cellAt(coords);
        }
        
        public function get startingPosition () :BoardCoordinates
        {
        	return _board.startingPosition;
        }
        
        public function replace (newCell:Cell)  :void
        {
        	newCell.addToLevel(this);
        	_board.replace(newCell);
        }
          
        public function get serverTime () :Number
        {
        	return (new Date()).getTime();
        }
        
        public function get levelNumber () :int
        {
        	return _board.levelNumber;
        }
          
        protected var _world:World;
        protected var _explored:BreadcrumbTrail = new BreadcrumbTrail();
        protected var _mapMaker:MapMaker;
        protected var _arbiter:BoardArbiter;
		protected var _height:int;
		protected var _players:PlayerMap = new PlayerMap();
		protected var _board:MasterBoard;
		protected var _clientLevel:ClientLevel;
		
		public static const MIN_HEIGHT:int = 8;
	}
}
