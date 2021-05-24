// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IChainLinkOracle.sol";
import "./interfaces/IKeeperV2Oracle.sol";

contract InvOracleHelper is IChainLinkOracle {
    address constant public inv = 0x41D5D79431A913C4aE7d69a668ecdfE5fF9DFB68;
    address constant public weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IChainLinkOracle constant public ethFeed = IChainLinkOracle(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    IKeeperV2Oracle constant public keeper = IKeeperV2Oracle(0x39b1dF026010b5aEA781f90542EE19E900F2Db15);

    function latestAnswer() external override view returns (uint256 answer) {
        (uint256 invEthPrice, ) = keeper.current(inv, 1e18, weth);
        uint256 ethPrice = ethFeed.latestAnswer();
        answer = invEthPrice * ethPrice /1e18;
    }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IChainLinkOracle {
    function latestAnswer() external view returns (uint256);
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IKeeperV2Oracle {
    function current(address, uint, address) external view returns (uint256, uint256);
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