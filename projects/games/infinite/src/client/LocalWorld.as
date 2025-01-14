package client
{
	import arithmetic.BoardCoordinates;
	
	import com.whirled.game.NetSubControl;
	
	import flash.events.EventDispatcher;
	
	import interactions.SabotageEvent;
	
	import server.Messages.EnterLevel;
	import server.Messages.InventoryUpdate;
	import server.Messages.LevelComplete;
	import server.Messages.MoveProposal;
	import server.Messages.PathStart;
	import server.Messages.PlayerPosition;
	
	import world.ClientWorld;
	import world.InventoryEvent;
	import world.Player;
	import world.World;
	import world.WorldClient;
	import world.WorldListener;
	import world.arbitration.MoveEvent;
	import world.level.LevelEvent;
	
	public class LocalWorld extends EventDispatcher implements ClientWorld, WorldListener
	{
		public function LocalWorld(control:NetSubControl)
		{
			_world = new World(control);
			_world.addListener(this);
		}
		
		public function get worldType () :String
		{
			return "standalone";
		}
		
        public function get clientId () :int
        {
            return ID;
        }
        
        public function nameForPlayer (id:int) :String
        {
            return "you";
        }
        
        public function enter (client:WorldClient) :void
        {
        	Log.debug("player entering world");
            _client = client;
            _world.playerEnters(ID, "you");
        }
        
        public function nextLevel () :void
        {
            _world.nextLevel(ID);
        }
        
        /**
         * Inform the client that a player has entered a level.
         */ 
        public function handleLevelEntered(event:LevelEvent) :void
        {
            _client.enterLevel(new EnterLevel(event.player.level.levelNumber, event.player.level.height,                
                new PlayerPosition(event.player.id, event.level.levelNumber, event.player.position)));
        }     
        
        public function proposeMove (coords:BoardCoordinates) :void
        {
            Log.debug(this + " proposing move to "+coords);
            _world.moveProposed(ID, new MoveProposal(_client.serverTime, coords));
        }

        public function handlePathStart (event:MoveEvent) :void
        {
            Log.debug("world dispatched path start "+event.path);
        	_client.startPath(new PathStart(event.player.id, event.path));
        }        
                	
        public function moveComplete (coords:BoardCoordinates) :void
        {
        	_world.moveCompleted(ID, coords);
        }
            
        public function handleItemReceived (event:InventoryEvent) :void
        {
        	_client.receiveItem(new InventoryUpdate(event.position, event.item.attributes));
        }
                	
        public function useItem (position:int) :void
        {
        	_world.useItem(ID, position);
        }
                	
  		public function handleItemUsed (event:InventoryEvent) :void
  		{
  			_client.itemUsed(event.position);
  		}
         
        public function handleNoPath (event:MoveEvent) :void
        {
            Log.debug("world dispatched 'no path'");
        	_client.pathUnavailable();
        }
                	
        public function handleLevelComplete (event:LevelEvent) :void
        {
            _client.levelComplete(new LevelComplete(event.player.id, event.level.levelNumber));
        }
        
        public function handleSabotageTriggered (event:SabotageEvent) :void
        {
            const victim:Player = _world.findPlayer(event.victimId);
            const saboteur:Player = _world.findPlayer(event.sabotage.saboteurId);

            Log.debug(victim.name + " "+event.sabotage.sabotageType+" by "+saboteur.name);
        }
                	
        protected var _client:WorldClient;	
		protected var _world:World;
		
		// the local player is always ID 0.
		protected static const ID:int = 0;
	}
}