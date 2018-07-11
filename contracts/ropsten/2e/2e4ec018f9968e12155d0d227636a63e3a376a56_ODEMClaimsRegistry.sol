pragma solidity ^0.4.23;

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
    emit OwnershipTransferred(owner, newOwner);
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
 * @dev Supports unlimited numbers of roles and addresses.
 * @dev See //contracts/mocks/RBACMock.sol for an example of usage.
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
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
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
    emit RoleRemoved(addr, roleName);
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

/**
 * @title RBACWithAdmin
 * @author Matt Condon (@Shrugs)
 * @dev It&#39;s recommended that you define constants in the contract,
 * @dev like ROLE_ADMIN below, to avoid typos.
 */
contract RBACWithAdmin is RBAC {
  /**
   * A constant role name for indicating admins.
   */
  string public constant ROLE_ADMIN = &quot;admin&quot;;
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
   * @dev constructor. Sets msg.sender as admin by default
   */
  function RBACWithAdmin()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
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
}

contract RBACManaged is Ownable {
  RBAC rbac;
  constructor(address _rbacAddr) public {
    rbac = RBAC(_rbacAddr);
  }
  function roleAdmin() internal pure returns (string);
  function hasRole(address addr, string role) public view returns (bool) {
    return rbac.hasRole(addr, role);
  }
  function checkRole(address addr, string role) public view {
    require(hasRole(addr, role));
  }
  modifier onlyRole(string role) {
    checkRole(msg.sender, role);
    _;
  }
  modifier onlyOwnerOrAdmin() {
    require(msg.sender == owner || hasRole(msg.sender, roleAdmin()));
    _;
  }
  function setRBACAddress(address addr) public onlyOwnerOrAdmin {
    rbac = RBAC(addr);
  }
}

contract UserAddressAliasable is RBACManaged {
    // TODO Events? Tree compression might make it weird
    mapping(address => address) addressAlias;  // Oldest address is canonical
    function roleAddressAliaser() internal pure returns (string);
    function addAddressAlias(address oldAddr, address newAddr) public onlyRole(roleAddressAliaser()) {
        require(addressAlias[newAddr] == address(0));
        address resolved = resolveAddress(oldAddr);
        require(resolved != newAddr);  // Detect cycles
        addAddressAliasUnsafe(resolved, newAddr);
    }
    function addAddressAliasUnsafe(address oldAddr, address newAddr) public onlyRole(roleAddressAliaser()) {
        addressAlias[newAddr] = resolveAddress(oldAddr);
    }
    // NOT a view! It compresses the tree
    function resolveAddress(address addr) public returns (address) {
        address nextAddr = addressAlias[addr];  // Keep it on the stack
        if (nextAddr == address(0)) {
            return addr;
        } else {
            address finalAddr = resolveAddress(nextAddr);
            if (finalAddr != nextAddr) {
                // Only write if necessary
                addressAlias[addr] = finalAddr;
            }
            return finalAddr;
        }
    }
    function resolveAddressLight(address addr) public view returns (address) {
        address nextAddr = addressAlias[addr];
        while (nextAddr != address(0)) {
            addr = nextAddr;
            nextAddr = addressAlias[addr];
        }
        return addr;
    }
}

contract ODEMClaimsRegistry is RBACManaged, UserAddressAliasable {

  string constant ROLE_ADMIN = &quot;claims__admin&quot;;
  string constant ROLE_ISSUER = &quot;claims__issuer&quot;;
  string constant ROLE_ADDRESS_ALIASER = &quot;claims__address_aliaser&quot;;

  struct Claim {
    bytes uri;
    bytes32 hash;
  }

  // subject => key => claim
  mapping(address => mapping(bytes32 => Claim)) internal claims;

  mapping(address => bool) internal hasClaims;
  // Used for safe address aliasing. Never reset to false.

  event ClaimSet(
    address indexed issuer,
    address indexed subject,
    bytes32 indexed key,
    bytes32 value,
    uint updatedAt
  );

  event ClaimRemoved(
    address indexed issuer,
    address indexed subject,
    bytes32 indexed key,
    uint removedAt
  );

  constructor(address rbacAddr) RBACManaged(rbacAddr) public {
    owner = msg.sender;
    rbac = RBAC(rbacAddr);
  }
  function roleAdmin() internal pure returns (string) {
    return ROLE_ADMIN;
  }
  function roleAddressAliaser() internal pure returns (string) {
    return ROLE_ADDRESS_ALIASER;
  }
  function getODEMClaim(address subject, bytes32 key) public view returns (bytes uri, bytes32 hash) {
    return (claims[subject][key].uri, claims[subject][key].hash);
  }
  
  function setODEMClaim(address subject, bytes32 key, bytes uri, bytes32 hash) public onlyRole(ROLE_ISSUER) {
    claims[subject][key].uri = uri;
    claims[subject][key].hash = hash;
    hasClaims[subject] = true;
    emit ClaimSet(msg.sender, subject, key, hash, now);
  }
  function removeODEMClaim(address subject, bytes32 key) public {
    require(hasRole(msg.sender, ROLE_ISSUER) || msg.sender == subject);
    delete claims[subject][key];
    emit ClaimRemoved(msg.sender, subject, key, now);
  }
  function addAddressAlias(address oldAddr, address newAddr) public onlyRole(ROLE_ADDRESS_ALIASER) {
    require(!hasClaims[newAddr]);
    super.addAddressAlias(oldAddr, newAddr);
  }
  // ERC780 interface
  function getClaim(address issuer, address subject, bytes32 key) public view returns (bytes32) {
    if (hasRole(issuer, ROLE_ISSUER)) {
      return claims[subject][key].hash;
    } else {
      return bytes32(0);
    }
  }
  function setClaim(address subject, bytes32 key, bytes32 value) public {
    revert();
  }
  function setSelfClaim(bytes32 key, bytes32 value) public {
    revert();
  }
  function removeClaim(address issuer, address subject, bytes32 key) public {
    require(hasRole(issuer, ROLE_ISSUER));
    removeODEMClaim(subject, key);
  }
}