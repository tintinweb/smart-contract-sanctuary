// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.7.0;

/// @title Interface that allows a user to draw an address using an index
interface ReserveInterface {
  function reserveRateMantissa(address prizePool) external view returns (uint256);
}
