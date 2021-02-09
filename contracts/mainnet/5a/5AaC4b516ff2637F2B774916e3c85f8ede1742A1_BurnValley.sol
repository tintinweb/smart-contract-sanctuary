//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

import "../interfaces/IBurnable.sol";


contract BurnValley {
  event TokensDestroyed(address token, uint256 amount, address burner);
  /**
    * @dev Method for burning any token from contract balance.
    *
    * Can be called by Factory contract
    *
    * Emits a {TokensDestroyed} event.
    */
  function burnAllTokens(address _token) external {
    IBurnable token = IBurnable(_token);

    uint256 balance = token.balanceOf(address(this));
    token.burn(balance);

    emit TokensDestroyed(_token, balance, msg.sender);
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.3;

interface IBurnable {
  function burn(uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
}