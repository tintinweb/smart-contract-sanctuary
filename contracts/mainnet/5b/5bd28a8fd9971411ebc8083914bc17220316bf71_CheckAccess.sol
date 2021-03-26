/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.1;

/*
VERSION DATE: 17/03/2021
*/

contract CheckAccess 
{
	address public owner;

	mapping(address => bool) public admins;
	
	event AddAdmin(address user);
	event RemoveAdmin(address user);
	
	modifier onlyOwner {
        require(msg.sender == owner, "wrong owner");
        _;
    }

	constructor() 
	{
		owner = msg.sender;
    }
	
    function changeOwner(address newOwner) public onlyOwner
	{
		require(newOwner != address(0), "wrong address");
		require(newOwner != owner, "wrong address");

        owner = newOwner;
    }
	
    function addAdmin(address addr) public onlyOwner
	{
		require(addr != address(0));
		require(admins[addr] == false, "admin exists");

		admins[addr] = true;
		
		emit AddAdmin(addr);
    }

    function removeAdmin(address addr) public onlyOwner
	{
		require(admins[addr] == true, "admin does not exists");
		
		delete admins[addr];
		
		emit RemoveAdmin(addr);
    }
	
	function isAdmin(address addr) public view returns (bool)
	{
		return( admins[addr] );
    }
}