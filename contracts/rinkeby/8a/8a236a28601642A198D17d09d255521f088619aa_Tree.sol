/**
 *Submitted for verification at Etherscan.io on 2021-09-16
*/

// SPDX-License-Identifier: MIT



pragma solidity ^0.8.0;

contract Tree {
  mapping (address => uint) balances;

	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	constructor() {
		balances[tx.origin] = 10000;
	}

	function getBalance(address addr) public view returns(uint) {
		return balances[addr];
	}
}