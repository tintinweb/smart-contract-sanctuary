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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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

// File: contracts/access/RBACManager.sol

contract RBACManager is RBAC, Ownable {
  string constant ROLE_MANAGER = "manager";

  modifier onlyOwnerOrManager() {
    require(
      msg.sender == owner || hasRole(msg.sender, ROLE_MANAGER),
      "unauthorized"
    );
    _;
  }

  constructor() public {
    addRole(msg.sender, ROLE_MANAGER);
  }

  function addManager(address _manager) public onlyOwner {
    addRole(_manager, ROLE_MANAGER);
  }

  function removeManager(address _manager) public onlyOwner {
    removeRole(_manager, ROLE_MANAGER);
  }
}

// File: contracts/CharityProject.sol

contract CharityProject is RBACManager {
  using SafeMath for uint256;

  modifier canWithdraw() {
    require(
      canWithdrawBeforeEnd || closingTime == 0 || block.timestamp > closingTime, // solium-disable-line security/no-block-members
      "can&#39;t withdraw");
    _;
  }

  uint256 public withdrawn;

  uint256 public maxGoal;
  uint256 public openingTime;
  uint256 public closingTime;
  address public wallet;
  ERC20 public token;
  bool public canWithdrawBeforeEnd;

  constructor (
    uint256 _maxGoal,
    uint256 _openingTime,
    uint256 _closingTime,
    address _wallet,
    ERC20 _token,
    bool _canWithdrawBeforeEnd,
    address _additionalManager
  ) public {
    require(_wallet != address(0), "_wallet can&#39;t be zero");
    require(_token != address(0), "_token can&#39;t be zero");
    require(
      _closingTime == 0 || _closingTime >= _openingTime,
      "wrong value for _closingTime"
    );

    maxGoal = _maxGoal;
    openingTime = _openingTime;
    closingTime = _closingTime;
    wallet = _wallet;
    token = _token;
    canWithdrawBeforeEnd = _canWithdrawBeforeEnd;

    if (wallet != owner) {
      addManager(wallet);
    }

    // solium-disable-next-line max-len
    if (_additionalManager != address(0) && _additionalManager != owner && _additionalManager != wallet) {
      addManager(_additionalManager);
    }
  }

  function withdrawTokens(
    address _to,
    uint256 _value
  )
  public
  onlyOwnerOrManager
  canWithdraw
  {
    token.transfer(_to, _value);
    withdrawn = withdrawn.add(_value);
  }

  function totalRaised() public view returns (uint256) {
    uint256 raised = token.balanceOf(this);
    return raised.add(withdrawn);
  }

  function hasStarted() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return openingTime == 0 ? true : block.timestamp > openingTime;
  }

  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return closingTime == 0 ? false : block.timestamp > closingTime;
  }

  function maxGoalReached() public view returns (bool) {
    return totalRaised() >= maxGoal;
  }

  function setMaxGoal(uint256 _newMaxGoal) public onlyOwner {
    maxGoal = _newMaxGoal;
  }

  function setTimes(
    uint256 _openingTime,
    uint256 _closingTime
  )
  public
  onlyOwner
  {
    require(
      _closingTime == 0 || _closingTime >= _openingTime,
      "wrong value for _closingTime"
    );

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  function setCanWithdrawBeforeEnd(
    bool _canWithdrawBeforeEnd
  )
  public
  onlyOwner
  {
    canWithdrawBeforeEnd = _canWithdrawBeforeEnd;
  }
}