// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Event {
    enum Status {
        AtBase,
        AtTranspot,
        AtCustomer
    }

    uint256 public item;
    uint256 public totalAmount;

    event Start(uint256 item, uint256 time);

    event SendItem(
        uint256 indexed item,
        address indexed from,
        address indexed to,
        uint256 amount,
        Status status
    );

    event SendItemNoIndex(
        uint256 item,
        address from,
        address to,
        uint256 amount,
        Status status
    );

    constructor() {
        item = 1;
    }

    function delivery(address _to, uint256 _amount) external {
        emit Start(item, block.timestamp);

        emit SendItem(item, msg.sender, _to, _amount, Status.AtTranspot);
        emit SendItemNoIndex(item, msg.sender, _to, _amount, Status.AtTranspot);

        item++;
        totalAmount += _amount;
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