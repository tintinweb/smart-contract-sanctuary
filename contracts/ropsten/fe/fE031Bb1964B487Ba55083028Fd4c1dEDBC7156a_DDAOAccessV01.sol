// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


contract DDAOAccessV01
{
	constructor()
	{
	}


	function balanceOf(address addr,uint8 level) public view returns(uint256)
	{
		if(level == 1)return 1;
		if(level == 2)return 0;
		if(level == 3)return 1;
	}
}