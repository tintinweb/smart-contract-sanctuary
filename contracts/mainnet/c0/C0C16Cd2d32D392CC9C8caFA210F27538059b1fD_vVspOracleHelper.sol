// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IChainLinkOracle.sol";
import "./interfaces/IBalancerPool.sol";

contract vVspOracleHelper is IChainLinkOracle {
    IBalancerPool constant public router = IBalancerPool(0xf7B90b1c3A2C31d5286B1A6472162cABF3De900c);
    address constant public vvsp = 0xbA4cFE5741b357FA371b506e5db0774aBFeCf8Fc;
    address constant public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IChainLinkOracle constant public ethFeed = IChainLinkOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);

    function latestAnswer() external override view returns (uint256 answer) {
        uint256 vvspEthPrice = router.getSpotPrice(weth, vvsp);
        uint256 ethPrice = ethFeed.latestAnswer();
        answer = vvspEthPrice * ethPrice /1e18;
    }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IChainLinkOracle {
    function latestAnswer() external view returns (uint256);
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IBalancerPool {
    function getSpotPrice(address, address) external view returns (uint256);
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