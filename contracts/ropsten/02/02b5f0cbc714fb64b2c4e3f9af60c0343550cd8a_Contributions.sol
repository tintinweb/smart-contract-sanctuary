pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

// File: openzeppelin-solidity/contracts/access/rbac/Roles.sol

/**
 * @title Roles
 * @author Francisco Giordano (@frangio)
 * @dev Library for managing addresses assigned to a Role.
 * See RBAC.sol for example usage.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an address access to this role
   */
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

  /**
   * @dev remove an address&#39; access to this role
   */
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

  /**
   * @dev check if an address has this role
   * // reverts
   */
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

  /**
   * @dev check if an address has this role
   * @return bool
   */
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

// File: openzeppelin-solidity/contracts/access/rbac/RBAC.sol

/**
 * @title RBAC (Role-Based Access Control)
 * @author Matt Condon (@Shrugs)
 * @dev Stores and provides setters and getters for roles and addresses.
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 */
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

  /**
   * @dev reverts if addr does not have role
   * @param _operator address
   * @param _role the name of the role
   * // reverts
   */
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

  /**
   * @dev determine if addr has role
   * @param _operator address
   * @param _role the name of the role
   * @return bool
   */
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

  /**
   * @dev add a role to an address
   * @param _operator address
   * @param _role the name of the role
   */
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

  /**
   * @dev remove a role from an address
   * @param _operator address
   * @param _role the name of the role
   */
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

  /**
   * @dev modifier to scope access to a single role (uses msg.sender as addr)
   * @param _role the name of the role
   * // reverts
   */
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

  /**
   * @dev modifier to scope access to a set of roles (uses msg.sender as addr)
   * @param _roles the names of the roles to scope access to
   * // reverts
   *
   * @TODO - when solidity supports dynamic arrays as arguments to modifiers, provide this
   *  see: https://github.com/ethereum/solidity/issues/2467
   */
  // modifier onlyRoles(string[] _roles) {
  //     bool hasAnyRole = false;
  //     for (uint8 i = 0; i < _roles.length; i++) {
  //         if (hasRole(msg.sender, _roles[i])) {
  //             hasAnyRole = true;
  //             break;
  //         }
  //     }

  //     require(hasAnyRole);

  //     _;
  // }
}

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


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
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

// File: contracts/crowdsale/utils/Contributions.sol

contract Contributions is RBAC, Ownable {
  using SafeMath for uint256;

  uint256 private constant TIER_DELETED = 999;
  string public constant ROLE_MINTER = "minter";
  string public constant ROLE_OPERATOR = "operator";

  uint256 public tierLimit;

  modifier onlyMinter () {
    checkRole(msg.sender, ROLE_MINTER);
    _;
  }

  modifier onlyOperator () {
    checkRole(msg.sender, ROLE_OPERATOR);
    _;
  }

  uint256 public totalSoldTokens;
  mapping(address => uint256) public tokenBalances;
  mapping(address => uint256) public ethContributions;
  mapping(address => uint256) private _whitelistTier;
  address[] public tokenAddresses;
  address[] public ethAddresses;
  address[] private whitelistAddresses;

  constructor(uint256 _tierLimit) public {
    addRole(owner, ROLE_OPERATOR);
    tierLimit = _tierLimit;
  }

  function addMinter(address minter) external onlyOwner {
    addRole(minter, ROLE_MINTER);
  }

  function removeMinter(address minter) external onlyOwner {
    removeRole(minter, ROLE_MINTER);
  }

  function addOperator(address _operator) external onlyOwner {
    addRole(_operator, ROLE_OPERATOR);
  }

  function removeOperator(address _operator) external onlyOwner {
    removeRole(_operator, ROLE_OPERATOR);
  }

  function addTokenBalance(
    address _address,
    uint256 _tokenAmount
  )
    external
    onlyMinter
  {
    if (tokenBalances[_address] == 0) {
      tokenAddresses.push(_address);
    }
    tokenBalances[_address] = tokenBalances[_address].add(_tokenAmount);
    totalSoldTokens = totalSoldTokens.add(_tokenAmount);
  }

  function addEthContribution(
    address _address,
    uint256 _weiAmount
  )
    external
    onlyMinter
  {
    if (ethContributions[_address] == 0) {
      ethAddresses.push(_address);
    }
    ethContributions[_address] = ethContributions[_address].add(_weiAmount);
  }

  function setTierLimit(uint256 _newTierLimit) external onlyOperator {
    require(_newTierLimit > 0, "Tier must be greater than zero");

    tierLimit = _newTierLimit;
  }

  function addToWhitelist(
    address _investor,
    uint256 _tier
  )
    external
    onlyOperator
  {
    require(_tier == 1 || _tier == 2, "Only two tier level available");
    if (_whitelistTier[_investor] == 0) {
      whitelistAddresses.push(_investor);
    }
    _whitelistTier[_investor] = _tier;
  }

  function removeFromWhitelist(address _investor) external onlyOperator {
    _whitelistTier[_investor] = TIER_DELETED;
  }

  function whitelistTier(address _investor) external view returns (uint256) {
    return _whitelistTier[_investor] <= 2 ? _whitelistTier[_investor] : 0;
  }

  function getWhitelistedAddresses(
    uint256 _tier
  )
    external
    view
    returns (address[])
  {
    address[] memory tmp = new address[](whitelistAddresses.length);

    uint y = 0;
    if (_tier == 1 || _tier == 2) {
      uint len = whitelistAddresses.length;
      for (uint i = 0; i < len; i++) {
        if (_whitelistTier[whitelistAddresses[i]] == _tier) {
          tmp[y] = whitelistAddresses[i];
          y++;
        }
      }
    }

    address[] memory toReturn = new address[](y);

    for (uint k = 0; k < y; k++) {
      toReturn[k] = tmp[k];
    }

    return toReturn;
  }

  function isAllowedPurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    external
    view
    returns (bool)
  {
    if (_whitelistTier[_beneficiary] == 2) {
      return true;
    } else if (_whitelistTier[_beneficiary] == 1 && ethContributions[_beneficiary].add(_weiAmount) <= tierLimit) {
      return true;
    }

    return false;
  }

  function getTokenAddressesLength() external view returns (uint) {
    return tokenAddresses.length;
  }

  function getEthAddressesLength() external view returns (uint) {
    return ethAddresses.length;
  }
}