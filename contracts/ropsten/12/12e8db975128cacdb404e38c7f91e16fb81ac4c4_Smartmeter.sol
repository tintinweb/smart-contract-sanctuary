/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.16 <0.9.0;

contract Smartmeter
{
	uint256 number;

	function () external payable {
		
	}

	function store(uint256 num) public
	{
		number = num;
	}

	function retrieve() public view returns (uint256)
	{
		return number;
	}
}