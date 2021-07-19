/**
 *Submitted for verification at Etherscan.io on 2021-07-19
*/

// (SPDX)-License-Identifier: GPL

pragma solidity ^0.8.0;

interface IRBAC {
  event RoleCreated(uint256 role);
  event BearerAdded(address indexed account, uint256 role);
  event BearerRemoved(address indexed account, uint256 role);

  function addRootRole(string calldata roleDescription) external returns(uint256);
  function removeBearer(address account, uint256 role) external;
  function addRole(string calldata roleDescription, uint256 admin) external returns(uint256);
  function totalRoles() external view returns(uint256);
  function hasRole(address account, uint256 role) external view returns(bool);
  function addBearer(address account, uint256 role) external;
}

// File: node_modules\@openzeppelin\contracts\utils\Context.sol


pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin\contracts\access\Ownable.sol

pragma solidity ^0.8.0;

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts\Manager.sol

pragma solidity ^0.8.0;



/**
  @title VNXManager
  @author Eugene Rupakov <[email protected]>
  @notice Implements runtime configurable Role Based Access Control, Contract Management.
*/
contract VNXManager is IRBAC, Ownable {
  /**
   * @dev Throws if called by any account other than the admin
   */
  modifier onlyAdmin() {
    require(isAdmin(), "RBAC: caller is not the admin");
    _;
  }

  /**
   * @dev Returns true if the caller is the admin role
   */
  function isAdmin() public view returns (bool) {
    return hasRole(msg.sender, 0);
  }

  function transferContractOwnership(address targetContract, address newOwner) onlyAdmin external returns(bool)
  {
    require(targetContract != address(0), "Target contract cannot be zero address");
    require(newOwner != address(0), "newOwner cannot be zero address");

    Ownable c = Ownable(targetContract);
    require(c.owner()!=newOwner, "New owner should differ from current");
    c.transferOwnership(newOwner);

    return true;
  }

  /**
   * @notice A role which will be used to group users.
   * @dev The role id is its position in the roles array.
   * @param description A description for the role.
   * @param admin The only role that can add or remove bearers from
   * this role. To have the role bearers to be also the role admins 
   * you should pass roles.length as the admin role.
   * @param bearers Addresses belonging to this role.
   * @param bearersCount total count of addresses belonging to this role.
   */
  struct Role {
    string description;
    uint256 admin;
    mapping (address => bool) bearers;
    uint256 bearersCount;
  }
  /**
   * @notice All roles ever created.
   */
  Role[] public roles;
  /**
   * @notice The contract constructor, empty as of now.
   */
  constructor() {
    addRootRole("Superadmin");
  }
  /**
   * @notice Create a new role that has itself as an admin. 
   * msg.sender is added as a bearer.
   * @param roleDescription The description of the role created.
   * @return The role id.
   */
  function addRootRole(string memory roleDescription)
    public override
    returns(uint256)
  {
    uint256 role = addRole(roleDescription, roles.length);
    roles[role].bearers[msg.sender] = true;
    roles[role].bearersCount++;
    emit BearerAdded(msg.sender, role);
    return role;
  }
  /**
   * @notice Create a new role.
   * @param roleDescription The description of the role created.
   * @param admin The role that is allowed to add and remove
   * bearers from the role being created.
   * @return The role id.
   */
  function addRole(string memory roleDescription, uint256 admin)
    public override
    returns(uint256)
  {
    require(admin <= roles.length, "Admin role doesn't exist.");
    Role storage r = roles.push();
    r.description = roleDescription;
    r.admin = admin;
    uint256 role = roles.length - 1;
    emit RoleCreated(role);
    return role;
  }
  /**
   * @notice Retrieve the number of roles in the contract.
   */
  function totalRoles()
    external override
    view
    returns(uint256)
  {
    return roles.length;
  }
  /**
   * @notice Verify whether an account is a bearer of a role
   * @param account The account to verify.
   * @param role The role to look into.
   * @return Whether the account is a bearer of the role.
   */
  function hasRole(address account, uint256 role)
    public override
    view
    returns(bool)
  {
    return role < roles.length && roles[role].bearers[account];
  }
  /**
   * @notice A method to add a bearer to a role
   * @param account The account to add as a bearer.
   * @param role The role to add the bearer to.
   */
  function addBearer(address account, uint256 role)
    external override
  {
    require(
      role < roles.length,
      "Role doesn't exist."
    );
    require(
      hasRole(msg.sender, roles[role].admin),
      "User can't add bearers."
    );
    require(
      !hasRole(account, role),
      "Account is bearer of role."
    );
    roles[role].bearers[account] = true;
    roles[role].bearersCount++;
    emit BearerAdded(account, role);
  }
  /**
   * @notice A method to remove a bearer from a role
   * @param account The account to remove as a bearer.
   * @param role The role to remove the bearer from.
   */
  function removeBearer(address account, uint256 role)
    external override
  {
    require(
      role < roles.length,
      "Role doesn't exist."
    );
    require(
      hasRole(msg.sender, roles[role].admin),
      "User can't remove bearers."
    );
    require(
      hasRole(account, role),
      "Account is not bearer of role."
    );
    if ( role == roles[role].admin && roles[role].bearersCount == 1) {
      revert("Cannot remove last role admin");
    }

    delete roles[role].bearers[account];
    roles[role].bearersCount--;
    emit BearerRemoved(account, role);
  }
}