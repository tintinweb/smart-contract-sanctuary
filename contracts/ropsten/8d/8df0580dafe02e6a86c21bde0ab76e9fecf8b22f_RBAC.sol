pragma solidity 0.4.24;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

// File: contracts/RBACInterface.sol

/// @title RBACInterface
/// @notice The interface for Role-Based Access Control.
contract RBACInterface {
    function hasRole(address addr, string role) public view returns (bool);
}

// File: contracts/RBAC.sol

/// @title RBAC
/// @notice A simple implementation of Role-Based Access Control.
contract RBAC is RBACInterface, Ownable {

    string constant ROLE_ADMIN = "rbac__admin";

    mapping(address => mapping(string => bool)) internal roles;

    event RoleAdded(address indexed addr, string role);
    event RoleRemoved(address indexed addr, string role);

    /// @notice Check if an address has a role.
    /// @param addr The address.
    /// @param role The role.
    /// @return A boolean indicating whether the address has the role.
    function hasRole(address addr, string role) public view returns (bool) {
        return roles[addr][role];
    }

    /// @notice Add a role to an address. Only the owner or an admin can add a
    /// role.
    /// @dev Requires caller to be the owner or have the role "rbac__admin".
    /// @param addr The address.
    /// @param role The role.
    function addRole(address addr, string role) public onlyOwnerOrAdmin {
        roles[addr][role] = true;
        emit RoleAdded(addr, role);
    }

    /// @notice Remove a role from an address. Only the owner or an admin can
    /// remove a role.
    /// @dev Requires caller to be the owner or have the role "rbac__admin".
    /// @param addr The address.
    /// @param role The role.
    function removeRole(address addr, string role) public onlyOwnerOrAdmin {
        roles[addr][role] = false;
        emit RoleRemoved(addr, role);
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || hasRole(msg.sender, ROLE_ADMIN), "Access denied: missing role");
        _;
    }
}