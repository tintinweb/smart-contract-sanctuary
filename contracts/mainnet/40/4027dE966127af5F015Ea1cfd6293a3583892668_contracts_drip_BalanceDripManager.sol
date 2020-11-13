// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

import "../utils/MappedSinglyLinkedList.sol";
import "./BalanceDrip.sol";

/// @title Manages the lifecycle of a set of Balance Drips.
library BalanceDripManager {
  using SafeMath for uint256;
  using MappedSinglyLinkedList for MappedSinglyLinkedList.Mapping;
  using BalanceDrip for BalanceDrip.State;

  struct State {
    mapping(address => MappedSinglyLinkedList.Mapping) activeBalanceDrips;
    mapping(address => mapping(address => BalanceDrip.State)) balanceDrips;
  }

  /// @notice Activates a drip by setting it's state and adding it to the active balance drips list.
  /// @param self The BalanceDripManager state
  /// @param measure The measure token
  /// @param dripToken The drip token
  /// @param dripRatePerSecond The amount of the drip token to be dripped per second
  function activateDrip(
    State storage self,
    address measure,
    address dripToken,
    uint256 dripRatePerSecond
  )
    internal
  {
    require(!self.activeBalanceDrips[measure].contains(dripToken), "BalanceDripManager/drip-active");
    if (self.activeBalanceDrips[measure].count == 0) {
      self.activeBalanceDrips[measure].initialize();
    }
    self.activeBalanceDrips[measure].addAddress(dripToken);
    self.balanceDrips[measure][dripToken].resetTotalDripped();
    self.balanceDrips[measure][dripToken].dripRatePerSecond = dripRatePerSecond;
  }

  /// @notice Deactivates an active balance drip.  The balance drip is removed from the active balance drips list.
  /// The drip rate for the balance drip will be set to zero to ensure it's "frozen".
  /// @param measure The measure token
  /// @param dripToken The drip token
  /// @param prevDripToken The previous drip token previous in the list.
  /// If no previous, then pass the SENTINEL address: 0x0000000000000000000000000000000000000001
  /// @param currentTime The current time
  function deactivateDrip(
    State storage self,
    address measure,
    address dripToken,
    address prevDripToken,
    uint32 currentTime,
    uint256 maxNewTokens
  )
    internal
  {
    self.activeBalanceDrips[measure].removeAddress(prevDripToken, dripToken);
    self.balanceDrips[measure][dripToken].drip(IERC20(measure).totalSupply(), currentTime, maxNewTokens);
    self.balanceDrips[measure][dripToken].dripRatePerSecond = 0;
  }

  /// @notice Gets a list of active balance drip tokens
  /// @param self The BalanceDripManager state
  /// @param measure The measure token
  /// @return An array of Balance Drip token addresses
  function getActiveBalanceDrips(State storage self, address measure) internal view returns (address[] memory) {
    return self.activeBalanceDrips[measure].addressArray();
  }

  /// @notice Sets the drip rate for an active balance drip.
  /// @param self The BalanceDripManager state
  /// @param measure The measure token
  /// @param dripToken The drip token
  /// @param dripRatePerSecond The amount to drip of the token each second
  /// @param currentTime The current time.
  function setDripRate(
    State storage self,
    address measure,
    address dripToken,
    uint256 dripRatePerSecond,
    uint32 currentTime,
    uint256 maxNewTokens
  ) internal {
    require(self.activeBalanceDrips[measure].contains(dripToken), "BalanceDripManager/drip-not-active");
    self.balanceDrips[measure][dripToken].drip(IERC20(measure).totalSupply(), currentTime, maxNewTokens);
    self.balanceDrips[measure][dripToken].dripRatePerSecond = dripRatePerSecond;
  }

  /// @notice Returns whether or not a drip is active for the given measure, dripToken pair
  /// @param self The BalanceDripManager state
  /// @param measure The measure token
  /// @param dripToken The drip token
  /// @return True if there is an active balance drip for the pair, false otherwise
  function isDripActive(State storage self, address measure, address dripToken) internal view returns (bool) {
    return self.activeBalanceDrips[measure].contains(dripToken);
  }

  /// @notice Returns the BalanceDrip.State for the given measure, dripToken pair
  /// @param self The BalanceDripManager state
  /// @param measure The measure token
  /// @param dripToken The drip token
  /// @return The BalanceDrip.State for the pair
  function getDrip(State storage self, address measure, address dripToken) internal view returns (BalanceDrip.State storage) {
    return self.balanceDrips[measure][dripToken];
  }
}
