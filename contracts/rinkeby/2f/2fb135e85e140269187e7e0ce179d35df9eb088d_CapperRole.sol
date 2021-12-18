/**
 *Submitted for verification at Etherscan.io on 2021-12-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = true;
  }

  /**
   * @dev remove an account's access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * return bool
   */
  function has(Role storage role, address account)
  internal
  view
  returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

contract CapperRole {
  using Roles for Roles.Role;

  event CapperAdded(address indexed account);
  event CapperRemoved(address indexed account);

  Roles.Role private cappers;

  constructor() {
    cappers.add(msg.sender);
  }

  modifier onlyCapper() {
    require(isCapper(msg.sender));
    _;
  }

  function isCapper(address account) public view returns (bool) {
    return cappers.has(account);
  }

  function addCapper(address account) public onlyCapper {
    cappers.add(account);
    emit CapperAdded(account);
  }

  function renounceCapper() public {
    cappers.remove(msg.sender);
  }

  function _removeCapper(address account) internal {
    cappers.remove(account);
    emit CapperRemoved(account);
  }
}