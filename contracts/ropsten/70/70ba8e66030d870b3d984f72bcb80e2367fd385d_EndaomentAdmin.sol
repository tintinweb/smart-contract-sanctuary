/**
 *Submitted for verification at Etherscan.io on 2022-01-20
*/

// SPDX-License-Identifier: BSD 3-Clause

pragma solidity ^0.6.10;

/**
 * @dev Interface of the EndaomentAdmin contract
 */
interface IEndaomentAdmin {
  event RoleModified(Role indexed role, address account);
  event RolePaused(Role indexed role);
  event RoleUnpaused(Role indexed role);

  enum Role {
    EMPTY,
    PAUSER,
    ACCOUNTANT,
    REVIEWER,
    FUND_FACTORY,
    ORG_FACTORY,
    ADMIN
  }

  struct RoleStatus {
    address account;
    bool paused;
  }

  function setRole(Role role, address account) external;

  function removeRole(Role role) external;

  function pause(Role role) external;

  function unpause(Role role) external;

  function isPaused(Role role) external view returns (bool);

  function isRole(Role role) external view returns (bool);

  function getRoleAddress(Role role) external view returns (address);
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 *
 * In order to transfer ownership, a recipient must be specified, at which point
 * the specified recipient can call `acceptOwnership` and take ownership.
 */
contract TwoStepOwnable {
  address private _owner;
  address private _newPotentialOwner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  event TransferInitiated(address indexed newOwner);

  event TransferCancelled(address indexed newPotentialOwner);

  /**
   * @dev Initialize contract by setting transaction submitter as initial owner.
   */
  constructor() internal {
    _owner = tx.origin;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function getOwner() external view returns (address) {
    return _owner;
  }

  /**
   * @dev Returns the address of the current potential new owner.
   */
  function getNewPotentialOwner() external view returns (address) {
    return _newPotentialOwner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner(), "TwoStepOwnable: caller is not the owner.");
    _;
  }

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows a new account (`newOwner`) to accept ownership.
   * Can only be called by the current owner.
   */
  function transferOwnership(address newPotentialOwner) public onlyOwner {
    require(
      newPotentialOwner != address(0),
      "TwoStepOwnable: new potential owner is the zero address."
    );

    _newPotentialOwner = newPotentialOwner;
    emit TransferInitiated(address(newPotentialOwner));
  }

  /**
   * @dev Cancel a transfer of ownership to a new account.
   * Can only be called by the current owner.
   */
  function cancelOwnershipTransfer() public onlyOwner {
    emit TransferCancelled(address(_newPotentialOwner));
    delete _newPotentialOwner;
  }

  /**
   * @dev Transfers ownership of the contract to the caller.
   * Can only be called by a new potential owner set by the current owner.
   */
  function acceptOwnership() public {
    require(
      msg.sender == _newPotentialOwner,
      "TwoStepOwnable: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    emit OwnershipTransferred(_owner, msg.sender);

    _owner = msg.sender;
  }
}

/**
 * @title EndaomentAdmin
 * @author rheeger
 * @notice Provides admin controls for the Endaoment contract ecosystem using
 * a roles-based system. Available roles are PAUSER (1), ACCOUNTANT (2),
 * REVIEWER (3), FUND_FACTORY (4), ORG_FACTORY (5), and ADMIN (6).
 */
contract EndaomentAdmin is IEndaomentAdmin, TwoStepOwnable {
  // Maintain a role status mapping with assigned accounts and paused states.
  mapping(uint256 => RoleStatus) private _roles;

  /**
   * @notice Set a new account on a given role and emit a `RoleModified` event
   * if the role holder has changed. Only the owner may call this function.
   * @param role The role that the account will be set for.
   * @param account The account to set as the designated role bearer.
   */
  function setRole(Role role, address account) public override onlyOwner {
    require(account != address(0), "EndaomentAdmin: Must supply an account.");
    _setRole(role, account);
  }

  /**
   * @notice Remove any current role bearer for a given role and emit a
   * `RoleModified` event if a role holder was previously set. Only the owner
   * may call this function.
   * @param role The role that the account will be removed from.
   */
  function removeRole(Role role) public override onlyOwner {
    _setRole(role, address(0));
  }

  /**
   * @notice Pause a currently unpaused role and emit a `RolePaused` event. Only
   * the owner or the designated pauser may call this function. Also, bear in
   * mind that only the owner may unpause a role once paused.
   * @param role The role to pause.
   */
  function pause(Role role) public override onlyAdminOr(Role.PAUSER) {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];
    require(!storedRoleStatus.paused, "EndaomentAdmin: Role in question is already paused.");
    storedRoleStatus.paused = true;
    emit RolePaused(role);
  }

  /**
   * @notice Unpause a currently paused role and emit a `RoleUnpaused` event.
   * Only the owner may call this function.
   * @param role The role to pause.
   */
  function unpause(Role role) public override onlyOwner {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];
    require(storedRoleStatus.paused, "EndaomentAdmin: Role in question is already unpaused.");
    storedRoleStatus.paused = false;
    emit RoleUnpaused(role);
  }

  /**
   * @notice External view function to check whether or not the functionality
   * associated with a given role is currently paused or not. The owner or the
   * pauser may pause any given role (including the pauser itself), but only the
   * owner may unpause functionality. Additionally, the owner may call paused
   * functions directly.
   * @param role The role to check the pause status on.
   * @return A boolean to indicate if the functionality associated with
   * the role in question is currently paused.
   */
  function isPaused(Role role) external override view returns (bool) {
    return _isPaused(role);
  }

  /**
   * @notice External view function to check whether the caller is the current
   * role holder.
   * @param role The role to check for.
   * @return A boolean indicating if the caller has the specified role.
   */
  function isRole(Role role) external override view returns (bool) {
    return _isRole(role);
  }

  /**
   * @notice External view function to check the account currently holding the
   * given role.
   * @param role The desired role to fetch the current address of.
   * @return The address of the requested role, or the null
   * address if none is set.
   */
  function getRoleAddress(Role role) external override view returns (address) {
    require(
      _roles[uint256(role)].account != address(0),
      "EndaomentAdmin: Role bearer is null address."
    );
    return _roles[uint256(role)].account;
  }

  /**
   * @notice Private function to set a new account on a given role and emit a
   * `RoleModified` event if the role holder has changed.
   * @param role The role that the account will be set for.
   * @param account The account to set as the designated role bearer.
   */
  function _setRole(Role role, address account) private {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];

    if (account != storedRoleStatus.account) {
      storedRoleStatus.account = account;
      emit RoleModified(role, account);
    }
  }

  /**
   * @notice Private view function to check whether the caller is the current
   * role holder.
   * @param role The role to check for.
   * @return A boolean indicating if the caller has the specified role.
   */
  function _isRole(Role role) private view returns (bool) {
    return msg.sender == _roles[uint256(role)].account;
  }

  /**
   * @notice Private view function to check whether the given role is paused or
   * not.
   * @param role The role to check for.
   * @return A boolean indicating if the specified role is paused or not.
   */
  function _isPaused(Role role) private view returns (bool) {
    return _roles[uint256(role)].paused;
  }

  /**
   * @notice Modifier that throws if called by any account other than the owner
   * or the supplied role, or if the caller is not the owner and the role in
   * question is paused.
   * @param role The role to require unless the caller is the owner.
   */
  modifier onlyAdminOr(Role role) {
    if (!isOwner()) {
      require(_isRole(role), "EndaomentAdmin: Caller does not have a required role.");
      require(!_isPaused(role), "EndaomentAdmin: Role in question is currently paused.");
    }
    _;
  }
}