/**
 *Submitted for verification at polygonscan.com on 2021-08-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

interface ERC20 {
	function transfer(address, uint256) external returns (bool);
}


contract Treasury {

	address public owner;

	constructor(address _owner) {
		owner = _owner;
	}

	function updateOwner(address _newOwner) external {
		require(msg.sender == owner);
		owner = _newOwner;
	}

	function transferToken(ERC20 _token, address _receiver, uint256 _amount) external {
		require(msg.sender == owner);
		_token.transfer(_receiver, _amount);
	}
}