pragma solidity ^0.4.24;

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

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

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

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
  * @param owner The address to query the the balance of.
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
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(msg.sender, to, value);
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
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    emit Transfer(from, to, value);
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
   * @dev Internal function that mints an amount of the token and assigns it to
   * an account. This encapsulates the modification of balances such that the
   * proper events are emitted.
   * @param account The account that will receive the created tokens.
   * @param amount The amount that will be created.
   */
  function _mint(address account, uint256 amount) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(amount);
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burn(address account, uint256 amount) internal {
    require(account != 0);
    require(amount <= _balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  /**
   * @dev Internal function that burns an amount of the token of a given
   * account, deducting from the sender&#39;s allowance for said account. Uses the
   * internal burn function.
   * @param account The account whose tokens will be burnt.
   * @param amount The amount that will be burnt.
   */
  function _burnFrom(address account, uint256 amount) internal {
    require(amount <= _allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      amount);
    _burn(account, amount);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
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
    require(token.approve(spender, value));
  }
}

// File: openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol

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
contract Crowdsale {
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
  constructor(uint256 rate, address wallet, IERC20 token) public {
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
   * @return the mount of wei raised.
   */
  function weiRaised() public view returns (uint256) {
    return _weiRaised;
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param beneficiary Address performing the token purchase
   */
  function buyTokens(address beneficiary) public payable {

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
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
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

// File: contracts/TieredPriceCrowdsale.sol

/**
 * @title CappedWhitelistedCrowdsale
 * @dev Crowdsale with a limit for total contributions and per-beneficiary caps. 
 * Combination of CappedCrowdsale and IndividuallyCappedCrowdsale
 */
contract TieredPriceCrowdsale is Crowdsale {
    uint256 private _baseRate;
    uint256 private _tier2Start;
    uint256 private _tier3Start;
    uint256 private _tier4Start;

    constructor( 
      uint256 baseRate,
      uint256 openingTimeTier2,
      uint256 openingTimeTier3, 
      uint256 openingTimeTier4
    ) 
    public 
    {
        require(baseRate > 0);
        require(openingTimeTier2 > block.timestamp);
        require(openingTimeTier3 >= openingTimeTier2);
        require(openingTimeTier4 >= openingTimeTier3);

        _baseRate = baseRate;
        _tier4Start = openingTimeTier4;
        _tier3Start = openingTimeTier3;
        _tier2Start = openingTimeTier2;
    }

    function _getbonusRate()
      internal view returns (uint256)
    {
        // Calculate current rate with bonus
        if(_tier2Start > block.timestamp){
            return(_baseRate * 6 / 5);
        }
        else if(_tier3Start > block.timestamp){
            return(_baseRate * 11 / 10);
        }
        else if(_tier4Start > block.timestamp){
            return(_baseRate * 21 / 20);
        }
        else {
            return(_baseRate);
        }
    }

    /**
      * @return the current bonus level.
      */
    function bonusRate() public view returns(uint256) {
        return _getbonusRate();
    }

     /**
      * @param tier Value that represents the tier
      * @return Timestamp when the tier starts
      */
    function tierStartTime(
        uint256 tier       
    ) external view returns(uint256) 
    {
        if(tier == 2){
            return _tier2Start;
        }
        else if(tier == 3){
            return _tier3Start;
        }
        else if(tier == 4){
            return _tier4Start;
        }
        return 0;
    }

    /**
      * @dev Override to extend the way in which ether is converted to tokens.
      * @param weiAmount Value in wei to be converted into tokens
      * @return Number of tokens that can be purchased with the specified _weiAmount
      */
    function _getTokenAmount(
        uint256 weiAmount
    )
      internal view returns (uint256)
    {
        return weiAmount.mul(_getbonusRate());
    }
}

// File: openzeppelin-solidity/contracts/access/Roles.sol

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
    role.bearer[account] = true;
  }

  /**
   * @dev remove an account&#39;s access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
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

// File: openzeppelin-solidity/contracts/access/roles/CapperRole.sol

contract CapperRole {
  using Roles for Roles.Role;

  event CapperAdded(address indexed account);
  event CapperRemoved(address indexed account);

  Roles.Role private cappers;

  constructor() public {
    cappers.add(msg.sender);
  }

  modifier onlyCapper() {
    require(isCapper(msg.sender));
    _;
  }

  function isCapper(address account) public view returns (bool) {
    return cappers.has(account);
  }

  function addCapper(address account) public onlyCapper {
    cappers.add(account);
    emit CapperAdded(account);
  }

  function renounceCapper() public {
    cappers.remove(msg.sender);
  }

  function _removeCapper(address account) internal {
    cappers.remove(account);
    emit CapperRemoved(account);
  }
}

// File: contracts/WhitelistedCrowdsale.sol

/**
 * @title WhitelistedCrowdsale
 * @dev Crowdsale with whitelist required for purchases, based on IndividuallyCappedCrowdsale.
 */
contract WhitelistedCrowdsale is Crowdsale, CapperRole {
    using SafeMath for uint256;

    uint256 private _invCap;   

    mapping(address => uint256) private _contributions;
    mapping(address => uint256) private _caps;

    constructor(uint256 invCap) public
    {
        require(invCap > 0);
        _invCap = invCap;
    }

    /**
    * @dev Checks whether the beneficiary is in the whitelist.
    * @param beneficiary Address to be checked
    * @return Whether the beneficiary is whitelisted
    */
    function isWhitelisted(address beneficiary) public view returns (bool) {
        return _caps[beneficiary] != 0;
    }

    /**
    * @dev add an address to the whitelist
    * @param beneficiary address
    * @return true if the address was added to the whitelist, false if the address was already in the whitelist
    */
    function addAddressToWhitelist(address beneficiary) public onlyCapper returns (bool) {
        require(beneficiary != address(0));
        _caps[beneficiary] = _invCap;
        return isWhitelisted(beneficiary);
    }

    /**
    * @dev add addresses to the whitelist
    * @param _beneficiaries addresses
    * @return true if at least one address was added to the whitelist,
    * false if all addresses were already in the whitelist
    */
    function addAddressesToWhitelist(address[] _beneficiaries) external onlyCapper {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            addAddressToWhitelist(_beneficiaries[i]);
        }
    }

    /**
    * @dev remove an address from the whitelist
    * @param beneficiary address
    * @return true if the address was removed from the whitelist, false if the address wasn&#39;t already in the whitelist
    */
    function removeAddressFromWhitelist(address beneficiary) public onlyCapper returns (bool) {
        require(beneficiary != address(0));
        _caps[beneficiary] = 0;
        return isWhitelisted(beneficiary);
    }

    /**
    * @dev remove addresses from the whitelist
    * @param _beneficiaries addresses
    * @return true if at least one address was removed from the whitelist,
    * false if all addresses weren&#39;t already in the whitelist
    */
    function removeAddressesFromWhitelist(address[] _beneficiaries) external onlyCapper {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            removeAddressFromWhitelist(_beneficiaries[i]);
        }
    }

    /**
    * @dev Returns the amount contributed so far by a specific beneficiary.
    * @param beneficiary Address of contributor
    * @return Beneficiary contribution so far
    */
    function getContribution(address beneficiary)
    public view returns (uint256)
    {
        return _contributions[beneficiary];
    }

    /**
    * @dev Extend parent behavior requiring purchase to respect the beneficiary&#39;s funding cap.
    * @param beneficiary Token purchaser
    * @param weiAmount Amount of wei contributed
    */
    function _preValidatePurchase(
        address beneficiary,
        uint256 weiAmount
    )
    internal
    {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(
            _contributions[beneficiary].add(weiAmount) <= _caps[beneficiary]);
    }

    /**
    * @dev Extend parent behavior to update beneficiary contributions
    * @param beneficiary Token purchaser
    * @param weiAmount Amount of wei contributed
    */
    function _updatePurchasingState(
        address beneficiary,
        uint256 weiAmount
    )
    internal
    {
        super._updatePurchasingState(beneficiary, weiAmount);
        _contributions[beneficiary] = _contributions[beneficiary].add(weiAmount);
    }

}

// File: openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol

/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 private _cap;

  /**
   * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
   * @param cap Max amount of wei to be contributed
   */
  constructor(uint256 cap) public {
    require(cap > 0);
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
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return weiRaised() >= _cap;
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
  {
    super._preValidatePurchase(beneficiary, weiAmount);
    require(weiRaised().add(weiAmount) <= _cap);
  }

}

// File: openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 private _openingTime;
  uint256 private _closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    require(isOpen());
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param openingTime Crowdsale opening time
   * @param closingTime Crowdsale closing time
   */
  constructor(uint256 openingTime, uint256 closingTime) public {
    // solium-disable-next-line security/no-block-members
    require(openingTime >= block.timestamp);
    require(closingTime >= openingTime);

    _openingTime = openingTime;
    _closingTime = closingTime;
  }

  /**
   * @return the crowdsale opening time.
   */
  function openingTime() public view returns(uint256) {
    return _openingTime;
  }

  /**
   * @return the crowdsale closing time.
   */
  function closingTime() public view returns(uint256) {
    return _closingTime;
  }

  /**
   * @return true if the crowdsale is open, false otherwise.
   */
  function isOpen() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > _closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param beneficiary Token purchaser
   * @param weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(beneficiary, weiAmount);
  }

}

