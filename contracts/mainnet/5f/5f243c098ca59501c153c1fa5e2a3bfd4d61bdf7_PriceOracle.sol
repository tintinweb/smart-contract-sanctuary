pragma solidity ^0.4.24;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
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
}


/**
 * @title Ethereum price feed
 * @dev Keeps the current ETH price in USD cents to use by crowdsale contracts.
 * Price kept up to date by external script polling exchanges tickers
 * @author OnGrid Systems
 */
contract PriceOracle is RBAC {
  using SafeMath for uint256;

  // Average ETH price in USD cents
  uint256 public ethPriceInCents;

  // The change limit in percent.
  // Provides basic protection from erroneous input.
  uint256 public allowedOracleChangePercent;

  // Roles in the oracle
  string public constant ROLE_ADMIN = "admin";
  string public constant ROLE_ORACLE = "oracle";

  /**
   * @dev modifier to scope access to admins
   * // reverts if called not by admin
   */
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }

  /**
   * @dev modifier to scope access to price keeping oracles (scripts polling exchanges)
   * // reverts if called not by oracle
   */
  modifier onlyOracle()
  {
    checkRole(msg.sender, ROLE_ORACLE);
    _;
  }

  /**
   * @dev Initializes oracle contract
   * @param _initialEthPriceInCents Initial Ethereum price in USD cents
   * @param _allowedOracleChangePercent Percent of change allowed per single request
   */
  constructor(
    uint256 _initialEthPriceInCents,
    uint256 _allowedOracleChangePercent
  ) public {
    ethPriceInCents = _initialEthPriceInCents;
    allowedOracleChangePercent = _allowedOracleChangePercent;
    addRole(msg.sender, ROLE_ADMIN);
  }

  /**
   * @dev Converts ETH (wei) to USD cents
   * @param _wei amount of wei (10e-18 ETH)
   * @return cents amount
   */
  function getUsdCentsFromWei(uint256 _wei) public view returns (uint256) {
    return _wei.mul(ethPriceInCents).div(1 ether);
  }

  /**
   * @dev Converts USD cents to wei
   * @param _usdCents amount
   * @return wei amount
   */
  function getWeiFromUsdCents(uint256 _usdCents)
    public view returns (uint256)
  {
    return _usdCents.mul(1 ether).div(ethPriceInCents);
  }

  /**
   * @dev Sets current ETH price in cents
   * @param _cents USD cents
   */
  function setEthPrice(uint256 _cents)
    public
    onlyOracle
  {
    uint256 maxCents = allowedOracleChangePercent.add(100)
    .mul(ethPriceInCents).div(100);
    uint256 minCents = SafeMath.sub(100,allowedOracleChangePercent)
    .mul(ethPriceInCents).div(100);
    require(
      _cents <= maxCents && _cents >= minCents,
      "Price out of allowed range"
    );
    ethPriceInCents = _cents;
  }

  /**
   * @dev Add admin role to an address
   * @param addr address
   */
  function addAdmin(address addr)
    public
    onlyAdmin
  {
    addRole(addr, ROLE_ADMIN);
  }

  /**
   * @dev Revoke admin privileges from an address
   * @param addr address
   */
  function delAdmin(address addr)
    public
    onlyAdmin
  {
    removeRole(addr, ROLE_ADMIN);
  }

  /**
   * @dev Add oracle role to an address
   * @param addr address
   */
  function addOracle(address addr)
    public
    onlyAdmin
  {
    addRole(addr, ROLE_ORACLE);
  }

  /**
   * @dev Revoke oracle role from an address
   * @param addr address
   */
  function delOracle(address addr)
    public
    onlyAdmin
  {
    removeRole(addr, ROLE_ORACLE);
  }
}