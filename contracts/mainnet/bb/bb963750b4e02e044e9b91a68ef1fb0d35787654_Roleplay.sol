// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./EnumerableSet.sol";

/// @title Roleplay
///
/// @notice This contract covers most functions about
/// role and permission's managment
///
abstract contract Roleplay {
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @dev Structure declaration of {RoleData} data model
  ///
  struct RoleData {
    EnumerableSet.AddressSet members;
    bytes32 ownerRole;
  }

  mapping (bytes32 => RoleData) private _roles;

  /// @dev Declare a public constant of type bytes32
  ///
  /// @return The bytes32 string of the role
  ///
  bytes32 public constant ROLE_OWNER = 0x00;

  /// @dev Declare a public constant of type bytes32
  ///
  /// @return The bytes32 string of the role
  ///
  bytes32 public constant ROLE_MANAGER = keccak256("MANAGER");

  /// @dev Declare two events to expose role
  /// modifications
  ///
  event RoleGranted(bytes32 indexed _role, address indexed _from, address indexed _sender);
  event RoleRevoked(bytes32 indexed role, address indexed _from, address indexed _sender);

  /// @dev Verify if the sender have Owner's role
  /// 
  /// Requirements:
  /// {_hasRole()} should be true
  ///
  modifier onlyOwner() {
    require(
      hasRole(ROLE_OWNER, msg.sender),
      "RPC:500"
    );
    _;
  }

  /// @notice This function verify is the {_account}
  /// has role {_role}
  ///
  /// @param _role - The bytes32 string of the role
  /// @param _account - The address to verify
  ///
  /// @return true/false depending the result 
  ///
  function hasRole(
    bytes32 _role,
    address _account
  ) public view returns (bool) {
    return _roles[_role].members.contains(_account);
  }

  /// @notice Expose the length of members[] for
  /// a given {_role}
  ///
  /// @param _role - The bytes32 string of the role
  ///
  /// @return - The length of members
  ///
  function getRoleMembersLength(
    bytes32 _role
  ) public view returns (uint256) {
    return _roles[_role].members.length();
  }


  /// @notice Expose the member address for
  /// a given {_role} at the {_id} index
  ///
  /// @param _id - Index to watch for
  /// @param _role - The bytes32 string of the role
  ///
  /// @return - The address of the member at {_id} index
  ///
  function exposeRoleMember(
    bytes32 _role,
    uint256 _id
  ) public view returns (address) {
    return _roles[_role].members.at(_id);
  }

  /// @notice This function allow the current Owner
  /// to transfer his ownership
  ///
  /// @dev Requirements:
  /// See {Roleplay::onlyOwner()}
  ///
  /// @param _to - Represent address of the receiver
  ///
  function transferOwnerRole(
    address _to
  ) public virtual onlyOwner() {
    _grantRole(ROLE_OWNER, _to);
    _revokeRole(ROLE_OWNER, msg.sender);
  }

  /// @notice This function allow the current Owner
  /// to give the Manager Role to {_to} address
  ///
  /// @dev Requirements:
  /// See {Roleplay::onlyOwner()}
  ///
  /// @param _to - Represent address of the receiver
  ///
  function grantManagerRole(
    address _to
  ) public virtual onlyOwner() {
    _grantRole(ROLE_MANAGER, _to);
  }

  /// @notice This function allow a Manager to grant
  /// role to a given address, it can't grant Owner role
  ///
  /// @dev Requirements:
  /// {_hasRole()} should be true
  /// {_role} should be different of ROLE_OWNER
  ///
  /// @param _role - The bytes32 string of the role
  /// @param _to - Represent address of the receiver
  ///
  function grantRole(
    bytes32 _role,
    address _to
  ) public virtual {
    require(
      hasRole(ROLE_MANAGER, msg.sender),
      "RPC:510"
    );

    require(
      _role != ROLE_OWNER,
      "RPC:520"
    );

    if (!hasRole(ROLE_OWNER, msg.sender)) {
      require(
        _role == keccak256("CHAIRPERSON"),
        "RPC:530"
      );
    }

    _grantRole(_role, _to);
  }

  /// @notice This function allow a Manager to revoke
  /// role to a given address, it can't revoke Owner role
  ///
  /// @dev Requirements:
  /// {_hasRole()} should be true
  /// {_role} should be different of ROLE_OWNER
  ///
  /// @param _role - The bytes32 string of the role
  /// @param _to - Represent address of the receiver
  ///
  function revokeRole(
    bytes32 _role,
    address _to
  ) public virtual {
    require(
      hasRole(ROLE_MANAGER, msg.sender),
      "RPC:550"
    );

    require(
      _role != ROLE_OWNER,
      "RPC:540"
    );

    if (!hasRole(ROLE_OWNER, msg.sender)) {
      require(
        _role == keccak256("CHAIRPERSON"),
        "RPC:530"
      );
    }

    _revokeRole(_role, _to);
  }

  /// @notice This function allow anyone to revoke his
  /// own role, even an Owner, use it carefully!
  ///
  /// @param _role - The bytes32 string of the role
  ///
  function renounceRole(
    bytes32 _role
  ) public virtual {
    require(
      _role != ROLE_OWNER,
      "RPC:540"
    );

    require(
      hasRole(_role, msg.sender),
      "RPC:570"
    );

    _revokeRole(_role, msg.sender);
  }

  function _setupRole(
    bytes32 _role,
    address _to
  ) internal virtual {
    _grantRole(_role, _to);
  }

  function _grantRole(
    bytes32 _role,
    address _to
  ) private {
    if (_roles[_role].members.add(_to)) {
      emit RoleGranted(_role, _to, msg.sender);
    }
  }

  function _revokeRole(
    bytes32 _role,
    address _to
  ) private {
    if (_roles[_role].members.remove(_to)) {
      emit RoleRevoked(_role, _to, msg.sender);
    }
  }
}