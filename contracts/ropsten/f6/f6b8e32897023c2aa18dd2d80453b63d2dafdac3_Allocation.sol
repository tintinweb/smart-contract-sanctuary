pragma solidity 0.4.25;


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

library Percent {
  using SafeMath for uint256;
  /**
   * @dev Add percent to numerator variable with precision
   */
	function perc
	(
    uint256 initialValue,
    uint256 percent
  ) 
    internal 
    pure 
    returns(uint256 result) 
  { 
    return initialValue.div(100).mul(percent);
  }
}

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
 * Supports unlimited numbers of roles and addresses.
 * See //contracts/mocks/RBACMock.sol for an example of usage.
 * This RBAC method uses strings to key roles. It may be beneficial
 * for you to write your own implementation of this interface using Enums or similar.
 * It&#39;s also recommended that you define constants in the contract, like ROLE_ADMIN below,
 * to avoid typos.
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
    view
    public
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
    view
    public
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

}


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

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        require(token.transferFrom(from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // &#39;safeIncreaseAllowance&#39; and &#39;safeDecreaseAllowance&#39;
        require((value == 0) || (token.allowance(msg.sender, spender) == 0));
        require(token.approve(spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        require(token.approve(spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        require(token.approve(spender, newAllowance));
    }
}


/**
 * @title TokenVesting
 * @dev A token holder contract that can release its token balance gradually like a
 * typical vesting scheme, with a cliff and vesting period. Optionally revocable by the
 * owner.
 */
contract TokenVesting is Ownable {
  using SafeMath for uint256;

  // Token release event, emits once owner releasing his tokens 
  event Released(uint256 amount);

  // Token revoke event
  event Revoked();

  // beneficiary of tokens after they are released
  address public beneficiary;

  // start
  uint256 public start;

  /**
   * Variables for setup vesting and release periods
   */
  uint256 public duration = 23667695;
  uint256 public firstStage = 7889229;
  uint256 public secondStage = 15778458;
  

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * _beneficiary, gradually in a linear fashion until _start + _duration. By then all
   * of the balance will have vested.
   * @param _beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param _start the time (as Unix time) at which point vesting starts 
   * @param _revocable whether the vesting is revocable or not
   */
  constructor(
    address _beneficiary,
    uint256 _start,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));
    beneficiary = _beneficiary;
    revocable = _revocable;
    start = _start;
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function release(ERC20 token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.transfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

  /**
   * @notice Allows the owner to revoke the vesting. Tokens already vested
   * remain in the contract, the rest are returned to the owner.
   * @param token ERC20 token which is being vested
   */
  function revoke(ERC20 token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.transfer(owner, refund);

    emit Revoked();
  }

  /**
   * @dev Calculates the amount that has already vested but hasn&#39;t been released yet.
   * @param token ERC20 token which is being vested
   */
  function releasableAmount(ERC20 token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function vestedAmount(ERC20 token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (block.timestamp >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } 

    if(block.timestamp >= start.add(firstStage) && block.timestamp <= start.add(secondStage)){
      return totalBalance.div(3);
    }

    if(block.timestamp >= start.add(secondStage) && block.timestamp <= start.add(duration)){
      return totalBalance.div(3).mul(2);
    }

    return 0;
  }
}


/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

  /**
   * @dev Throws if operator is not whitelisted.
   * @param _operator address
   */
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

  /**
   * @dev add an address to the whitelist
   * @param _operator address
   * @return true if the address was added to the whitelist, false if the address was already in the whitelist
   */
  function addAddressToWhitelist(address _operator)
    onlyOwner
    public
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev getter to determine if address is in whitelist
   */
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev add addresses to the whitelist
   * @param _operators addresses
   * @return true if at least one address was added to the whitelist,
   * false if all addresses were already in the whitelist
   */
  function addAddressesToWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

  /**
   * @dev remove an address from the whitelist
   * @param _operator address
   * @return true if the address was removed from the whitelist,
   * false if the address wasn&#39;t in the whitelist in the first place
   */
  function removeAddressFromWhitelist(address _operator)
    onlyOwner
    public
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

  /**
   * @dev remove addresses from the whitelist
   * @param _operators addresses
   * @return true if at least one address was removed from the whitelist,
   * false if all addresses weren&#39;t in the whitelist in the first place
   */
  function removeAddressesFromWhitelist(address[] _operators)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}


contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}


contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}


contract TokenDestructible is Ownable {

  constructor() public payable { }

  /**
   * @notice Terminate contract and refund to owner
   * @notice The called token contracts could try to re-enter this contract. Only
   supply token contracts you trust.
   */
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }
}


contract Token is PausableToken, TokenDestructible {
  /**
   * Variables that define basic token features
   */ 
  uint256 public decimals;
  string public name;
  string public symbol;
  uint256 releasedAmount = 0;

  constructor(uint256 _totalSupply, uint256 _decimals, string _name, string _symbol) public {
    require(_totalSupply > 0);
    require(_decimals > 0);

    totalSupply_ = _totalSupply;
    decimals = _decimals;
    name = _name;
    symbol = _symbol;

    balances[msg.sender] = _totalSupply;

    // transfer all supply to the owner
    emit Transfer(address(0), msg.sender, _totalSupply);
  }
}

/**
 * @title Allocation
 * Allocation is a base contract for managing a token sale,
 * allowing investors to purchase tokens with ether.
 */
contract Allocation is Whitelist {
  using SafeMath for uint256;
  using Percent for uint256;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  event Finalized();

  /**
   * Event for creation of token vesting contract
   * @param beneficiary who will receive tokens 
   * @param start time of vesting start
   * @param revocable specifies if vesting contract has abitility to revoke
   */
  event TimeVestingCreation
  (
    address beneficiary,
    uint256 start,
    uint256 duration,
    bool revocable
  );

  struct PartInfo {
    uint256 percent;
    bool lockup;
    uint256 amount;
  }

  mapping (address => bool) public owners;
  mapping (address => uint256) public contributors;            
  mapping (address => TokenVesting) public vesting;
  mapping (uint256 => PartInfo) public pieChart;
  mapping (address => bool) public isInvestor;
  
  address[] public investors;

  /**
   * Variables for bonus program
   * ============================
   * Variables values are test!!!
   */
  uint256 private SMALLEST_SUM; // 971911700000000000
  uint256 private SMALLER_SUM;  // 291573500000000000000
  uint256 private MEDIUM_SUM;   // 485955800000000000000
  uint256 private BIGGER_SUM;   // 971911700000000000000
  uint256 private BIGGEST_SUM;  // 1943823500000000000000

  // Vesting period
  uint256 public duration = 23667695;

  // Flag of Finalized sale event
  bool public isFinalized = false;

  // Wei raides accumulator
  uint256 public weiRaised = 0;

  //
  Token public token;
  //
  address public wallet;
  uint256 public rate;  
  uint256 public softCap;
  uint256 public hardCap;

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   * @param _softCap Soft cap
   * @param _hardCap Hard cap
   * @param _smallestSum Sum after which investor receives 5% of bonus tokens to vesting contract
   * @param _smallerSum Sum after which investor receives 10% of bonus tokens to vesting contract
   * @param _mediumSum Sum after which investor receives 15% of bonus tokens to vesting contract
   * @param _biggerSum Sum after which investor receives 20% of bonus tokens to vesting contract
   * @param _biggestSum Sum after which investor receives 30% of bonus tokens to vesting contract
   */
  constructor(
    uint256 _rate, 
    address _wallet, 
    Token _token,
    uint256 _softCap,
    uint256 _hardCap,
    uint256 _smallestSum,
    uint256 _smallerSum,
    uint256 _mediumSum,
    uint256 _biggerSum,
    uint256 _biggestSum
  ) 
    public 
  {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));
    require(_hardCap > 0);
    require(_softCap > 0);
    require(_hardCap > _softCap);

    rate = _rate;
    wallet = _wallet;
    token = _token;
    hardCap = _hardCap;
    softCap = _softCap;

    SMALLEST_SUM = _smallestSum;
    SMALLER_SUM = _smallerSum;
    MEDIUM_SUM = _mediumSum;
    BIGGER_SUM = _biggerSum;
    BIGGEST_SUM = _biggestSum;

    owners[msg.sender] = true;

    /**
    * Pie chart 
    *
    * early cotributors => 1
    * management team => 2
    * advisors => 3
    * partners => 4
    * community => 5
    * company => 6
    * liquidity => 7
    * sale => 8
    */
    pieChart[1] = PartInfo(10, true, token.totalSupply().mul(10).div(100));
    pieChart[2] = PartInfo(15, true, token.totalSupply().mul(15).div(100));
    pieChart[3] = PartInfo(5, true, token.totalSupply().mul(5).div(100));
    pieChart[4] = PartInfo(5, false, token.totalSupply().mul(5).div(100));
    pieChart[5] = PartInfo(8, false, token.totalSupply().mul(8).div(100));
    pieChart[6] = PartInfo(17, false, token.totalSupply().mul(17).div(100));
    pieChart[7] = PartInfo(10, false, token.totalSupply().mul(10).div(100));
    pieChart[8] = PartInfo(30, false, token.totalSupply().mul(30).div(100));
  }

  // -----------------------------------------
  // Allocation external interface
  // -----------------------------------------
  /**
   * Function for buying tokens
   */
  function() 
    external 
    payable 
  {
    buyTokens(msg.sender);
  }

  /**
   *  Check if value respects sale minimal contribution sum
   */
  modifier respectContribution() {
    require(
      msg.value >= SMALLEST_SUM,
      "Minimum contribution is $50,000"
    );
    _;
  }


  /**
   * Check if sale is still open
   */
  modifier onlyWhileOpen {
    require(!isFinalized, "Sale is closed");
    _;
  }

  /**
   * Check if sender is owner
   */
  modifier onlyOwner {
    require(isOwner(msg.sender) == true, "User is not in Owners");
    _;
  }


  /**
   * Add new owner
   * @param _owner Address of owner which should be added
   */
  function addOwner(address _owner) public onlyOwner {
    require(owners[_owner] == false);
    owners[_owner] = true;
  }

  /**
   * Delete an onwer
   * @param _owner Address of owner which should be deleted
   */
  function deleteOwner(address _owner) public onlyOwner {
    require(owners[_owner] == true);
    owners[_owner] = false;
  }

  /**
   * Check if sender is owner
   * @param _address Address of owner which should be checked
   */
  function isOwner(address _address) public view returns(bool res) {
    return owners[_address];
  }
  
  /**
   * Allocate tokens to provided investors
   */
  function allocateTokens(address[] _investors) public onlyOwner {
    require(_investors.length <= 50);
    
    for (uint i = 0; i < _investors.length; i++) {
      allocateTokensInternal(_investors[i]);
    }
  }

  /**
   * Allocate tokens to a single investor
   * @param _contributor Address of the investor
   */
  function allocateTokensForContributor(address _contributor) public onlyOwner {
    allocateTokensInternal(_contributor);
  }

  /*
   * Allocates tokens to single investor
   * @param _contributor Investor address
   */
  function allocateTokensInternal(address _contributor) internal {
    uint256 weiAmount = contributors[_contributor];

    if (weiAmount > 0) {
      uint256 tokens = _getTokenAmount(weiAmount);
      uint256 bonusTokens = _getBonusTokens(weiAmount);

      pieChart[8].amount = pieChart[8].amount.sub(tokens);
      pieChart[1].amount = pieChart[1].amount.sub(bonusTokens);

      contributors[_contributor] = 0;

      token.transfer(_contributor, tokens);
      createTimeBasedVesting(_contributor, bonusTokens);

      _forwardFunds();

      contributors[_contributor] = 0;
    }
  }
  
  /**
   * Send funds from any part of pieChart
   * @param _to Investors address
   * @param _type Part of pieChart
   * @param _amount Amount of tokens
   */
  function sendFunds(address _to, uint256 _type, uint256 _amount) public onlyOwner {
    require(
      pieChart[_type].amount >= _amount &&
      _type >= 1 &&
      _type <= 8
    );

    if (pieChart[_type].lockup == true) {
      createTimeBasedVesting(_to, _amount);
    } else {
      token.transfer(_to, _amount);
    }
    
    pieChart[_type].amount -= _amount;
  }

  /**
   * Investment receiver
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {
    uint256 weiAmount = msg.value;

    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created without bonuses
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    // update 
    contributors[_beneficiary] += weiAmount;

    if(!isInvestor[_beneficiary]){
      investors.push(_beneficiary);
      isInvestor[_beneficiary] = true;
    }

    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );
  }


  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------
  /**
   * Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase
  (
    address _beneficiary,
    uint256 _weiAmount
  )
    onlyIfWhitelisted(_beneficiary)
    respectContribution
    onlyWhileOpen
    view
    internal
  {
    require(weiRaised.add(_weiAmount) <= hardCap);
    require(_beneficiary != address(0));
  }

  /**
   * Create vesting contract
   * @param _beneficiary address of person who will get all tokens as vesting ends
   * @param _tokens amount of vested tokens
   */
  function createTimeBasedVesting
  (
    address _beneficiary,
    uint256 _tokens
  )
    internal
  {
    uint256 _start = block.timestamp;

    TokenVesting tokenVesting;

    if (vesting[_beneficiary] == address(0)) {
      tokenVesting = new TokenVesting(_beneficiary, _start, false);
      vesting[_beneficiary] = tokenVesting;
    } else {
      tokenVesting = vesting[_beneficiary];
    }

    token.transfer(address(tokenVesting), _tokens);

    emit TimeVestingCreation(_beneficiary, _start, duration, false);
  }


  /**
   *  checks if sale is closed
   */
  function hasClosed() public view returns (bool) {
    return isFinalized;
  }

  /** 
   * Release tokens from vesting contract
   */
  function releaseVestedTokens() public {
    address beneficiary = msg.sender;
    require(vesting[beneficiary] != address(0));

    TokenVesting tokenVesting = vesting[beneficiary];
    tokenVesting.release(token);
  }

  /**
   * Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getBonusTokens
  (
    uint256 _weiAmount
  )
    internal
    view
    returns (uint256 purchasedAmount)
  {
    purchasedAmount = _weiAmount;

    if (_weiAmount >= SMALLEST_SUM && _weiAmount < SMALLER_SUM) {
      purchasedAmount = _weiAmount.perc(5);
    }

    if (_weiAmount >= SMALLER_SUM && _weiAmount < MEDIUM_SUM) {
      purchasedAmount = _weiAmount.perc(10);
    }

    if (_weiAmount >= MEDIUM_SUM && _weiAmount < BIGGER_SUM) {
      purchasedAmount = _weiAmount.perc(15);
    }

    if (_weiAmount >= BIGGER_SUM && _weiAmount < BIGGEST_SUM) {
      purchasedAmount = _weiAmount.perc(20);
    }

    if (_weiAmount >= BIGGEST_SUM) {
      purchasedAmount = _weiAmount.perc(30);
    }

    return purchasedAmount.mul(rate);
  }

  function _getTokenAmount
  (
    uint256 _weiAmount
  )
    internal
    view
    returns (uint256 purchasedAmount)
  {
    return _weiAmount.mul(rate);
  }

  /**
   * Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }


  /**
   * Must be called after sale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() public onlyOwner {
    require(!hasClosed());
    finalization();
    isFinalized = true;
    emit Finalized();
  } 


  /**
   * Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() pure internal {}

}