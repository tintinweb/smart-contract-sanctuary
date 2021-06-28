// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.7.6;

contract EthPool {
    address owner;
    mapping(address => uint256) public balances;

    constructor() {
        owner = msg.sender;
    }

    event Deposit(address sender, uint256 amount);
    event Withdrawal(address from, uint256 amount);
    event DepositReward(address recipient, uint256 amount);

    function deposit() public payable {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
        msg.sender.transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    function depositRewards(address addr) public payable {
        require(msg.sender == owner);
        balances[addr] += msg.value;
        emit DepositReward(addr, msg.value);
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
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