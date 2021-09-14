pragma solidity 0.4.21;

contract Forwarder{

function forward(address _receipt) public payable {

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