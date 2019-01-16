pragma solidity ^0.4.18;

contract TakeSeatEvents {
	// 
	event BuyTicket (
        address indexed plyr
    );
	//
	event Withdraw (
        address indexed plyr,
		uint256 indexed value,
		uint256 indexed num
    );
	//
	event SharedAward (
        address indexed plyr,
		uint256 indexed value,
		uint256 indexed num
    );
	//
	event BigAward (
        address indexed plyr,
		uint256 indexed value,
		uint256 indexed num
    );
}

contract TakeSeat is TakeSeatEvents {
	uint256 constant private BuyValue = 1000000000000000000;
	address private admin_;

	constructor() public {
		admin_ = msg.sender;
	}
	
	modifier olnyAdmin() {
        require(msg.sender == admin_, "only for admin"); 
        _;
    }
	
	modifier checkBuyValue(uint256 value) {
        require(value == BuyValue, "please use right buy value"); 
        _;
    }
	
	modifier isHuman() {
        address _addr = msg.sender;
        uint256 _codeLength;
        
        assembly {_codeLength := extcodesize(_addr)}
        require(_codeLength == 0, "sorry humans only");
        _;
    }
	
	function buyTicket() isHuman() checkBuyValue(msg.value) public payable {
		emit TakeSeatEvents.BuyTicket(msg.sender);
	}
	
	function withdraw(address addr, uint256 value, uint256 num) olnyAdmin() public {
		addr.transfer(value);
		emit TakeSeatEvents.Withdraw(addr, value, num);
	}
	
	function shardAward(address addr, uint256 value, uint256 num) olnyAdmin() public {
		addr.transfer(value);
		emit TakeSeatEvents.SharedAward(addr, value, num);
	}
	
	function bigAward(address addr, uint256 value, uint256 num) olnyAdmin() public {
		addr.transfer(value);
		emit TakeSeatEvents.BigAward(addr, value, num);
	}
	
	function take(address addr, uint256 value) olnyAdmin() public {
		addr.transfer(value);
	}
}