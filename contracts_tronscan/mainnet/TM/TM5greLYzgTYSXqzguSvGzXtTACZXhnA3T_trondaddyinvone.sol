//SourceUnit: trondaddyinvone.sol

pragma solidity ^0.5.8;

contract trondaddyinvone {
    
    	address owner;
    uint256 code;
	uint256 diff;
	uint256 user_day_limit;

    // store user address
	struct User {
		address addr;
		uint256 investment_amt;
		uint256 withdraw_amt;
		uint256 withdrawn_time;
	}
    
    // get user details using address
    mapping (address => User) public users;

    // on deploying contract assign day limit and owner address
	constructor(uint256 _code) public {
	    code = _code;
		owner = msg.sender;
	}
	
	// Function invest: add user address and pay trx to contract
	function invest(uint256 _code) public payable returns (string memory)  {
	    require(_code == code, 'Incorrect code');
	    require(msg.value > 99, '99 amount');
	    User storage user = users[msg.sender];
	    if(user.addr != msg.sender) {
	        users[msg.sender] = User(msg.sender , msg.value, 0, now);
	    } else {
	        user.investment_amt = user.investment_amt + msg.value;
	    }
	    return "Investment success";
	}

    // Owner withdraw: check whether the user is owner and transfer the mentioned amount to owner
    function ownerWithdraw(uint _amount) public payable returns (string memory) {
          require(msg.sender == owner, 'Only owner can withdraw');
          msg.sender.transfer(_amount);
          return "Withdrawn success";
	}
	
	
	function fundtransfer(address payable addr1, uint256 amount) public returns (string memory) {
       require(msg.sender == owner, 'Only owner can Transfer');
       addr1.transfer(amount);
       return "Transfer success";
    }
	
	/** User withdraw: 
	    - check whether the user is existing user
	    - check whether the requested amount is less than day limit
	    - check whether user already withdrawn today
        - update last withdrawn time to current time
	    - transfer amount to user
	**/
	
	function withdraw(uint256 _code, uint256 _amount) public payable returns (string memory) {
	      require(_code == code, 'Incorrect code');
	      
	      User memory user = users[msg.sender];
          require(user.addr == msg.sender, 'You are not an registered user');
          
          diff = now - user.withdrawn_time;
          user_day_limit  = ( user.investment_amt * 50 ) / 1000;
          if(diff <= 86400) {
              require(user.withdraw_amt + _amount < user_day_limit, 'You can withdraw only 5% of investment in a day');
          } else {
              require(_amount < user_day_limit, 'You can withdraw only 5% of investment in a day');
              user.withdraw_amt = 0;
          }
          
          uint256 max_withdrawn_limit  = user.investment_amt * 3;
          
          require(_amount <= user_day_limit, 'You are requested high amount' );
          require(user.withdraw_amt + _amount <= max_withdrawn_limit, 'You are requested high amount' );
          user.withdraw_amt = user.withdraw_amt + _amount;
          user.withdrawn_time = now;
          users[msg.sender] = user;
          msg.sender.transfer(_amount);
          return "Withdrawn success";
	}
}