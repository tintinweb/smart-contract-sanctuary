// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.7.0;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";

import "../utils/MappedSinglyLinkedList.sol";
import "./VolumeDrip.sol";

/// @title Manages the active set of Volume Drips.
library VolumeDripManager {
  using SafeMath for uint256;
  using MappedSinglyLinkedList for MappedSinglyLinkedList.Mapping;
  using VolumeDrip for VolumeDrip.State;

  struct State {
    mapping(address => MappedSinglyLinkedList.Mapping) activeVolumeDrips;
    mapping(address => mapping(address => VolumeDrip.State)) volumeDrips;
  }

  /// @notice Activates a volume drip for the given (measure,dripToken) pair.
  /// @param self The VolumeDripManager state
  /// @param measure The measure token
  /// @param dripToken The drip token
  /// @param periodSeconds The period of the volume drip in seconds
  /// @param dripAmount The amount of tokens to drip each period
  /// @param endTime The end time to set for the current period.
  function activate(
    State storage self,
    address measure,
    address dripToken,
    uint32 periodSeconds,
    uint112 dripAmount,
    uint32 endTime
  )
    internal
    returns (uint32)
  {
    require(!self.activeVolumeDrips[measure].contains(dripToken), "VolumeDripManager/drip-active");
    if (self.activeVolumeDrips[measure].count == 0) {
      self.activeVolumeDrips[measure].initialize();
    }
    self.activeVolumeDrips[measure].addAddress(dripToken);
    self.volumeDrips[measure][dripToken].setNewPeriod(periodSeconds, dripAmount, endTime);

    return self.volumeDrips[measure][dripToken].periodCount;
  }

  /// @notice Deactivates the volume drip for the given (measure, dripToken) pair.
  /// @param self The VolumeDripManager state
  /// @param measure The measure token
  /// @param dripToken The drip token
  /// @param prevDripToken The active drip token previous to the passed on in the list.
  function deactivate(
    State storage self,
    address measure,
    address dripToken,
    address prevDripToken
  )
    internal
  {
    self.activeVolumeDrips[measure].removeAddress(prevDripToken, dripToken);
  }

  /// @notice Gets a list of active balance drip tokens
  /// @param self The BalanceDripManager state
  /// @param measure The measure token
  /// @return An array of Balance Drip token addresses
  function getActiveVolumeDrips(State storage self, address measure) internal view returns (address[] memory) {
    return self.activeVolumeDrips[measure].addressArray();
  }

  /// @notice Sets the parameters for the next period of an active volume drip
  /// @param self The VolumeDripManager state
  /// @param measure The measure token
  /// @param dripToken The drip token
  /// @param periodSeconds The length in seconds to use for the next period
  /// @param dripAmount The amount of tokens to be dripped in the next period
  function set(State storage self, address measure, address dripToken, uint32 periodSeconds, uint112 dripAmount) internal {
    require(self.activeVolumeDrips[measure].contains(dripToken), "VolumeDripManager/drip-not-active");
    self.volumeDrips[measure][dripToken].setNextPeriod(periodSeconds, dripAmount);
  }

  /// @notice Returns whether or not an active volume drip exists for the given (measure, dripToken) pair
  /// @param self The VolumeDripManager state
  /// @param measure The measure token
  /// @param dripToken The drip token
  function isActive(State storage self, address measure, address dripToken) internal view returns (bool) {
    return self.activeVolumeDrips[measure].contains(dripToken);
  }

  /// @notice Returns the VolumeDrip.State for the given (measure, dripToken) pair.
  /// @param self The VolumeDripManager state
  /// @param measure The measure token
  /// @param dripToken The drip token
  function getDrip(State storage self, address measure, address dripToken) internal view returns (VolumeDrip.State storage) {
    return self.volumeDrips[measure][dripToken];
  }
}
