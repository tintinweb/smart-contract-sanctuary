// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

interface ITruPriceOracle {
    function usdToTru(uint256 amount) external view returns (uint256);

    function truToUsd(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.10;

import "ITruPriceOracle.sol";

contract MockTruPriceOracle is ITruPriceOracle {
    function usdToTru(uint256 amount) external override view returns (uint256) {
        return (amount * 4) / 1e10;
    }

    function truToUsd(uint256 amount) external override view returns (uint256) {
        return (amount * 1e10) / 4;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 20000
  },
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