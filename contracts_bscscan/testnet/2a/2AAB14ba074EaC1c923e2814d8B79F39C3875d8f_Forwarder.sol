pragma solidity 0.8.2;

contract Forwarder{

function forward(address payable _receipt) public payable {

_receipt.transfer(msg.value);
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