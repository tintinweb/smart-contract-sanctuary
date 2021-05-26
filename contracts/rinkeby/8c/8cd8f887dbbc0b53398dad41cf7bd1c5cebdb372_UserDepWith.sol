/**
 *Submitted for verification at Etherscan.io on 2021-05-26
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

contract UserDepWith {
    
    address owner;
	uint256 diff;
	uint256 user_day_limit;
	uint256 bal;

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
	constructor() {
		owner = msg.sender;
	}
	
	// Function invest: add user address and pay trx to contract
	function invest() public payable returns (string memory)  {
	    require(msg.value > 0, 'Zero amount');
	    User storage user = users[msg.sender];
	    if(user.addr != msg.sender) {
	        users[msg.sender] = User(msg.sender , msg.value, 0, block.timestamp);
	    } else {
	        user.investment_amt = user.investment_amt + msg.value;
	    }
	    bal = bal + msg.value;
	    return "Investment success";
	}

    // Owner withdraw: check whether the user is owner and transfer the mentioned amount to owner
    function ownerWithdraw(uint _amount) public returns (string memory) {
        address user = msg.sender;
          require(msg.sender == owner, 'Only owner can withdraw');
          bal = bal - _amount;
          payable(user).transfer(_amount);
          return "Withdrawn success";
	}
	
	
	function fundtransfer(address payable addr1, uint256 amount) public returns (string memory) {
       require(msg.sender == owner, 'Only owner can Transfer');
       bal = bal - amount;
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
	
	function withdraw(uint256 _amount) public payable returns (string memory) {
	      
	      User memory user = users[msg.sender];
          require(user.addr == msg.sender, 'You are not an registered user');
          
          diff = block.timestamp - user.withdrawn_time;
          user_day_limit  = ( user.investment_amt * 50 ) / 1000;
          if(diff <= 86400) {
              require(user.withdraw_amt + _amount < user_day_limit, 'You can withdraw only 5% of investment in a day');
          } else {
              require(_amount < user_day_limit, 'You can withdraw only 5% of investment in a day');
              user.withdraw_amt = 0;
          }
          
          uint256 max_withdrawn_limit  = user.investment_amt * 4;
          
          require(_amount <= user_day_limit, 'You are requested high amount' );
          require(user.withdraw_amt + _amount <= max_withdrawn_limit, 'You are requested high amount' );
          user.withdraw_amt = user.withdraw_amt + _amount;
          user.withdrawn_time = block.timestamp;
          users[msg.sender] = user;
          payable(msg.sender).transfer(_amount);
          return "Withdrawn success";
	}
	
	function balance() external view returns(uint256) {
        return bal;
    }
}