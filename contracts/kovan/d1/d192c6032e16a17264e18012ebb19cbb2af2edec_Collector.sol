/**
 *Submitted for verification at Etherscan.io on 2021-05-11
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.0;

interface IERC20
{
	function balanceOf(address _account) external view returns (uint256 _amount);
	function transfer(address _recipient, uint256 _amount) external returns (bool _success);
}

contract Collector
{
	address constant TREASURY = 0xb327bCbFA79380b8111e3D2EAB0F3F8b0A69D54f;

	function collectFunds(address _token) external
	{
		require(msg.sender == TREASURY, "access denied");
		IERC20(_token).transfer(TREASURY, IERC20(_token).balanceOf(address(this)));
	}
}