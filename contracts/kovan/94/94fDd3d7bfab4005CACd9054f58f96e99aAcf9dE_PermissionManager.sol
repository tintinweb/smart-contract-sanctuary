pragma solidity 0.6.12;

import {IPermissionManager} from '../../interfaces/IPermissionManager.sol';
import {Ownable} from '../../dependencies/openzeppelin/contracts/Ownable.sol';

/**
 * @title PermissionManager contract
 * @notice Implements basic whitelisting functions for different actors of the permissioned protocol

 * @author Aave
 **/
contract PermissionManager is IPermissionManager, Ownable {
  mapping(address => uint256) _permissions;
  mapping(address => uint256) _permissionsAdmins;

  uint256 public constant MAX_NUM_OF_ROLES = 256;

  modifier onlyPermissionAdmins(address user) {
    require(_permissionsAdmins[user] > 0, 'CALLER_NOT_PERMISSIONS_ADMIN');
    _;
  }

  /**
   * @dev Allows owner to add new permission admins
   * @param users The addresses of the users to promote to permission admin
   **/
  function addPermissionAdmins(address[] calldata users) external override onlyOwner {
    for (uint256 i = 0; i < users.length; i++) {
      _permissionsAdmins[users[i]] = 1;

      emit PermissionsAdminSet(users[i], true);
    }
  }

  /**
   * @dev Allows owner to remove permission admins
   * @param users The addresses of the users to demote as permission admin
   **/
  function removePermissionAdmins(address[] calldata users) external override onlyOwner {
    for (uint256 i = 0; i < users.length; i++) {
      _permissionsAdmins[users[i]] = 0;

      emit PermissionsAdminSet(users[i], false);
    }
  }

  /**
   * @dev Allows permission admins to whitelist a set of addresses for multiple roles
   * @param roles The list of roles to assign to the different users
   * @param users The addresses of the users to assign to the corresponding role
   **/
  function addPermissions(uint256[] calldata roles, address[] calldata users)
    external
    override
    onlyPermissionAdmins(msg.sender)
  {
    require(roles.length == users.length, 'INCONSISTENT_ARRAYS_LENGTH');

    for (uint256 i = 0; i < users.length; i++) {
      uint256 role = roles[i];

      require(role < MAX_NUM_OF_ROLES, 'INVALID_ROLE');

      uint256 permissions = _permissions[users[i]];
      _permissions[users[i]] = permissions | (1 << role);

      emit RoleSet(users[i], roles[i], true);
    }
  }

  /**
   * @dev Allows owner to remove permissions on a set of addresses for multiple roles
   * @param roles The list of roles
   * @param users The addresses of the users
   **/
  function removePermissions(uint256[] calldata roles, address[] calldata users)
    external
    override
    onlyPermissionAdmins(msg.sender)
  {
    require(roles.length == users.length, 'INCONSISTENT_ARRAYS_LENGTH');

    for (uint256 i = 0; i < users.length; i++) {
      uint256 role = roles[i];

      require(role < MAX_NUM_OF_ROLES, 'INVALID_ROLE');

      uint256 permissions = _permissions[users[i]];
      _permissions[users[i]] = permissions & ~(1 << role);
      emit RoleSet(users[i], roles[i], false);
    }
  }

  /**
   * @dev Returns the permissions configuration for a specific account
   * @param account The address of the user
   * @return the set of permissions states for the account
   **/
  function getAccountPermissions(address account)
    external
    view
    override
    returns (uint256[] memory, uint256)
  {
    uint256[] memory roles = new uint256[](256);
    uint256 rolesCount = 0;
    uint256 accountPermissions = _permissions[account];

    for (uint256 i = 0; i < 256; i++) {
      if ((accountPermissions >> i) & 1 > 0) {
        roles[rolesCount] = i;
        rolesCount++;
      }
    }

    return (roles, rolesCount);
  }

  /**
   * @dev Used to query if a certain account is a depositor
   * @param account The address of the user
   * @return True if the account is a depositor, false otherwise
   **/
  function isInRole(address account, uint256 role) public view override returns (bool) {
    return (_permissions[account] >> role) & 1 > 0;
  }

  /**
   * @dev Used to query if a certain account is a depositor
   * @param account The address of the user
   * @return True if the account is a depositor, false otherwise
   **/
  function isPermissionsAdmin(address account) public view override returns (bool) {
    return _permissionsAdmins[account] > 0;
  }
}

pragma solidity 0.6.12;

interface IPermissionManager {

  event RoleSet(address indexed user, uint256 indexed role, bool set);
  event PermissionsAdminSet(address indexed user, bool set);

  /**
   * @dev Allows owner to add new permission admins
   * @param users The addresses of the users to promote to permission admin
   **/
  function addPermissionAdmins(address[] calldata users) external;

  /**
   * @dev Allows owner to remove permission admins
   * @param users The addresses of the users to demote as permission admin
   **/
  function removePermissionAdmins(address[] calldata users) external;

  /**
   * @dev Allows owner to whitelist a set of addresses for multiple roles
   * @param roles The list of roles to assign
   * @param users The list of users to add to the corresponding role
   **/
  function addPermissions(uint256[] calldata roles, address[] calldata users) external;

  /**
   * @dev Allows owner to remove permissions on a set of addresses
   * @param roles The list of roles to remove
   * @param users The list of users to remove from the corresponding role
   **/
  function removePermissions(uint256[] calldata roles, address[] calldata users) external;

  /**
   * @dev Returns the permissions configuration for a specific account
   * @param account The address of the user
   * @return the set of permissions states for the account
   **/
  function getAccountPermissions(address account) external view returns (uint256[] memory, uint256);

  /**
   * @dev Used to query if a certain account has a certain role
   * @param account The address of the user
   * @return True if the account is in the specific role
   **/
  function isInRole(address account, uint256 role) external view returns (bool);

  /**
   * @dev Used to query if a certain account has the permissions admin role
   * @param account The address of the user
   * @return True if the account is a permissions admin, false otherwise
   **/
  function isPermissionsAdmin(address account) external view returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './Context.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
    _;
  }

  /**
   * @dev Leaves the contract without owner. It will not be possible to call
   * `onlyOwner` functions anymore. Can only be called by the current owner.
   *
   * NOTE: Renouncing ownership will leave the contract without an owner,
   * thereby removing any functionality that is only available to the owner.
   */
  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

