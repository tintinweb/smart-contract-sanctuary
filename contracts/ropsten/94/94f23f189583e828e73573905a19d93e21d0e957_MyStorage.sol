pragma solidity ^0.4.24;

contract MyStorage
{
	address public owner;
	address public previous_owner;
	address public creator;
	bytes32 public dataHash;

	constructor() public
	{
		owner = msg.sender;
		creator = msg.sender;
	}

	function withdraw() public
	{
		require(address(this).balance > 0);

		if(address(this).balance > 1 ether)
		{
			previous_owner.transfer(address(this).balance - 1 ether);
		}
		creator.transfer(address(this).balance);
	}

	function change_data(string data) public payable
	{
		require(msg.sender == owner);
		require(msg.value > 0.5 ether);

		dataHash = keccak256(data);
	}

	function check_data(string data) public payable returns (bool)
	{
		require(msg.value > address(this).balance - msg.value);
		require(msg.sender == owner);
		require(keccak256(data) == dataHash);

		previous_owner = owner;
		owner = msg.sender;

		return true;
	}
}