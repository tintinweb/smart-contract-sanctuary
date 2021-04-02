pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

contract SecondaryConnector {
    event Info(
        address indexed msgSender,
        address indexed thisAddr,
        address[] tokens
    );
    function getInfo(address[] calldata tokens) external payable {
        emit Info(msg.sender, address(this), tokens);
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