// File: openzeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale with a one-off finalization action, where one
 * can do extra work after finishing.
 */
contract FinalizableCrowdsale is TimedCrowdsale {
  using SafeMath for uint256;

  bool private _finalized = false;

  event CrowdsaleFinalized();

  /**
   * @return true if the crowdsale is finalized, false otherwise.
   */
  function finalized() public view returns (bool) {
    return _finalized;
  }

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() public {
    require(!_finalized);
    require(hasClosed());

    _finalization();
    emit CrowdsaleFinalized();

    _finalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super._finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function _finalization() internal {
  }

}

// File: openzeppelin-solidity/contracts/access/roles/MinterRole.sol

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() public {
    minters.add(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    minters.add(account);
    emit MinterAdded(account);
  }

  function renounceMinter() public {
    minters.remove(msg.sender);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol

/**
 * @title ERC20Mintable
 * @dev ERC20 minting logic
 */
contract ERC20Mintable is ERC20, MinterRole {
  event MintingFinished();

  bool private _mintingFinished = false;

  modifier onlyBeforeMintingFinished() {
    require(!_mintingFinished);
    _;
  }

  /**
   * @return true if the minting is finished.
   */
  function mintingFinished() public view returns(bool) {
    return _mintingFinished;
  }

  /**
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens.
   * @param amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address to,
    uint256 amount
  )
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    _mint(to, amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting()
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    _mintingFinished = true;
    emit MintingFinished();
    return true;
  }
}

// File: openzeppelin-solidity/contracts/crowdsale/emission/MintedCrowdsale.sol

/**
 * @title MintedCrowdsale
 * @dev Extension of Crowdsale contract whose tokens are minted in each purchase.
 * Token ownership should be transferred to MintedCrowdsale for minting.
 */
contract MintedCrowdsale is Crowdsale {

  /**
   * @dev Overrides delivery by minting tokens upon purchase.
   * @param beneficiary Token purchaser
   * @param tokenAmount Number of tokens to be minted
   */
  function _deliverTokens(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    // Potentially dangerous assumption about the type of the token.
    require(
      ERC20Mintable(address(token())).mint(beneficiary, tokenAmount));
  }
}

// File: contracts/PlazaCrowdsale.sol

contract PlazaCrowdsale is CappedCrowdsale, FinalizableCrowdsale, MintedCrowdsale, WhitelistedCrowdsale, TieredPriceCrowdsale {
    constructor(
        uint256 openingTime,
        uint256 closingTime,
        uint256 rate,
        address wallet,
        uint256 cap,
        ERC20Mintable token,
        uint256 openingTimeTier4, 
        uint256 openingTimeTier3, 
        uint256 openingTimeTier2,
        uint256 invCap
    )
    public
    Crowdsale(rate, wallet, token)
    CappedCrowdsale(cap)
    WhitelistedCrowdsale(invCap)
    TimedCrowdsale(openingTime, closingTime)
    TieredPriceCrowdsale(rate, openingTimeTier2, openingTimeTier3, openingTimeTier4)
    {}

}