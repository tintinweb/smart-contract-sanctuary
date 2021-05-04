pragma solidity >=0.6.0 <0.8.0;

interface IOracle {
    function getValue() external view returns (uint256);
}

contract MockOracle is IOracle {
    constructor() public {}
    
    function getValue() override external view returns (uint256) {
        return uint(blockhash(block.number - 1));
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