pragma solidity ^0.4.18;

contract DogDevents {
	// 
	event Exchange
    (
        uint256 indexed dogId,  // 
        address indexed from,   // 
        address indexed to      //  
    );
	//
	event SetTxcode
	(
		uint256 indexed dogId,  // 
		address indexed owner,  // 
		uint256 status          // 
	);
}

contract Dog is DogDevents {
	address public admin_;
	mapping (uint256 => DogDdatasets.DogInfo) public dog_;
	mapping (uint256 => uint256) dogTxcode_; 

	constructor() 
	    public 
	{
		admin_ = msg.sender;
	}

    modifier olnyAdmin() {
        require(msg.sender == admin_, "only for admin"); 
        _;
    }
	
	modifier olnyOwner(uint256 dogId) {
        require(msg.sender == dog_[dogId].owner, "only for owner"); 
        _;
    }
	
	function exchangeByAdmin(uint256 dogId, address newOwner)
        olnyAdmin()
        public
    {
	    dogTxcode_[dogId] = 0;
		exchange(dogId, newOwner, 0);
	}
	
	function exchangeByBuyer(uint256 dogId, uint256 code)
        public
    {
		uint256 status = dog_[dogId].status;
		uint256 f = status % 10;
		uint256 oldEndtime = status / 10;
		// 
		if (f == 1 && now < oldEndtime && dogTxcode_[dogId] == code) {
		    dogTxcode_[dogId] = 0;
			exchange(dogId, msg.sender, 0);
		}
	}
	
	function setTxcode(uint256 dogId, uint256 code, uint256 endtime)
	    olnyOwner(dogId)
        public
    {
        uint256 status = dog_[dogId].status;
		uint256 f = status % 10;
		uint256 oldEndtime = status / 10;
		//  
		if (f != 1 || now > oldEndtime) {
			dogTxcode_[dogId] = code;
			dog_[dogId].status = 1 + endtime * 10;
			
			emit DogDevents.SetTxcode (
				dogId,
				msg.sender,
				dog_[dogId].status
			);
		}
	}
	
	function getDogInfo(uint256 dogId)
        public
		view
		returns (address, uint256)
    {
		return (
			dog_[dogId].owner,
			dog_[dogId].status
		);
	}
	
	function exchange(uint256 dogId, address newOwner, uint256 status)
        private
    {
		address oldOwner = dog_[dogId].owner;
		dog_[dogId].owner = newOwner;
		dog_[dogId].status = status;
		// 
		emit DogDevents.Exchange (
			dogId,
			oldOwner,
			newOwner
		);
	}
}

library DogDdatasets {
	struct DogInfo {
        address owner;      // 
        uint256 status;     //
    }
}