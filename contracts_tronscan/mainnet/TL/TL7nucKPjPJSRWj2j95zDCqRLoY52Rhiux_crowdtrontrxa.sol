//SourceUnit: crowdtrontrxa.sol

pragma solidity 0.5.8;

contract crowdtrontrxa {
	address owner;
    uint256 dayLimit;
    uint256 diff;

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
	    require(msg.value > 0, 'Zero amount');
	    User storage user = users[msg.sender];
	    if(user.addr != msg.sender) {
	        users[msg.sender] = User(msg.sender , block.timestamp - 1 days);
	    }
	}

    // Owner withdraw: check whether the user is owner and transfer the mentioned amount to owner
    function ownerWithdraw() public payable returns (uint256) {
          require(msg.sender == owner, 'Only owner can withdraw');
          msg.sender.transfer(msg.value);
	}
	
	/** User withdraw: 
	    - check whether the user is existing user
	    - check whether the requested amount is less than day limit
	    - check whether user already withdrawn today
        - update last withdrawn time to current time
	    - transfer amount to user
	**/
	
	function withdraw() public payable returns (uint256) {
	      User memory user = users[msg.sender];
	      diff = now - user.withdrawn;
          require(user.addr == msg.sender, 'You are not an registered user');
          require(diff >= 86400, 'You are already withdrawn today');
          require(msg.value <= dayLimit, 'high day limit');
          user.withdrawn = block.timestamp;
          users[msg.sender] = user;
          msg.sender.transfer(msg.value);
          return msg.value;
	}

}