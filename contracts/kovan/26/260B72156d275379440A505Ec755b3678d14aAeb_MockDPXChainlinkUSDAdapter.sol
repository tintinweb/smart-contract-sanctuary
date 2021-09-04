// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { IOracle } from "../interfaces/IOracle.sol";

contract MockDPXChainlinkUSDAdapter is IOracle {
  function getPriceInUSD() external pure override returns (uint256 price) {
    return 100e8; // 100$
  }

  function viewPriceInUSD() external pure override returns (uint256 price) {
    return 100e8; // 100$
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOracle {
  event PriceUpdated(address asset, uint256 newPrice);

  function getPriceInUSD() external returns (uint256);

  function viewPriceInUSD() external view returns (uint256);
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}