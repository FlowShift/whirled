package world
{
	import arithmetic.VoidBoardRectangle;
	
	import flash.utils.Dictionary;
	
	public class PlayerRegister
	{
		public function PlayerRegister()
		{
			
		}
		
		public function find (id:int) :Player
		{
			return _dictionary[id] as Player;
		}
		
		public function register (player:Player) :void
		{
			Log.debug(this + "registering "+player);
			_dictionary[player.id] = player;
		}		

        public function toString () :String
        {
        	return "server player register";
        }

        protected var _dictionary:Dictionary = new Dictionary();
	}
}