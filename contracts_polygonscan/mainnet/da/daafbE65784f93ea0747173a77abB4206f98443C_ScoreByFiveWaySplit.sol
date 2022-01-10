// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;


interface IScoringStrategy {
  function getTokenScores(address[] calldata tokens) external view returns (uint256[] memory scores);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.6.0;

import "../interfaces/IScoringStrategy.sol";

contract ScoreByFiveWaySplit is IScoringStrategy {
  uint256 internal constant ONE = 1e18;

  function getTokenScores(address[] calldata tokens)
    external
    view
    override
    returns (uint256[] memory scores)
  {
    require(tokens.length == 5, "Must provide 5 tokens");
    scores = new uint256[](5);
    scores[0] = ONE;
    scores[1] = ONE;
    scores[2] = ONE;
    scores[3] = ONE;
    scores[4] = ONE;
  }
}