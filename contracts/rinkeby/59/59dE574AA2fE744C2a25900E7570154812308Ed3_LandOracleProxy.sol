pragma solidity ^0.8.0;

interface ILandEthPriceOracle {
    function lastLandIndexTokenPerEth() external view returns (uint256);
}

// Need to start calling a function that updates the oracle!
contract LandOracleProxy {
    function LandPrice(address _called) external view returns (uint256) {
        return ILandEthPriceOracle(_called).lastLandIndexTokenPerEth();
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}