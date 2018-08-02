pragma solidity ^0.4.24;

contract DonateDust {

	address public owner;
	uint256 public totalDonations;

	constructor() {
		owner = msg.sender;
	}

	modifier onlyOwner { 
		require (msg.sender == owner); 
		_; 
	}
	
	function donate() public payable {
		totalDonations += msg.value;
	}

	function withdraw() public onlyOwner {
		owner.transfer(address(this).balance);
	}
	
	function() public payable {
		donate();
	}
}