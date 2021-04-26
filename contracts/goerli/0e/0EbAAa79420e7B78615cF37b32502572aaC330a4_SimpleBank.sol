// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract SimpleBank {
    uint8 private clientCount;
    mapping(address => uint256) private balances;
    address public owner;

    event LogDepositMade(address indexed accountAddress, uint256 amount);

    constructor() payable {
        require(msg.value == 1 ether, "1 ether initial funding required");
        /* Set the owner to the creator of this contract */
        owner = msg.sender;
        balances[msg.sender] = msg.value;
        clientCount = 0;
    }

    function enroll() public returns (uint256) {
        clientCount++;
        balances[msg.sender] = 1 ether;
        return balances[msg.sender];
    }

    function deposit() public payable returns (uint256) {
        balances[msg.sender] += msg.value;
        return balances[msg.sender];
    }

    function withdraw(uint256 withdrawAmount)
        public
        returns (uint256 remainingBal)
    {
        // Check enough balance available, otherwise just return balance
        if (withdrawAmount <= balances[msg.sender]) {
            balances[msg.sender] -= withdrawAmount;
            payable(msg.sender).transfer(withdrawAmount);
        }
        return balances[msg.sender];
    }

    function balance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function depositsBalance() public view returns (uint256) {
        return address(this).balance;
    }
}

{
  "optimizer": {
    "enabled": false,
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