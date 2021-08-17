// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;



contract ERC20Token {
	string public name = "Test Token";
	string public symbol = "TT";
	uint public totalSupply = 1000000;
	address public owner;
	mapping(address => uint) balances;

	event Transfer(address indexed from, address indexed to, uint value);

	constructor() {
		balances[msg.sender] = totalSupply;
		owner = msg.sender;
	}

	function transfer(address to, uint amount) external returns (bool) {



		require(balances[msg.sender] >= amount, 'Not enough tokens');

		balances[msg.sender] -= amount;
		balances[to] += amount;
		emit Transfer(msg.sender, to, amount);
		return true;
	}

	function balanceOf(address account) external view returns(uint) {
		return balances[account];
	}
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}