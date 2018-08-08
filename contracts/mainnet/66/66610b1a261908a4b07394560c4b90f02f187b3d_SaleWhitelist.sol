pragma solidity ^0.4.24;

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

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

contract SaleWhitelist is Ownable, RBAC {
    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    string public constant ROLE_CONTROLLER = "controller";
    string public constant ROLE_WHITELISTED = "whitelist";

    Whitelist public list;

    /* constructor */
    constructor(address whitelist) public {
        require(whitelist != address(0));
        list = Whitelist(whitelist);
    }

    /* whitelist controller */
    function setWhitelist(address addr)
        onlyOwner
        public
    {
        list = Whitelist(addr);
    }

    /* ownership controller */
    function addController(address addr)
        onlyOwner
        public
    {
        addRole(addr, ROLE_CONTROLLER);
    }

    function removeController(address addr)
        onlyOwner
        public
    {
        removeRole(addr, ROLE_CONTROLLER);
    }

    /* listing functions */
    function whitelist(address addr)
        public
        view
        returns (bool)
    {
        return (hasRole(addr, ROLE_WHITELISTED) || list.whitelist(addr));
    }

    function addAddressToWhitelist(address addr)
        onlyRole(ROLE_CONTROLLER)
        public
    {
        addRole(addr, ROLE_WHITELISTED);
        emit WhitelistedAddressAdded(addr);
    }

    function addAddressesToWhitelist(address[] addrs)
        onlyRole(ROLE_CONTROLLER)
        public
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            addAddressToWhitelist(addrs[i]);
        }
    }

    function removeAddressFromWhitelist(address addr)
        onlyRole(ROLE_CONTROLLER)
        public
    {
        removeRole(addr, ROLE_WHITELISTED);
        emit WhitelistedAddressRemoved(addr);
    }

    function removeAddressesFromWhitelist(address[] addrs)
        onlyRole(ROLE_CONTROLLER)
        public
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            removeAddressFromWhitelist(addrs[i]);
        }
    }
}

contract Whitelist is Ownable, RBAC {
  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  string public constant ROLE_WHITELISTED = "whitelist";

  /**
   * @dev Throws if called by any account that&#39;s not whitelisted.
   */
  modifier onlyWhitelisted() {
    checkRole(msg.sender, ROLE_WHITELISTED);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param addr address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address addr)
    onlyOwner
    public
  {
    addRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressAdded(addr);
  }

  /**
   * @dev getter to determine if address is in whitelist
   */
  function whitelist(address addr)
    public
    view
    returns (bool)
  {
    return hasRole(addr, ROLE_WHITELISTED);
  }

  /**
   * @dev add addresses to the whitelist
   * @param addrs addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      addAddressToWhitelist(addrs[i]);
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param addr address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn&#39;t in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address addr)
    onlyOwner
    public
  {
    removeRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressRemoved(addr);
  }

  /**
   * @dev remove addresses from the whitelist
   * @param addrs addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren&#39;t in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      removeAddressFromWhitelist(addrs[i]);
    }
  }

}

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