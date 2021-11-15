//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface IOracle {
  function getPrice(address token, uint256 amount) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IOracle.sol";

contract SingleTokenOracle is IOracle {
  address public immutable token;

  constructor(address _token) {
    token = _token;
  }

  function getPrice(address _token, uint256 amount) external view override returns (uint256) {
    if (_token == token) {
      return amount;
    }

    return 0;
  }
}

