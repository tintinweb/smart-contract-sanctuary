pragma solidity ^0.4.23;

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
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

// File: openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overriden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using &#39;super&#39; where appropiate to concatenate
 * behavior.
 */
contract Crowdsale {
  using SafeMath for uint256;

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
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
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
    token.transfer(_beneficiary, _tokenAmount);
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

// File: contracts/ZeexWhitelistedCrowdsale.sol

contract ZeexWhitelistedCrowdsale is Crowdsale, Ownable {

  address public whitelister;
  mapping(address => bool) public whitelist;

  constructor(address _whitelister) public {
    require(_whitelister != address(0));
    whitelister = _whitelister;
  }

  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

  function addToWhitelist(address _beneficiary) public onlyOwnerOrWhitelister {
    whitelist[_beneficiary] = true;
  }

  function addManyToWhitelist(address[] _beneficiaries) public onlyOwnerOrWhitelister {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  function removeFromWhitelist(address _beneficiary) public onlyOwnerOrWhitelister {
    whitelist[_beneficiary] = false;
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

  modifier onlyOwnerOrWhitelister() {
    require(msg.sender == owner || msg.sender == whitelister);
    _;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
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

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
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
   *
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
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint _addedValue
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
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

// File: openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/openzeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
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
   * @param _beneficiary Token purchaser
   * @param _tokenAmount Number of tokens to be minted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}

// File: openzeppelin-solidity/contracts/crowdsale/validation/CappedCrowdsale.sol

/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  /**
   * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
   * @param _cap Max amount of wei to be contributed
   */
  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

  /**
   * @dev Checks whether the cap has been reached.
   * @return Whether the cap was reached
   */
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

  /**
   * @dev Extend parent behavior requiring purchase to respect the funding cap.
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
  }

}

// File: openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
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

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
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

// File: contracts/ZeexCrowdsale.sol

contract ZeexCrowdsale is CappedCrowdsale, MintedCrowdsale, TimedCrowdsale, Pausable, ZeexWhitelistedCrowdsale {
  using SafeMath for uint256;

  uint256 public presaleOpeningTime;
  uint256 public presaleClosingTime;
  uint256 public presaleBonus = 25;
  uint256 public minPresaleWei;
  uint256 public maxPresaleWei;

  bytes1 public constant publicPresale = "0";
  bytes1 public constant privatePresale = "1";

  address[] public bonusUsers;
  mapping(address => mapping(bytes1 => uint256)) public bonusTokens;

  event Lock(address user, uint amount, bytes1 tokenType);
  event ReleaseLockedTokens(bytes1 tokenType, address user, uint amount, address to);

  constructor(uint256 _openingTime, uint256 _closingTime, uint hardCapWei,
    uint256 _presaleOpeningTime, uint256 _presaleClosingTime,
    uint256 _minPresaleWei, uint256 _maxPresaleWei,
    address _wallet, MintableToken _token, address _whitelister) public
    Crowdsale(5000, _wallet, _token)
    CappedCrowdsale(hardCapWei)
    TimedCrowdsale(_openingTime, _closingTime)
    validPresaleClosingTime(_presaleOpeningTime, _presaleClosingTime)
    ZeexWhitelistedCrowdsale(_whitelister) {

    require(_presaleOpeningTime >= openingTime);
    require(_maxPresaleWei >= _minPresaleWei);

    presaleOpeningTime = _presaleOpeningTime;
    presaleClosingTime = _presaleClosingTime;
    minPresaleWei = _minPresaleWei;
    maxPresaleWei = _maxPresaleWei;

    paused = true;
  }

  // Overrides
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal whenNotPaused {
    super._preValidatePurchase(_beneficiary, _weiAmount);

    if (isPresaleOn()) {
      require(_weiAmount >= minPresaleWei && _weiAmount <= maxPresaleWei);
    }
  }

  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate).add(getPresaleBonusAmount(_weiAmount));
  }

  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    uint256 weiAmount = msg.value;
    uint256 lockedAmount = getPresaleBonusAmount(weiAmount);
    uint256 unlockedAmount = _tokenAmount.sub(lockedAmount);

    if (lockedAmount > 0) {
      lockAndDeliverTokens(_beneficiary, lockedAmount, publicPresale);
    }

    _deliverTokens(_beneficiary, unlockedAmount);
  }
  // End of Overrides

  function grantTokens(address _beneficiary, uint256 _tokenAmount) public onlyOwner {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  function grantBonusTokens(address _beneficiary, uint256 _tokenAmount) public onlyOwner {
    lockAndDeliverTokens(_beneficiary, _tokenAmount, privatePresale);
  }

  // lock tokens section

  function lockAndDeliverTokens(address _beneficiary, uint256 _tokenAmount, bytes1 _type) internal {
    lockBonusTokens(_beneficiary, _tokenAmount, _type);
    _deliverTokens(address(this), _tokenAmount);
  }

  function lockBonusTokens(address _beneficiary, uint256 _amount, bytes1 _type) internal {
    if (bonusTokens[_beneficiary][publicPresale] == 0 && bonusTokens[_beneficiary][privatePresale] == 0) {
      bonusUsers.push(_beneficiary);
    }

    bonusTokens[_beneficiary][_type] = bonusTokens[_beneficiary][_type].add(_amount);
    emit Lock(_beneficiary, _amount, _type);
  }

  function getBonusBalance(uint _from, uint _to) public view returns (uint total) {
    require(_from >= 0 && _to >= _from && _to <= bonusUsers.length);

    for (uint i = _from; i < _to; i++) {
      total = total.add(getUserBonusBalance(bonusUsers[i]));
    }
  }

  function getBonusBalanceByType(uint _from, uint _to, bytes1 _type) public view returns (uint total) {
    require(_from >= 0 && _to >= _from && _to <= bonusUsers.length);

    for (uint i = _from; i < _to; i++) {
      total = total.add(bonusTokens[bonusUsers[i]][_type]);
    }
  }

  function getUserBonusBalanceByType(address _user, bytes1 _type) public view returns (uint total) {
    return bonusTokens[_user][_type];
  }

  function getUserBonusBalance(address _user) public view returns (uint total) {
    total = total.add(getUserBonusBalanceByType(_user, publicPresale));
    total = total.add(getUserBonusBalanceByType(_user, privatePresale));
  }

  function getBonusUsersCount() public view returns(uint count) {
    return bonusUsers.length;
  }

  function releasePublicPresaleBonusTokens(address[] _users, uint _percentage) public onlyOwner {
    require(_percentage > 0 && _percentage <= 100);

    for (uint i = 0; i < _users.length; i++) {
      address user = _users[i];
      uint tokenBalance = bonusTokens[user][publicPresale];
      uint amount = tokenBalance.mul(_percentage).div(100);
      releaseBonusTokens(user, amount, user, publicPresale);
    }
  }

  function releaseUserPrivateBonusTokens(address _user, uint _amount, address _to) public onlyOwner {
    releaseBonusTokens(_user, _amount, _to, privatePresale);
  }

  function releasePrivateBonusTokens(address[] _users, uint[] _amounts) public onlyOwner {
    for (uint i = 0; i < _users.length; i++) {
      address user = _users[i];
      uint amount = _amounts[i];
      releaseBonusTokens(user, amount, user, privatePresale);
    }
  }

  function releaseBonusTokens(address _user, uint _amount, address _to, bytes1 _type) internal onlyOwner {
    uint tokenBalance = bonusTokens[_user][_type];
    require(tokenBalance >= _amount);

    bonusTokens[_user][_type] = bonusTokens[_user][_type].sub(_amount);
    token.transfer(_to, _amount);
    emit ReleaseLockedTokens(_type, _user, _amount, _to);
  }

  // Presale section
  function getPresaleBonusAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint256 tokenAmount = 0;
    if (isPresaleOn()) tokenAmount = (_weiAmount.mul(presaleBonus).div(100)).mul(rate);

    return tokenAmount;
  }

  function updatePresaleMinWei(uint _minPresaleWei) public onlyOwner {
    require(maxPresaleWei >= _minPresaleWei);

    minPresaleWei = _minPresaleWei;
  }

  function updatePresaleMaxWei(uint _maxPresaleWei) public onlyOwner {
    require(_maxPresaleWei >= minPresaleWei);

    maxPresaleWei = _maxPresaleWei;
  }

  function updatePresaleBonus(uint _presaleBonus) public onlyOwner {
    presaleBonus = _presaleBonus;
  }

  function isPresaleOn() public view returns (bool) {
    return block.timestamp >= presaleOpeningTime && block.timestamp <= presaleClosingTime;
  }

  modifier validPresaleClosingTime(uint _presaleOpeningTime, uint _presaleClosingTime) {
    require(_presaleOpeningTime >= openingTime);
    require(_presaleClosingTime >= _presaleOpeningTime);
    require(_presaleClosingTime <= closingTime);
    _;
  }

  function setOpeningTime(uint256 _openingTime) public onlyOwner {
    require(_openingTime >= block.timestamp);
    require(presaleOpeningTime >= _openingTime);
    require(closingTime >= _openingTime);

    openingTime = _openingTime;
  }

  function setPresaleClosingTime(uint _presaleClosingTime) public onlyOwner validPresaleClosingTime(presaleOpeningTime, _presaleClosingTime) {
    presaleClosingTime = _presaleClosingTime;
  }

  function setPresaleOpeningClosingTime(uint256 _presaleOpeningTime, uint256 _presaleClosingTime) public onlyOwner validPresaleClosingTime(_presaleOpeningTime, _presaleClosingTime) {
    presaleOpeningTime = _presaleOpeningTime;
    presaleClosingTime = _presaleClosingTime;
  }

  function setClosingTime(uint256 _closingTime) public onlyOwner {
    require(_closingTime >= block.timestamp);
    require(_closingTime >= openingTime);

    closingTime = _closingTime;
  }

  function setOpeningClosingTime(uint256 _openingTime, uint256 _closingTime) public onlyOwner {
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  function transferTokenOwnership(address _to) public onlyOwner {
    Ownable(token).transferOwnership(_to);
  }
}