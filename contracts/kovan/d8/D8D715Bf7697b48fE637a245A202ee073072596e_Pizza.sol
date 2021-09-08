//SPDX-License-Identifier: Unlicense
pragma solidity ^0.6.6;

contract Pizza {
  event Order(uint orderId, uint numberOfPizzas);
  event DeliveryStarted(uint orderId, uint eta, address deliverer);
  event DeliveryComplete(uint orderId, uint arrival, uint tip);

  uint numberOfOrders;

  function order(uint numberOfPizzas) external {
    numberOfOrders++;
    emit Order(numberOfOrders, numberOfPizzas);
  }

  function takeOnDelivery(uint orderId, uint eta) external {
    emit DeliveryStarted(orderId, eta, msg.sender);
  }

  function completeDelivery(uint orderId, uint tip) external {
    emit DeliveryComplete(orderId, block.timestamp, tip);
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