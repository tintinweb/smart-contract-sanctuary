pragma solidity ^0.4.18;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

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
   * @dev remove an address&#39; access to this role
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
    require(has(role, addr));
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


/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 *      Supports unlimited numbers of roles and addresses.
 *      See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 *  for you to write your own implementation of this interface using Enums or similar.
 * It&#39;s also recommended that you define constants in the contract, like ROLE_ADMIN below,
 *  to avoid typos.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

  /**
   * A constant role name for indicating admins.
   */
  string public constant ROLE_ADMIN = &quot;admin&quot;;

  /**
   * @dev constructor. Sets msg.sender as admin by default
   */
  function RBAC()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
  }

  /**
   * @dev reverts if addr does not have role
   * @param addr address
   * @param roleName the name of the role
   * // reverts
   */
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

  /**
   * @dev determine if addr has role
   * @param addr address
   * @param roleName the name of the role
   * @return bool
   */
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
  {
    addRole(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
  {
    removeRole(addr, roleName);
  }

  /**
   * @dev add a role to an address
   * @param addr address
   * @param roleName the name of the role
   */
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    RoleAdded(addr, roleName);
  }

  /**
   * @dev remove a role from an address
   * @param addr address
   * @param roleName the name of the role
   */
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    RoleRemoved(addr, roleName);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param roleName the name of the role
   * // reverts
   */
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

  /**
   * @dev modifier to scope access to admins
   * // reverts
   */
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param roleNames the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] roleNames) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < roleNames.length; i++) {
  //         if (hasRole(msg.sender, roleNames[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

contract MultiUser is Ownable, RBAC {

    string public constant ROLE_ACCESS_ADDRESS = &quot;access-address&quot;;

    event adminTransferredEvent(address indexed previousAdmin, address indexed newAdmin);

    function MultiUser() public {
        addRole(msg.sender, ROLE_ACCESS_ADDRESS);
    }

    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        adminTransferredEvent(owner, newAdmin);
        addRole(newAdmin, ROLE_ADMIN);
        addRole(newAdmin, ROLE_ACCESS_ADDRESS);
        removeRole(owner, ROLE_ACCESS_ADDRESS);
        removeRole(owner, ROLE_ADMIN);
        transferOwnership(newAdmin);
    }

    modifier onlyAccessAddress()
    {
        checkRole(msg.sender, ROLE_ACCESS_ADDRESS);
        _;
    }
}

contract AccountStorage is MultiUser {

    struct Account {
        uint id;
        uint16 hashType;
        bytes32 hash;
        uint amount;
    }

    mapping(uint => Account) public accountList;

    event addAccountEvent(uint indexed _id, uint16 _hashType, bytes32 _hash, uint _amount, address _sender);
    event updateAccountEvent(
        uint indexed _id,
        uint16 _oldHashType,
        uint16 _hashType,
        bytes32 _oldHash,
        bytes32 _hash,
        uint _oldAmount,
        uint _amount,
        uint16 _reasonUpdateHashType,
        bytes32 _reasonUpdateHash,
        address _sender
    );
    event updateAccountAmountEvent(uint indexed _id, uint _oldAmount, uint _amount, address _sender);

    function addAccount(
        uint _id,
        uint16 _hashType,
        bytes32 _hash,
        uint _amount
    ) external onlyAccessAddress {
        require(accountList[_id].id == 0);
        accountList[_id] = Account(_id, _hashType, _hash, _amount);
        addAccountEvent(_id, _hashType, _hash, _amount, msg.sender);
    }

    function updateAccountData(
        uint _id,
        uint16 _hashType,
        bytes32 _hash,
        uint _amount,
        uint16 _reasonUpdateHashType,
        bytes32 _reasonUpdateHash
    ) external onlyAccessAddress {
        require(accountList[_id].id != 0);
        uint16 oldHashType = accountList[_id].hashType;
        bytes32 oldHash = accountList[_id].hash;
        uint oldAmount = accountList[_id].amount;
        if (oldHashType != _hashType) {
            accountList[_id].hashType = _hashType;
        }
        if (oldHash != _hash) {
            accountList[_id].hash = _hash;
        }
        if (oldAmount != _amount) {
            accountList[_id].amount = _amount;
            updateAccountAmountEvent(_id, oldAmount, _amount, msg.sender);
        }
        updateAccountEvent(_id, oldHashType, _hashType, oldHash, _hash, oldAmount, _amount, _reasonUpdateHashType, _reasonUpdateHash, msg.sender);
    }

    function updateAccountAmount(uint _id, uint _amount) external onlyAccessAddress {
        require(accountList[_id].id != 0);
        uint oldAmount = accountList[_id].amount;
        if (oldAmount != _amount) {
            accountList[_id].amount = _amount;
            updateAccountAmountEvent(_id, oldAmount, _amount, msg.sender);
        }
    }

    function existAccount(
        uint _id
    ) public view returns (bool) {
        return accountList[_id].id != 0;
    }

    function getAccountAmount(
        uint _id
    ) public view returns (uint amount) {
        return accountList[_id].amount;
    }
}