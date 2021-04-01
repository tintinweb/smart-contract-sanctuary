/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

// SPDX-License-Identifier: MPL-2.0
pragma solidity 0.7.6;

interface IVoteEmitter {
	event Vote(address indexed dispatcher, address voter, uint8[] percentiles);

	function dispatch(address voter, uint8[] memory percentiles) external;
}

contract VoteEmitter is IVoteEmitter {
	function dispatch(address voter, uint8[] memory percentiles)
		external
		override
	{
		emit Vote(msg.sender, voter, percentiles);
	}
}