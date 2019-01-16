pragma solidity ^0.4.24;

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 * Originally based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param owner The address to query the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param owner address The address which owns the funds.
   * @param spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

  /**
  * @dev Transfer token for a specified address
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param spender The address which will spend the funds.
   * @param value The amount of tokens to be spent.
   */
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param from address The address which you want to send tokens from
   * @param to address The address which you want to transfer to
   * @param value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param addedValue The amount of tokens to increase the allowance by.
   */
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed_[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param spender The address which will spend the funds.
   * @param subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  /**
  * @dev Transfer token for a specified addresses
  * @param from The address to transfer from.
  * @param to The address to transfer to.
  * @param value The amount to be transferred.
  */
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

  /**
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param value The amount that will be created.
   */
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param value The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Mintable is ERC20, MinterRole {
  /**
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens.
   * @param value The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address to,
    uint256 value
  )
    public
    onlyMinter
    returns (bool)
  {
    _mint(to, value);
    return true;
  }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {

  using SafeMath for uint256;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    // safeApprove should only be called when setting an initial allowance, 
    // or when resetting it to zero. To increase and decrease it, use 
    // &#39;safeIncreaseAllowance&#39; and &#39;safeDecreaseAllowance&#39;
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
  }
}

/**
 * @title Helps contracts guard against reentrancy attacks.
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="81f3e4ece2eec1b3">[email&#160;protected]</a>π.com>, Eenae <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="e2838e879a879ba28f8b9a809b968791cc8b8d">[email&#160;protected]</a>>
 * @dev If you mark a function `nonReentrant`, you should also
 * mark it `external`.
 */
contract ReentrancyGuard {

  /// @dev counter to allow mutex lock with only one SSTORE operation
  uint256 private _guardCounter;

  constructor() internal {
    // The counter starts at one to prevent changing it from zero to a non-zero
    // value, which is a more expensive operation.
    _guardCounter = 1;
  }

  /**
   * @dev Prevents a contract from calling itself, directly or indirectly.
   * Calling a `nonReentrant` function from another `nonReentrant`
   * function is not supported. It is possible to prevent this from happening
   * by making the `nonReentrant` function external, and make it call a
   * `private` function that does the actual work.
   */
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using &#39;super&#39; where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  // The token being sold
  IERC20 private _token;

  // Address where funds are collected
  address private _wallet;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 private _rate;

  // Amount of wei raised
  uint256 private _weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param rate Number of token units a buyer gets per wei
   * @dev The rate is the conversion between wei and the smallest and indivisible
   * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
   * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
   * @param wallet Address where collected funds will be forwarded to
   * @param token Address of the token being sold
   */
  constructor(uint256 rate, address wallet, IERC20 token) internal {
    require(rate > 0);
    require(wallet != address(0));
    require(token != address(0));

    _rate = rate;
    _wallet = wallet;
    _token = token;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   * Note that other contracts will transfer fund with a base gas stipend
   * of 2300, which is not enough to call buyTokens. Consider calling
   * buyTokens directly when purchasing tokens from a contract.
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @return the token being sold.
   */
  function token() public view returns(IERC20) {
    return _token;
  }

  /**
   * @return the address where funds are collected.
   */
  function wallet() public view returns(address) {
    return _wallet;
  }

  /**
   * @return the number of token units a buyer gets per wei.
   */
  function rate() public view returns(uint256) {
    return _rate;
  }

  /**
   * @return the amount of wei raised.
   */
  function weiRaised() public view returns (uint256) {
    return _weiRaised;
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * This function has a non-reentrancy guard, so it shouldn&#39;t be called by
   * another `nonReentrant` function.
   * @param beneficiary Recipient of the token purchase
   */
  function buyTokens(address beneficiary) public nonReentrant payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    _weiRaised = _weiRaised.add(weiAmount);

    _processPurchase(beneficiary, tokens);
    emit TokensPurchased(
      msg.sender,
      beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
   * Example from CappedCrowdsale.sol&#39;s _preValidatePurchase method:
   *   super._preValidatePurchase(beneficiary, weiAmount);
   *   require(weiRaised().add(weiAmount) <= cap);
   * @param beneficiary Address performing the token purchase
   * @param weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    view
  {
    require(beneficiary != address(0));
    require(weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param beneficiary Address performing the token purchase
   * @param weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    view
  {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param beneficiary Address performing the token purchase
   * @param tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _token.safeTransfer(beneficiary, tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Doesn&#39;t necessarily emit/send tokens.
   * @param beneficiary Address receiving the tokens
   * @param tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _deliverTokens(beneficiary, tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param beneficiary Address receiving the tokens
   * @param weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address beneficiary,
    uint256 weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 weiAmount)
    internal view returns (uint256)
  {
    return weiAmount.mul(_rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    _wallet.transfer(msg.value);
  }
}

/**
 * @title IncreasingPriceTCO
 * @notice Extension of Crowdsale contract that increases the price of tokens according to price ranges.
 * At least two ranges should be provided to the constructor with every next range value greater than the previous.
 */
contract IncreasingPriceTCO is Crowdsale {
    using SafeMath for uint256;

    uint256[2][] private _rates; //_rates[i][0] - upper limit of total weiRaised to apply _rates[i][1] exchange rate at the 
    uint8 private _currentRateIndex; // Index of the current rate: _rates[_currentIndex][1] is the current rate index

    event NewRateIsSet(
    uint256 newRate,
    uint8 newRateIndex,
    uint256 weiRaisedRange,
    uint256 weiRaised
  );
/**
 * @param initRates Is an array of pairs [weiRaised, exchangeRate]. Deteremine the exchange rate depending on the total wei raised before the transaction. 
 */
  constructor(uint256[2][] memory initRates) internal {
    require(initRates.length > 1, &#39;Rates array should contain more then one value&#39;); // Rates Ranges array is usable whith more than one exchange rate range
    _rates = initRates;
    _currentRateIndex = 0;
  }
 
  function getCurrentRate() public view returns(uint256) {
     return _rates[_currentRateIndex][1];
  }

  modifier ifNotLastRange {
      if(_currentRateIndex < _rates.length - 1)
      _;
  }

/**
 * @notice The new exchange rate is set if the total weiRased() after a transaction is out of the current range 
 */
  function _updateCurrentRate() internal ifNotLastRange {
    uint256 _weiRaised = weiRaised();
    while(_weiRaised >= _rates[_currentRateIndex][0] && _currentRateIndex < _rates.length) {
        _currentRateIndex++;
        emit NewRateIsSet(_rates[_currentRateIndex][1], _currentRateIndex, _rates[_currentRateIndex][0], _weiRaised);
    }
  }

  /**
   * @notice The base rate function is overridden to revert, since this crowdsale doens&#39;t use it, and
   * all calls to it are a mistake.
   */
  function rate() public view returns(uint256) {
    revert();
  }
  
/**
 * @notice Overrides Crowdsales&#39; function applying multiple increasing price exchange rates concept
 */
  function _getTokenAmount(uint256 weiAmount)
    internal view returns (uint256)
  {
    return getCurrentRate().mul(weiAmount);
  }

/**
 * @notice Overloads "hook" from base Crowdsale. Checks and updates current exchange rate. The parameters aren&#39;t used thus commented out.
 * 
 */
  function _updatePurchasingState(address /*beneficiary*/, uint256 /*weiAmount*/) internal
  {
    _updateCurrentRate();
    //super._updatePurchasingState(beneficiary, weiAmount);
  }
}

contract KeeperRole {
  using Roles for Roles.Role;

  event KeeperAdded(address indexed account);
  event KeeperRemoved(address indexed account);

  Roles.Role private keepers;

  constructor() internal {
    _addKeeper(msg.sender);
  }

  modifier onlyKeeper() {
    require(isKeeper(msg.sender), &#39;Only Keeper is allowed&#39;);
    _;
  }

  function isKeeper(address account) public view returns (bool) {
    return keepers.has(account);
  }

  function addKeeper(address account) public onlyKeeper {
    _addKeeper(account);
  }

  function renounceKeeper() public {
    _removeKeeper(msg.sender);
  }

  function _addKeeper(address account) internal {
    keepers.add(account);
    emit KeeperAdded(account);
  }

  function _removeKeeper(address account) internal {
    keepers.remove(account);
    emit KeeperRemoved(account);
  }
}

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

/**
 * @title Haltable
 * @dev Base contract which allows children to implement an emergency pause mechanism 
 * and close irreversibly
 */
contract Haltable is KeeperRole, PauserRole {
  event Paused(address account);
  event Unpaused(address account);
  event Closed(address account);

  bool private _paused;
  bool private _closed;

  constructor() internal {
    _paused = false;
    _closed = false;
  }

  /**
   * @return true if the contract is paused, false otherwise.
   */
  function paused() public view returns(bool) {
    return _paused;
  }

  /**
   * @return true if the contract is closed, false otherwise.
   */
  function isClosed() public view returns(bool) {
    return _closed;
  }

  /**
   * @return true if the contract is not closed, false otherwise.
   */
  function notClosed() public view returns(bool) {
    return !isClosed();
  }

  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!_paused, &#39;The contract is paused&#39;);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(_paused, &#39;The contract is not paused&#39;);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is closed.
   */
  modifier whenClosed(bool orCondition) {
    require(_closed, &#39;The contract is not closed&#39;);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is closed or an external condition is met.
   */
  modifier whenClosedOr(bool orCondition) {
    require(_closed || orCondition, "It must be closed or what is set in &#39;orCondition&#39;");
    _;
  }

/**
   * @dev Modifier to make a function callable only when the contract is not closed.
   */
  modifier whenNotClosed() {
    require(!_closed, "Reverted because it is closed");
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }

  /**
   * @dev Called by a Keeper to close a contract. This is irreversible.
   */
  function close() internal whenNotClosed {
    _closed = true;
    emit Closed(msg.sender);
  }
}

/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
contract CappedTCO is Crowdsale {
  using SafeMath for uint256;
  uint256 private _cap;
  
  /**
  * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
  * @param cap Max amount of wei to be contributed
  */
  constructor(uint256 cap) internal {
      require(cap > 0, &#39;Hard cap must be > 0&#39;);
      _cap = cap;
  }
  
  /**
  * @return the cap of the crowdsale.
  */
  function cap() public view returns(uint256) {
      return _cap;
  }
  
  /**
  * @dev Checks whether the cap has been reached.
  * @return Whether the cap was not reached
  */
  function capNotReached() public view returns (bool) {
      return weiRaised() < _cap;
  }
  
  /**
  * @dev Checks whether the cap has been reached.
  * @return Whether the cap was reached
  */
  function capReached() public view returns (bool) {
      return weiRaised() >= _cap;
  }
}

/**
 * @title PostDeliveryCrowdsale
 * @dev Crowdsale that locks tokens from withdrawal until it ends.
 */

contract PostDeliveryCappedTCO is CappedTCO, Haltable {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances; //token balances storage until the crowdsale ends

  uint256 private _totalSupply; //total GUT distributed amount

  event TokensWithdrawn(
    address indexed beneficiary,
    uint256 amount
  );

  constructor() internal {}

  /**
   * @dev Withdraw tokens only after the crowdsale ends (closed).
   * @param beneficiary Whose tokens will be withdrawn.
   * @notice withdrawal is suspended in case the crowdsale is paused.
   */
  function withdrawTokens(address beneficiary) public whenNotPaused whenClosedOr(capReached()) {
    uint256 amount = _balances[beneficiary];
    require(amount > 0, &#39;The balances should be positive for withdrawal. Maybe you have already done it, please check the token balances, not crowdsale.&#39;);
    _balances[beneficiary] = 0;
    _deliverTokens(beneficiary, amount);
    emit TokensWithdrawn(beneficiary, amount);
  }

  /**
   * @dev Total number of tokens supplied
   */
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

  /**
   * @return the balance of an account.
   */
  function balanceOf(address account) public view returns(uint256) {
    return _balances[account];
  }

/**
  * @dev Extend parent behavior requiring purchase to respect the funding cap.
  * @param beneficiary Token purchaser
  * @param weiAmount Amount of wei contributed
  */
  function _preValidatePurchase(
      address beneficiary,
      uint256 weiAmount
  )
      internal
      view
  {
      require(capNotReached(),"Hardcap for is reached.");
      require(notClosed(), "TCO finished, sorry.");
      super._preValidatePurchase(beneficiary, weiAmount);
  }

  /**
   * @dev Overrides parent by storing balances instead of issuing tokens right away
   * @param beneficiary Token purchaser
   * @param tokenAmount Amount of tokens purchased
   */
  function _processPurchase(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
    _totalSupply = _totalSupply.add(tokenAmount);
  }
}

/**
 * @notice If you transfer funds (ETH) from a contract, the default gas stipend 2300 will not be enough to complete transaction to your contract address. Please, consider calling buyTokens() directly when purchasing tokens from a contract.
 * 
*/
contract GutTCO is 
PostDeliveryCappedTCO, 
IncreasingPriceTCO, 
MinterRole
{
    bool private _finalized;

    event CrowdsaleFinalized();
/**
 * @param _rate is nominal and not used
 * @param _wallet is beneficiary address
 */
    constructor(
    uint256 _rate,
    address _wallet,
    uint256 _cap,
    ERC20Mintable _token
  ) public 
  Crowdsale(_rate, _wallet, _token)
  CappedTCO(_cap)
  IncreasingPriceTCO(initRates())
  {
    _finalized = false;
  }

/**
 * @notice Initializes exchange rates ranges.
 */
  function initRates() internal pure returns(uint256[2][] memory ratesArray) {
     ratesArray = new uint256[2][](4);
     ratesArray[0] = [uint256(1 ether), 3000];
     ratesArray[1] = [uint256(3 ether), 1500];   
     ratesArray[2] = [uint256(5 ether), 500];
     ratesArray[3] = [uint256(7 ether), 125];
  }
  
  function closeTCO() public onlyMinter {
     if(notFinalized()) _finalize();
  }

  /**
   * @return true if the crowdsale is finalized, false otherwise.
   */
  function finalized() public view returns (bool) {
    return _finalized;
  }

  /**
   * @return true if the crowdsale is finalized, false otherwise.
   */
  function notFinalized() public view returns (bool) {
    return !finalized();
  }

  /**
   * @dev Must be called after TCO ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function _finalize() private {
    require(notFinalized(), &#39;TCO already finalized&#39;);
    if(notClosed()) close();
    _finalization();
    emit CrowdsaleFinalized();
  }

  function _finalization() private {
     require(totalSupply()>0, &#39;Total ether supply must be > 0&#39;);
     require(ERC20Mintable(address(token())).mint(address(this), totalSupply()), &#39;Error when being finalized at minting totalSupply() to the token&#39;);
     _finalized = true;
  }

  /**
 * @notice Overloads PostDeliveryCappedTCO. Auto finalize TCO when the cap is reached. 
 * 
 */
  function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal 
  {
    super._updatePurchasingState(beneficiary, weiAmount);
    if(capReached()) _finalize();
  }
}