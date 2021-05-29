// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IChainLinkOracle.sol";
import "./interfaces/IXToken.sol";

contract xCoverOracleHelper is IChainLinkOracle {
    IChainLinkOracle constant public coverFeed = IChainLinkOracle(0x0ad50393F11FfAc4dd0fe5F1056448ecb75226Cf);
    IXToken constant public xCover = IXToken(0xa921392015eB37c5977c4Fd77E14DD568c59D5F8);

    function latestAnswer() external override view returns (uint256 answer) {
        uint256 coverPrice = coverFeed.latestAnswer();
        answer = coverPrice * xCover.getShareValue() / 1e18;
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
    function getShareValue() external view returns (uint256);
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