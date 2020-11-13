// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/// @title Burneable
///
/// @notice This contract covers everything related
/// to the burn functions
///
contract Burneable {
  /// @dev Declare a private bool {_burningEnabled}
  ///
  bool private _burningEnabled;

  /// @dev Declare a public constant of type bytes32
  ///
  /// @return The bytes32 string of the role
  ///
  bytes32 public constant ROLE_BURNER = keccak256("BURNER");

  /// @dev Declare two events to expose when burning
  /// is enabled or disabled, take the event's sender
  /// as argument
  ///
  event BurningEnabled(address indexed _from);
  event BurningDisabled(address indexed _from);

  /// @dev Verify if the sender can burn, if yes,
  /// enable burning
  /// 
  /// Requirements:
  /// {_hasRole} should be true
  /// {_amount} should be superior to 0
  /// {_burningEnabled} should be true
  ///
  modifier isBurneable(
    uint256 _amount,
    bool _hasRole
  ) {
    require(
      _hasRole,
      "BC:500"
    );

    require(
      _amount > 0,
      "BC:30"
    );

    _enableBurning();

    require(
      burningEnabled(),
      "BC:210"
    );
    _;
  }

  /// @dev By default, burning is disabled
  ///
  constructor()
  internal {
    _burningEnabled = false;
  }

  /// @notice Expose the state of {_burningEnabled}
  ///
  /// @return The state as a bool
  ///
  function burningEnabled()
  public view returns (bool) {
    return _burningEnabled;
  }

  /// @dev Enable burning by setting {_burningEnabled}
  /// to true, then emit the related event
  ///
  function _enableBurning()
  internal virtual {
    _burningEnabled = true;
    emit BurningEnabled(msg.sender);
  }

  /// @dev Disable burning by setting {_burningEnabled}
  /// to false, then emit the related event
  ///
  function _disableBurning()
  internal virtual {
    _burningEnabled = false;
    emit BurningDisabled(msg.sender);
  }
}
