pragma solidity ^0.4.24;

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

contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

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

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
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
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
   * Example from CappedCrowdsale.sol&#39;s _preValidatePurchase method: 
   *   super._preValidatePurchase(_beneficiary, _weiAmount);
   *   require(weiRaised.add(_weiAmount) <= cap);
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor(uint256 _openingTime, uint256 _closingTime) public {
    // solium-disable-next-line security/no-block-members
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

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
    public
    onlyOwner
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
    public
    onlyOwner
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
    public
    onlyOwner
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
    public
    onlyOwner
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
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

contract TokenDestructible is Ownable {

  constructor() public payable { }

  /**
   * @notice Terminate contract and refund to owner
   * @param _tokens List of addresses of ERC20 or ERC20Basic token contracts to
   refund.
   * @notice The called token contracts could try to re-enter this contract. Only
   supply token contracts you trust.
   */
  function destroy(address[] _tokens) public onlyOwner {

    // Transfer tokens to owner
    for (uint256 i = 0; i < _tokens.length; i++) {
      ERC20Basic token = ERC20Basic(_tokens[i]);
      uint256 balance = token.balanceOf(this);
      token.transfer(owner, balance);
    }

    // Transfer Eth to owner and terminate contract
    selfdestruct(owner);
  }
}

contract VictorTokenSale is TimedCrowdsale, Ownable, Whitelist, TokenDestructible {

  using SafeMath for uint256;



  // stage bonus

  uint256 public constant STAGE_1_BONUS_RT = 35;

  uint256 public constant STAGE_2_BONUS_RT = 30;

  uint256 public constant STAGE_3_BONUS_RT = 25;

  uint256 public constant STAGE_4_BONUS_RT = 20;

  uint256 public constant STAGE_5_BONUS_RT = 15;

  uint256 public constant STAGE_6_BONUS_RT = 10;

  uint256 public constant STAGE_7_BONUS_RT =  5;



  // BOUNDARY ethereum conv:  22000 / 44000 / 66000 / 88000 / 110000 / 132000 / 154000

  // This is wei * 25000 limit.

  uint256 public constant BOUNDARY_1 =  550000000000000000000000000;

  uint256 public constant BOUNDARY_2 = 1100000000000000000000000000;

  uint256 public constant BOUNDARY_3 = 1650000000000000000000000000;

  uint256 public constant BOUNDARY_4 = 2200000000000000000000000000;

  uint256 public constant BOUNDARY_5 = 2750000000000000000000000000;

  uint256 public constant BOUNDARY_6 = 3300000000000000000000000000;

  uint256 public constant BOUNDARY_7 = 3850000000000000000000000000; // End of Sales amount



  VictorToken _token;



  uint256 public bonusRate;

  uint256 public calcAdditionalRatio;

  uint256 public cumulativeSumofToken = 0;



  uint256 public minimum_buy_limit = 0.1 ether;

  uint256 public maximum_buy_limit = 1000 ether;



  event SetPeriod(uint256 _openingTime, uint256 _closingTime);

  event SetBuyLimit(uint256 _minLimit, uint256 _maxLimit);



  // ----------------------------------------------------------------------------------- 

  // Constructor

  // ----------------------------------------------------------------------------------- 

  // Fixed exchange ratio: 25000 (FIXED!)

  // Fixed period of sale: 16 weeks from now set as sales period (changeable)

  constructor(

    VictorToken _token_,

    address _wallet

  )

    public

    Crowdsale(25000, _wallet, _token_)

    TimedCrowdsale(block.timestamp, block.timestamp + 16 weeks)

  {

    _token = _token_;



    emit SetPeriod(openingTime, closingTime);



    calcBonusRate();

  }



  // -----------------------------------------------------------------------------------

  // override fuction.

  // -----------------------------------------------------------------------------------

  function _preValidatePurchase(

    address _beneficiary,

    uint256 _weiAmount

  )

    onlyWhileOpen

    onlyIfWhitelisted(_beneficiary)

    internal

  {

    require(_beneficiary != address(0));

    require(_weiAmount >= minimum_buy_limit);

    require(_weiAmount <= maximum_buy_limit);

    require(BOUNDARY_7 >= (cumulativeSumofToken + _weiAmount));

  }



  // override fuction. default + bonus token

  function _getTokenAmount(

    uint256 _weiAmount

  )

    internal

    view

    returns (uint256)

  {

    return (_weiAmount.mul(rate)).add(_weiAmount.mul(calcAdditionalRatio)) ;

  }



  // override fuction.

  // bonus token locking

  // stage bonus boundary check and change.

  function _updatePurchasingState(

    address _beneficiary,

    uint256 _weiAmount

  )

    internal

  {

    uint256 lockBalance = _weiAmount.mul(calcAdditionalRatio);



    _token.increaseLockBalance(_beneficiary, lockBalance);

    

    cumulativeSumofToken = cumulativeSumofToken.add(_weiAmount.mul(rate));



    calcBonusRate();



    return;

  }



  // -----------------------------------------------------------------------------------

  // Utility function

  // -----------------------------------------------------------------------------------

  // Bonus rate calcuration.

  function calcBonusRate()

    public

  {

    if      (cumulativeSumofToken >=          0 && cumulativeSumofToken < BOUNDARY_1 && bonusRate != STAGE_1_BONUS_RT)

    {

      bonusRate = STAGE_1_BONUS_RT;

      calcAdditionalRatio = (rate.mul(bonusRate)).div(100);

    }

    else if (cumulativeSumofToken >= BOUNDARY_1 && cumulativeSumofToken < BOUNDARY_2 && bonusRate != STAGE_2_BONUS_RT)

    {

      bonusRate = STAGE_2_BONUS_RT;

      calcAdditionalRatio = (rate.mul(bonusRate)).div(100);

    }

    else if (cumulativeSumofToken >= BOUNDARY_2 && cumulativeSumofToken < BOUNDARY_3 && bonusRate != STAGE_3_BONUS_RT)

    {

      bonusRate = STAGE_3_BONUS_RT;

      calcAdditionalRatio = (rate.mul(bonusRate)).div(100);

    }

    else if (cumulativeSumofToken >= BOUNDARY_3 && cumulativeSumofToken < BOUNDARY_4 && bonusRate != STAGE_4_BONUS_RT)

    {

      bonusRate = STAGE_4_BONUS_RT;

      calcAdditionalRatio = (rate.mul(bonusRate)).div(100);

    }

    else if (cumulativeSumofToken >= BOUNDARY_4 && cumulativeSumofToken < BOUNDARY_5 && bonusRate != STAGE_5_BONUS_RT)

    {

      bonusRate = STAGE_5_BONUS_RT;

      calcAdditionalRatio = (rate.mul(bonusRate)).div(100);

    }

    else if (cumulativeSumofToken >= BOUNDARY_5 && cumulativeSumofToken < BOUNDARY_6 && bonusRate != STAGE_6_BONUS_RT)

    {

      bonusRate = STAGE_6_BONUS_RT;

      calcAdditionalRatio = (rate.mul(bonusRate)).div(100);

    }

    else if (cumulativeSumofToken >= BOUNDARY_6 && cumulativeSumofToken < BOUNDARY_7 && bonusRate != STAGE_7_BONUS_RT)

    {

      bonusRate = STAGE_7_BONUS_RT;

      calcAdditionalRatio = (rate.mul(bonusRate)).div(100);

    }

    else if (cumulativeSumofToken >= BOUNDARY_7)

    {

      bonusRate = 0;

      calcAdditionalRatio = (rate.mul(bonusRate)).div(100);

    }

    

    return;

  }



  // Change open, close time and bonus rate. _openingTime, _closingTime is epoch (like 1532919600)

  function changePeriod(

    uint256 _openingTime,

    uint256 _closingTime

  )

    onlyOwner

    external

    returns (bool)

  {

    require(_openingTime >= block.timestamp);

    require(_closingTime >= _openingTime);



    openingTime = _openingTime;

    closingTime = _closingTime;



    calcAdditionalRatio = (rate.mul(bonusRate)).div(100);



    emit SetPeriod(openingTime, closingTime);



    return true;

  }



  // Buyer limit change

  function changeLimit(

    uint256 _minLimit,

    uint256 _maxLimit

  )

    onlyOwner

    external

    returns (bool)

  {

    require(_minLimit >= 0 ether);

    require(_maxLimit >= 3 ether);



    minimum_buy_limit = _minLimit;

    maximum_buy_limit = _maxLimit;



    emit SetBuyLimit(minimum_buy_limit, maximum_buy_limit);



    return true;

  }



  // bonus drop. Bonus tokens take a lock.

  function bonusDrop(

    address _beneficiary,

    uint256 _tokenAmount

  )

    onlyOwner

    external

    returns (bool)

  {

    _processPurchase(_beneficiary, _tokenAmount);



    emit TokenPurchase(

      msg.sender,

      _beneficiary,

      0,

      _tokenAmount

    );



    _token.increaseLockBalance(_beneficiary, _tokenAmount);



    return true;

  }



  // bonus drop. Bonus tokens are not locked !!!

  function unlockBonusDrop(

    address _beneficiary,

    uint256 _tokenAmount

  )

    onlyOwner

    external

    returns (bool)

  {

    _processPurchase(_beneficiary, _tokenAmount);



    emit TokenPurchase(

      msg.sender,

      _beneficiary,

      0,

      _tokenAmount

    );



    return true;

  }



  // -----------------------------------------------------------------------------------

  // Token Interface

  // -----------------------------------------------------------------------------------

  // Increases the lock on the balance at a specific address.

  function increaseTokenLock(

    address _beneficiary,

    uint256 _tokenAmount

  )

    onlyOwner

    external

    returns (bool)

  {

    return(_token.increaseLockBalance(_beneficiary, _tokenAmount));

  }



  // Decreases the lock on the balance at a specific address.

  function decreaseTokenLock(

    address _beneficiary,

    uint256 _tokenAmount

  )

    onlyOwner

    external

    returns (bool)

  {

    return(_token.decreaseLockBalance(_beneficiary, _tokenAmount));

  }



  // It completely unlocks a specific address.

  function clearTokenLock(

    address _beneficiary

  )

    onlyOwner

    external

    returns (bool)

  {

    return(_token.clearLock(_beneficiary));

  }



  // Redefine the point at which a lock that affects the whole is released.

  function resetLockReleaseTime(

    address _beneficiary,

    uint256 _releaseTime

  )

    onlyOwner

    external

    returns (bool)

  {

    return(_token.setReleaseTime(_beneficiary, _releaseTime));

  }



  // Attention of administrator is required!! Migrate the owner of the token.

  function transferTokenOwnership(

    address _newOwner

  )

    onlyOwner

    external

    returns (bool)

  {

    _token.transferOwnership(_newOwner);

    return true;

  }



  // Stops the entire transaction of the token completely.

  function pauseToken()

    onlyOwner

    external

    returns (bool)

  {

    _token.pause();

    return true;

  }



  // Resume a suspended transaction.

  function unpauseToken()

    onlyOwner

    external

    returns (bool)

  {

    _token.unpause();

    return true;

  }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

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
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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

library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
    if (_subtractedValue >= oldValue) {
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

contract IndividualLockableToken is PausableToken{

  using SafeMath for uint256;



  event LockTimeSetted(address indexed holder, uint256 old_release_time, uint256 new_release_time);

  event Locked(address indexed holder, uint256 locked_balance_change, uint256 total_locked_balance, uint256 release_time);



  struct lockState {

    uint256 locked_balance;

    uint256 release_time;

  }



  // default lock period

  uint256 public lock_period = 24 weeks;



  mapping(address => lockState) internal userLock;



  // Specify the time that a particular person&#39;s lock will be released

  function setReleaseTime(address _holder, uint256 _release_time)

    public

    onlyOwner

    returns (bool)

  {

    require(_holder != address(0));

	require(_release_time >= block.timestamp);



	uint256 old_release_time = userLock[_holder].release_time;



	userLock[_holder].release_time = _release_time;

	emit LockTimeSetted(_holder, old_release_time, userLock[_holder].release_time);

	return true;

  }

  

  // Returns the point at which token holder&#39;s lock is released

  function getReleaseTime(address _holder)

    public

    view

    returns (uint256)

  {

    require(_holder != address(0));



	return userLock[_holder].release_time;

  }



  // Unlock a specific person. Free trading even with a lock balance

  function clearReleaseTime(address _holder)

    public

    onlyOwner

    returns (bool)

  {

    require(_holder != address(0));

    require(userLock[_holder].release_time > 0);



	uint256 old_release_time = userLock[_holder].release_time;



	userLock[_holder].release_time = 0;

	emit LockTimeSetted(_holder, old_release_time, userLock[_holder].release_time);

	return true;

  }



  // Increase the lock balance of a specific person.

  // If you only want to increase the balance, the release_time must be specified in advance.

  function increaseLockBalance(address _holder, uint256 _value)

    public

    onlyOwner

    returns (bool)

  {

	require(_holder != address(0));

	require(_value > 0);

	require(balances[_holder] >= _value);

	

	if (userLock[_holder].release_time == 0) {

		userLock[_holder].release_time = block.timestamp + lock_period;

	}

	

	userLock[_holder].locked_balance = (userLock[_holder].locked_balance).add(_value);

	emit Locked(_holder, _value, userLock[_holder].locked_balance, userLock[_holder].release_time);

	return true;

  }



  // Decrease the lock balance of a specific person.

  function decreaseLockBalance(address _holder, uint256 _value)

    public

    onlyOwner

    returns (bool)

  {

	require(_holder != address(0));

	require(_value > 0);

	require(userLock[_holder].locked_balance >= _value);



	userLock[_holder].locked_balance = (userLock[_holder].locked_balance).sub(_value);

	emit Locked(_holder, _value, userLock[_holder].locked_balance, userLock[_holder].release_time);

	return true;

  }



  // Clear the lock.

  function clearLock(address _holder)

    public

    onlyOwner

    returns (bool)

  {

	require(_holder != address(0));

	require(userLock[_holder].release_time > 0);



	userLock[_holder].locked_balance = 0;

	userLock[_holder].release_time = 0;

	emit Locked(_holder, 0, userLock[_holder].locked_balance, userLock[_holder].release_time);

	return true;

  }



  // Check the amount of the lock

  function getLockedBalance(address _holder)

    public

    view

    returns (uint256)

  {

    if(block.timestamp >= userLock[_holder].release_time) return uint256(0);

    return userLock[_holder].locked_balance;

  }



  // Check your remaining balance

  function getFreeBalance(address _holder)

    public

    view

    returns (uint256)

  {

    if(block.timestamp >= userLock[_holder].release_time) return balances[_holder];

    return balances[_holder].sub(userLock[_holder].locked_balance);

  }



  // transfer overrride

  function transfer(

    address _to,

    uint256 _value

  )

    public

    returns (bool)

  {

    require(getFreeBalance(msg.sender) >= _value);

    return super.transfer(_to, _value);

  }



  // transferFrom overrride

  function transferFrom(

    address _from,

    address _to,

    uint256 _value

  )

    public

    returns (bool)

  {

    require(getFreeBalance(_from) >= _value);

    return super.transferFrom(_from, _to, _value);

  }



  // approve overrride

  function approve(

    address _spender,

    uint256 _value

  )

    public

    returns (bool)

  {

    require(getFreeBalance(msg.sender) >= _value);

    return super.approve(_spender, _value);

  }



  // increaseApproval overrride

  function increaseApproval(

    address _spender,

    uint _addedValue

  )

    public

    returns (bool success)

  {

    require(getFreeBalance(msg.sender) >= allowed[msg.sender][_spender].add(_addedValue));

    return super.increaseApproval(_spender, _addedValue);

  }

  

  // decreaseApproval overrride

  function decreaseApproval(

    address _spender,

    uint _subtractedValue

  )

    public

    returns (bool success)

  {

	uint256 oldValue = allowed[msg.sender][_spender];

	

    if (_subtractedValue < oldValue) {

      require(getFreeBalance(msg.sender) >= oldValue.sub(_subtractedValue));	  

    }    

    return super.decreaseApproval(_spender, _subtractedValue);

  }

}

contract VictorToken is IndividualLockableToken, TokenDestructible {

  using SafeMath for uint256;



  string public constant name = "VictorToken";

  string public constant symbol = "VIC";

  uint8  public constant decimals = 18;



  // 10,000,000,000 10 billion

  uint256 public constant INITIAL_SUPPLY = 10000000000 * (10 ** uint256(decimals));



  constructor()

    public

  {

    totalSupply_ = INITIAL_SUPPLY;

    balances[msg.sender] = totalSupply_;

  }

}