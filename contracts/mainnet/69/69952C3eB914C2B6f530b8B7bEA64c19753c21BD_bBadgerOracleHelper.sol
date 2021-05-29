// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IChainLinkOracle.sol";
import "./interfaces/IXToken.sol";

contract bBadgerOracleHelper is IChainLinkOracle {
    IChainLinkOracle constant public badgerFeed = IChainLinkOracle(0x66a47b7206130e6FF64854EF0E1EDfa237E65339);
    IXToken constant public bBadger = IXToken(0x19D97D8fA813EE2f51aD4B4e04EA08bAf4DFfC28);

    function latestAnswer() external override view returns (uint256 answer) {
        uint256 badgerPrice = badgerFeed.latestAnswer();
        answer = badgerPrice * bBadger.getPricePerFullShare() / 1e18;
    }
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IChainLinkOracle {
    function latestAnswer() external view returns (uint256);
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

interface IXToken {
    function getPricePerFullShare() external view returns (uint256);
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