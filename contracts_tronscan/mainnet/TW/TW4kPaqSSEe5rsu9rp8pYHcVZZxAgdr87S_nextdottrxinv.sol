//SourceUnit: nextdottrxinv.sol

pragma solidity 0.5.8;

contract nextdottrxinv {
	address owner;
    uint256 dayLimit;
    uint256 public diff;

    // store user address
	struct User {
		address addr;
		uint256 withdrawn;
	}
    
    // get user details using address
    mapping (address => User) public users;

    // on deploying contract assign day limit and owner address
	constructor(uint256 _dayLimit) public {
	    dayLimit = _dayLimit;
		owner = msg.sender;
	}
	
	// Function invest: add user address and pay trx to contract
	function invest() public payable {
	    require(msg.value > 499, '499 amount');
	    User storage user = users[msg.sender];
	    if(user.addr != msg.sender) {
	        users[msg.sender] = User(msg.sender , block.timestamp - 1 days);
	    }
	}

    // Owner withdraw: check whether the user is owner and transfer the mentioned amount to owner
    function ownerWithdraw(uint256 amount) public payable returns (uint256) {
          require(msg.sender == owner, 'Only owner can withdraw');
          msg.sender.transfer(amount);
	}
	
	

}