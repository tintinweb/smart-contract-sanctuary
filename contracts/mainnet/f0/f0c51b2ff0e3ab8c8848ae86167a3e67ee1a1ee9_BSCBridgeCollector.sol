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

contract BSCBridgeCollector
{
	address constant TREASURY = 0xc718E5a5b06ce7FEd722B128C0C0Eb9c5c902D92;

	function collectFunds(address _token) external
	{
		require(msg.sender == TREASURY, "access denied");
		IERC20(_token).transfer(TREASURY, IERC20(_token).balanceOf(address(this)));
	}
}