/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

/**
 *Submitted for verification at Etherscan.io on 2019-06-13
*/

pragma solidity ^0.4.22;

// Adding only the ERC-20 function we need 
interface DaiToken {
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

contract owned {
    DaiToken daitoken;
	address owner;

	constructor() public{
		owner = msg.sender;
		daitoken = DaiToken(0x4f96fe3b7a6cf9725f59d353f723c1bdb64ca6aa);
	}
	
	modifier onlyOwner {
		require(msg.sender == owner,
		        "Only the contract owner can call this function");
		_;
	}
}

contract mortal is owned {
	// Only owner can shutdown this contract. 
	function destroy() public onlyOwner {
	    daitoken.transfer(owner, daitoken.balanceOf(address(this)));
		selfdestruct(owner);
	}
}

contract DaiFaucet is mortal {
    
	event Withdrawal(address indexed to, uint amount);
	event Deposit(address indexed from, uint amount);
	

	// Give out Dai to anyone who asks
	function withdraw(uint withdraw_amount) public {
		// Limit withdrawal amount
		require(withdraw_amount <= 0.1 ether);
		require(daitoken.balanceOf(address(this)) >= withdraw_amount,
			"Insufficient balance in faucet for withdrawal request");
		// Send the amount to the address that requested it
		daitoken.transfer(msg.sender, withdraw_amount);
		emit Withdrawal(msg.sender, withdraw_amount);
	}
	
	// Accept any incoming amount
	function () external payable {
		emit Deposit(msg.sender, msg.value);
	}
}