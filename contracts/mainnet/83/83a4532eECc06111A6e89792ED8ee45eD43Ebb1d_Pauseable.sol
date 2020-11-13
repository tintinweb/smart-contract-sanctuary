// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import './Roleplay.sol';

/// @title Pauseable
///
/// @notice This contract covers everything related
/// to the pause functions
///
/// @dev Inehrit {Roleplay}
///
contract Pauseable is Roleplay {
  /// @dev Declare a private bool {_paused}
  ///
  bool private _paused;
  
  /// @dev Declare two events to expose when pause
  /// is enabled or disabled, take the event's sender
  /// as argument
  ///
  event Paused(address indexed _from);
  event Unpaused(address indexed _from);

  /// @dev Verify if the contract is not paused
  /// 
  /// Requirements:
  /// {_paused} should be false
  ///
  modifier whenNotPaused() {
    require(
      !_paused,
      "PC:300"
    );
    _;
  }

  /// @dev Verify if the contract is paused
  /// 
  /// Requirements:
  /// {_paused} should be true
  ///
  modifier whenPaused() {
    require(
      _paused,
      "PC:310"
    );
    _;
  }

  /// @dev By default, pause is disabled
  ///
  constructor ()
  internal {
    _paused = false;
  }

  /// @notice Expose the state of {_paused}
  ///
  /// @return The state as a bool
  ///
  function paused()
  public view returns (bool) {
    return _paused;
  }
  
  /// @dev Enable pause by setting {_paused}
  /// to true, then emit the related event
  ///
  function pause()
  public virtual whenNotPaused() onlyOwner() {
    _paused = true;
    emit Paused(msg.sender);
  }

  /// @dev Disable pause by setting {_paused}
  /// to false, then emit the related event
  ///
  function unpause()
  public virtual whenPaused() onlyOwner() {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}