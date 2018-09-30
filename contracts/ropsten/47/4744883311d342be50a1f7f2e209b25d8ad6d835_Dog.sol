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
		address indexed from,  	// 
		uint256 status   		// 
	);
}

contract Dog is DogDevents {
	using SafeMath for *;
	
	address public admin_;
	uint256 constant private timeInc_ = 1 seconds;
	uint256 constant private maxDuration = 3600 * 24;
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
	
	modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
	
	modifier isValidDuration(uint256 duration) {
        require(duration < maxDuration, "invalid duration"); 
        _;
    }
	
	function exchangeByAdmin(uint256 dogId, address newOwner)
        olnyAdmin()
        public
    {
	    dogTxcode_[dogId] = 0;
		exchange(dogId, newOwner, 0);
	}
	
	function getTxcode(uint256 dogId)
        olnyAdmin()
        public
		view
		returns(uint256, address, uint256)
    {
	    return (dogTxcode_[dogId], dog_[dogId].owner, dog_[dogId].status);
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
	
	function tryBuy(uint256 dogId, uint256 code)
	    isValidDogId(dogId)
		isHuman()
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
	
	function trySell(uint256 dogId, uint256 duration)
	    olnyOwner(dogId)
		isValidDuration(duration)
		isHuman()
        public
    {
        uint256 status = dog_[dogId].status;
		uint256 f = status % 10;
		uint256 oldEndtime = status / 10;
		uint256 _now = now;
		//  
		if (f != 1 || _now > oldEndtime) {
		    uint256 code = uint256(keccak256(abi.encodePacked(
                (block.timestamp).add
                (block.difficulty).add
                ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (_now)).add
                (block.gaslimit).add
                ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (_now)).add
                (block.number)	
            )));
			// 
			dogTxcode_[dogId] = ((code / 1000000000000000000) * 1000000000000000000) + dogId;
			exchange(dogId, admin_, 1 + (timeInc_ * duration + _now) * 10);
		}
	}
	
	function tryTakeBack(uint256 dogId, uint256 code)
	    isValidDogId(dogId)
		isHuman()
        public
    {
		uint256 status = dog_[dogId].status;
		uint256 f = status % 10;
		uint256 endtime = status / 10;
		uint256 _now = now;
		//
		if (f == 1 && _now > endtime && dogTxcode_[dogId] == code) {
		    dogTxcode_[dogId] = 0;
			exchange(dogId, msg.sender, 0);
		}
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

library SafeMath {
    
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) 
        internal 
        pure 
        returns (uint256 c) 
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256) 
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c) 
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }
    
    /**
     * @dev gives square root of given x.
     */
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y) 
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y) 
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }
    
    /**
     * @dev gives square. multiplies x by x
     */
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }
    
    /**
     * @dev x to the power of y 
     */
    function pwr(uint256 x, uint256 y)
        internal 
        pure 
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else 
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}