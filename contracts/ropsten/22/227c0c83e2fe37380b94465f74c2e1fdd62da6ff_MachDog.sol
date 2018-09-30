pragma solidity ^0.4.18;

contract MachDog {
	// create dog event
	event CreateDog
    (
        uint256 indexed dogId,	// 
		uint256 indexed owner   //  
    );
	// exchange dog&#39;s owner
	event ExchangeOwner
    (
        uint256 indexed dogId,  // 
        uint256 indexed from,   // 
        uint256 indexed to      //  
    );
	
	address admin_;
	mapping (uint256 => uint256) dogMap_;

	constructor() 
	    public 
	{
		admin_ = msg.sender;
	}

    modifier olnyAdmin() {
        require(msg.sender == admin_, "only for admin"); 
        _;
    }
	
	function createDog(uint256 dogId, uint256 owner)
        olnyAdmin()
        public
    {
		dogMap_[dogId] = owner;
		// 
		emit CreateDog (
			dogId,
			owner
		);
	}
	
	function exchangeOwner(uint256 dogId, uint256 newOwner)
        olnyAdmin()
        public
    {
	    uint256 oldOwner = dogMap_[dogId];
		dogMap_[dogId] = newOwner;
		// 
		emit ExchangeOwner (
			dogId,
			oldOwner,
			newOwner
		);
	}
	
	function getOwner(uint256 dogId) 
		public 
		view 
		returns(uint256)
	{
		return dogMap_[dogId];
	}
}