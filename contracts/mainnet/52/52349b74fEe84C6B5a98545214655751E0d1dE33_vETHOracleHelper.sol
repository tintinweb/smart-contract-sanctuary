// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IChainLinkOracle.sol";
import "./interfaces/ISaddlePool.sol";

contract vETHOracleHelper is IChainLinkOracle {
    address constant public inv = 0x41D5D79431A913C4aE7d69a668ecdfE5fF9DFB68;
    address constant public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IChainLinkOracle constant public ethFeed = IChainLinkOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    function latestAnswer() external override view returns (uint256 answer) {
        uint256 vethPrice = ISaddlePool(0xdec2157831D6ABC3Ec328291119cc91B337272b5).calculateSwap(1, 0, 10**18);
        uint256 ethPrice = ethFeed.latestAnswer();
        answer = vethPrice * ethPrice /1e18;
    }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IChainLinkOracle {
    function latestAnswer() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ISaddlePool {
    function calculateSwap(uint8 from, uint8 to, uint256 dx) external view returns (uint256);
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