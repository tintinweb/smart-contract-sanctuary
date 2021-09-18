//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

contract FeePool {
    address destination;

    // Event give info who done to pay for fee
    event Deposit(address indexed _from, uint256 indexed _id, uint _value);

    /*
    @param destination - it's main wallet address which manage withdrawal
    */
    constructor(address _destination) {
        destination = _destination;
    }

    /*
    @param _withdrawalId - for which deposit pay fee
    */
    function transfer(uint256 _withdrawalId) public payable {
        require(msg.value > 0, "Transfer from the zero address");
        (bool sent,) = payable(destination).call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        emit Deposit(msg.sender, _withdrawalId, msg.value);
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