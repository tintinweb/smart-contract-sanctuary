// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMarketOracle.sol";

contract MarketOracleMock is IMarketOracle {
  constructor() {}

  function getData() external pure override returns (uint256) {
    return 15151348220717791; // $0.0151534
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMarketOracle {
  function getData() external view returns (uint256);
}