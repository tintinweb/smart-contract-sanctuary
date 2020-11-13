// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/// @title Mintable
///
/// @notice This contract covers everything related
/// to the mint functions
///
contract Minteable {
  /// @dev Declare a private bool {_mintingEnabled}
  ///
  bool private _mintingEnabled;

  /// @dev Declare a public constant of type bytes32
  ///
  /// @return The bytes32 string of the role
  ///
  bytes32 public constant ROLE_MINTER = keccak256("MINTER");

  /// @dev Declare two events to expose when minting
  /// is enabled or disabled, take the event's sender
  /// as argument
  ///
  event MintingEnabled(address indexed _from);
  event MintingDisabled(address indexed _from);

  /// @dev Verify if the sender can mint, if yes,
  /// enable minting
  /// 
  /// Requirements:
  /// {_hasRole} should be true
  /// {_amount} should be superior to 0
  /// {_mintingEnabled} should be true
  ///
  modifier isMintable(
    uint256 _amount,
    bool _hasRole
  ) {
    require(
      _hasRole,
      "MC:500"
    );

    require(
      _amount > 0,
      "MC:30"
    );

    _enableMinting();

    require(
      mintingEnabled(),
      "MC:110"
    );
    _;
  }

  /// @dev By default, minting is disabled
  ///
  constructor()
  internal {
    _mintingEnabled = false;
  }

  /// @notice Expose the state of {_mintingEnabled}
  ///
  /// @return The state as a bool
  ///
  function mintingEnabled()
  public view returns (bool) {
    return _mintingEnabled;
  }

  /// @dev Enable minting by setting {_mintingEnabled}
  /// to true, then emit the related event
  ///
  function _enableMinting()
  internal virtual {
    _mintingEnabled = true;
    emit MintingEnabled(msg.sender);
  }

  /// @dev Disable minting by setting {_mintingEnabled}
  /// to false, then emit the related event
  ///
  function _disableMinting()
  internal virtual {
    _mintingEnabled = false;
    emit MintingDisabled(msg.sender);
  }
}