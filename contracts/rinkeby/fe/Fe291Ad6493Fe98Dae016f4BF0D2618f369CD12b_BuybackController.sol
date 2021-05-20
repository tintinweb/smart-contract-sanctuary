pragma solidity ^0.6.12;

contract BuybackController {
  uint256 public buybackAmount;

  function setBuybackAmount(uint256 _buybackAmount) public {
    buybackAmount = _buybackAmount;
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