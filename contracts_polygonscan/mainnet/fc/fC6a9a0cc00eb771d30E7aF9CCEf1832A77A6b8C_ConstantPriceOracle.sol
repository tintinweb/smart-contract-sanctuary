pragma solidity ^0.5.16;

contract ConstantPriceOracle {
    function getUnderlyingPrice(address cToken) public view returns (uint) {
        // Shh -- currently unused
        cToken;
        return 2e18;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
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