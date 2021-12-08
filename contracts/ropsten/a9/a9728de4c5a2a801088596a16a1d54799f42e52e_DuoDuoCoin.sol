/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;

abstract contract  ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) public view virtual returns (uint);
  function transfer(address to, uint value) public virtual;
  event Transfer(address indexed from, address indexed to, uint value);
}

contract DuoDuoCoin is ERC20Basic {
    address private minter;
    mapping (address => uint) private balances;

    constructor() {
        minter = msg.sender;
    }

    function mint(address receiver, uint amount) public {
        require(msg.sender == minter);
        require(amount < 1e9);
        balances[receiver] += amount;
    }
	
	function balanceOf(address who) public view override returns (uint balence) {
		return balances[who];
	}
	
    function transfer(address receiver, uint amount) public override {
        require(amount <= balances[msg.sender], "Insufficient balance.");
        balances[msg.sender] -= amount;
        balances[receiver] += amount;
        emit Transfer(msg.sender, receiver, amount);
    }
}