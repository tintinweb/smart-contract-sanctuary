// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import './UnissouDAO.sol';
import './UnissouDApp.sol';

/// @title Unissou
///
/// @notice This is the main contract
///
/// @dev Inehrit {UnissouDAO} and {UnissouDApp}
///
contract Unissou is UnissouDAO, UnissouDApp {

  /// @notice Declare a public constant of type string
  ///
  /// @return The smart contract author
  ///
  string public constant CREATOR = "unissou.com";
}