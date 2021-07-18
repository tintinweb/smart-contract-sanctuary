/**
 *Submitted for verification at Etherscan.io on 2021-07-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 *      See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

  /**
   * @dev remove an address' access to this role
   */
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr), "Illegal user rights");
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}


library RBAC
{
    using Roles for Roles.Role;

    struct RolesManager
    {
        mapping (string => Roles.Role)  userRoles;
        address owner;
        bool isInit;
    }

    event RoleAdded(address addr, string roleName);
    event RoleRemoved(address addr, string roleName);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function initialize(RolesManager storage rolesManager, address _owner) internal
    {
        rolesManager.owner = _owner;
        rolesManager.userRoles["admin"].add(msg.sender);
        rolesManager.userRoles["mint"].add(msg.sender);
        addRole(rolesManager, _owner, "admin");
        addRole(rolesManager, _owner, "mint");
        addRole(rolesManager, _owner, "burn");
        addRole(rolesManager, _owner, "frozen");
        addRole(rolesManager, _owner, "pause");
    }

    modifier onlyAdmin(RolesManager storage rolesManager)
    {
        require(isAdmin(rolesManager), "Adminable: caller is not the admin");
        _;
    }

    function isOwner(RolesManager storage rolesManager) internal view returns(bool)
    {
        return (msg.sender == rolesManager.owner);
    }

    function isAdmin(RolesManager storage rolesManager) internal view returns(bool)
    {
        return hasRole(rolesManager, msg.sender, "admin") || msg.sender == rolesManager.owner;
    }

    /**
    * @dev reverts if addr does not have role
    * @param addr address
    * @param roleName the name of the role
    * // reverts
    */
    function checkRole(RolesManager storage rolesManager, address addr, string memory roleName) internal view
    {
        rolesManager.userRoles[roleName].check(addr);
    }

    /**
    * @dev determine if addr has role
    * @param addr address
    * @param roleName the name of the role
    * @return bool
    */
    function hasRole(RolesManager storage rolesManager, address addr, string memory roleName) internal view returns (bool)
    {
        return rolesManager.userRoles[roleName].has(addr);
    }

    /**
    * @dev add a role to an address
    * @param addr address
    * @param roleName the name of the role
    */
    function addRole(RolesManager storage rolesManager, address addr, string memory roleName) internal onlyAdmin(rolesManager)
    {
        rolesManager.userRoles[roleName].add(addr);
        emit RoleAdded(addr, roleName);
    }

    /**
    * @dev remove a role from an address
    * @param addr address
    * @param roleName the name of the role
    */
    function removeRole(RolesManager storage rolesManager, address addr, string memory roleName) internal onlyAdmin(rolesManager)
    {
        rolesManager.userRoles[roleName].remove(addr);
        emit RoleRemoved(addr, roleName);
    }

    function setOwner(RolesManager storage rolesManager, address newOwner) private onlyAdmin(rolesManager) {
        address oldOwner = rolesManager.owner;
        rolesManager.owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /** set owner null
     */
    function renounceOwnership(RolesManager storage rolesManager)  internal
    {
        setOwner(rolesManager, address(0));
    }

    /* transfer owner */
    function transferOwnership(RolesManager storage rolesManager, address newOwner) internal
    {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        setOwner(rolesManager, newOwner);
    }
}