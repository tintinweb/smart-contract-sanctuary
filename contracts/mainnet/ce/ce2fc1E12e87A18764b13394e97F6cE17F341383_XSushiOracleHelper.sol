// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IChainLinkOracle.sol";

contract XSushiOracleHelper is IChainLinkOracle {
    IChainLinkOracle constant public rawXSushiFeed = IChainLinkOracle(0x8Aa3932790b33C7Cc751231161Ae5221af058D12);

    // returns USD price in 1e8
    function latestAnswer() external override view returns (uint256 answer) {
        uint256 rawXSushiPrice = rawXSushiFeed.latestAnswer(); // 1e18
        answer = rawXSushiPrice / 1e10;
    }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IChainLinkOracle {
    function latestAnswer() external view returns (uint256);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 2000
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