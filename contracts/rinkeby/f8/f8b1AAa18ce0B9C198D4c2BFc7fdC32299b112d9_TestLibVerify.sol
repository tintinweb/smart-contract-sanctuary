// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Strings.sol";
import "./ERC721.sol";

// File: @openzeppelin/contracts/utils/TestLibVerify.sol

/**
 * @dev TestLibVerify.
 */
contract TestLibVerify is ERC721 {
  using Strings for uint256;

  constructor() ERC721("test1", "test") {}
}