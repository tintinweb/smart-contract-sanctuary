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
	//
	//
	event TestEvent
	(
		uint256 d1,  // 
		uint256 d2,  // 
		uint256 d3,          // 
		uint256 d4          // 
	);
}

contract Dog is DogDevents {
	address public admin_;
	uint256 constant private timeInc_ = 1 seconds;
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
	
	modifier isValidDogId(uint256 dogId) {
        require(dogId > 0, "invalid dog id"); 
        _;
    }
	
	modifier isValidTxcode(uint256 code) {
        require(code > 0, "invalid tx code"); 
        _;
    }
	
	modifier isValidTime(uint256 endtime) {
        require(endtime > now, "invalid endtime"); 
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
	    isValidDogId(dogId)
		isValidTxcode(code)
        public
    {
		uint256 status = dog_[dogId].status;
		uint256 f = status % 10;
		uint256 endtime = status / 10;
		uint256 _now = now;
		// 
		if (f == 1 && _now < endtime && dogTxcode_[dogId] == code) {
		    dogTxcode_[dogId] = 0;
			exchange(dogId, msg.sender, 0);
		}
	}
	
	function setTxcode(uint256 dogId, uint256 code, uint256 con)
	    olnyOwner(dogId)
		isValidTxcode(code)
        public
    {
        uint256 status = dog_[dogId].status;
		uint256 f = status % 10;
		uint256 oldEndtime = status / 10;
		uint256 _now = now;
		//
		emit DogDevents.TestEvent (
				status,
				f,
				oldEndtime,
				_now
			);
		//  
		if (f != 1 || _now > oldEndtime) {
			dogTxcode_[dogId] = code;
			dog_[dogId].status = 1 + timeInc_ * con;
			
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