pragma solidity 0.4.23;

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
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

  // How many token units a buyer gets per wei
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
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
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
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
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

// File: contracts/PausableCrowdsale.sol

/**
 * @title PausableCrowdsale
 * @dev Extension of Crowdsale contract that can be paused and unpaused by owner
 */
contract PausableCrowdsale is Crowdsale, Pausable {

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal whenNotPaused {
    return super._preValidatePurchase(_beneficiary, _weiAmount);
  }
}

// File: contracts/interfaces/IDAVToken.sol

contract IDAVToken is ERC20 {

  function name() public view returns (string) {}
  function symbol() public view returns (string) {}
  function decimals() public view returns (uint8) {}
  function increaseApproval(address _spender, uint _addedValue) public returns (bool success);
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success);

  function owner() public view returns (address) {}
  function transferOwnership(address newOwner) public;

  function burn(uint256 _value) public;

  function pauseCutoffTime() public view returns (uint256) {}
  function paused() public view returns (bool) {}
  function pause() public;
  function unpause() public;
  function setPauseCutoffTime(uint256 _pauseCutoffTime) public;

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
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
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
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

// File: openzeppelin-solidity/contracts/crowdsale/distribution/FinalizableCrowdsale.sol

/**
 * @title FinalizableCrowdsale
 * @dev Extension of Crowdsale where an owner can do extra work
 * after finishing.
 */
contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

  /**
   * @dev Must be called after crowdsale ends, to do some extra finalization
   * work. Calls the contract&#39;s finalization function.
   */
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

  /**
   * @dev Can be overridden to add finalization logic. The overriding function
   * should call super.finalization() to ensure the chain of finalization is
   * executed entirely.
   */
  function finalization() internal {
  }

}

// File: contracts/DAVCrowdsale.sol

/**
 * @title DAVCrowdsale
 * @dev DAV Crowdsale contract
 */
contract DAVCrowdsale is PausableCrowdsale, FinalizableCrowdsale {

  // Opening time for Whitelist B
  uint256 public openingTimeB;
  // Sum of contributions in Wei, per beneficiary
  mapping(address => uint256) public contributions;
  // List of beneficiaries whitelisted in group A
  mapping(address => bool) public whitelistA;
  // List of beneficiaries whitelisted in group B
  mapping(address => bool) public whitelistB;
  // Maximum number of Wei that can be raised
  uint256 public weiCap;
  // Maximum number of Vincis that can be sold in Crowdsale
  uint256 public vinciCap;
  // Minimal contribution amount in Wei per transaction
  uint256 public minimalContribution;
  // Maximal total contribution amount in Wei per beneficiary
  uint256 public maximalIndividualContribution;
  // Maximal acceptable gas price
  uint256 public gasPriceLimit = 50000000000 wei;
  // Wallet to transfer foundation tokens to
  address public tokenWallet;
  // Wallet to transfer locked tokens to (e.g., presale buyers)
  address public lockedTokensWallet;
  // DAV Token
  IDAVToken public davToken;
  // Amount of Vincis sold
  uint256 public vinciSold;
  // Address of account that can manage the whitelist
  address public whitelistManager;

  constructor(uint256 _rate, address _wallet, address _tokenWallet, address _lockedTokensWallet, IDAVToken _token, uint256 _weiCap, uint256 _vinciCap, uint256 _minimalContribution, uint256 _maximalIndividualContribution, uint256 _openingTime, uint256 _openingTimeB, uint256 _closingTime) public
    Crowdsale(_rate, _wallet, _token)
    TimedCrowdsale(_openingTime, _closingTime)
  {
    require(_openingTimeB >= _openingTime);
    require(_openingTimeB <= _closingTime);
    require(_weiCap > 0);
    require(_vinciCap > 0);
    require(_minimalContribution > 0);
    require(_maximalIndividualContribution > 0);
    require(_minimalContribution <= _maximalIndividualContribution);
    require(_tokenWallet != address(0));
    require(_lockedTokensWallet != address(0));
    weiCap = _weiCap;
    vinciCap = _vinciCap;
    minimalContribution = _minimalContribution;
    maximalIndividualContribution = _maximalIndividualContribution;
    openingTimeB = _openingTimeB;
    tokenWallet = _tokenWallet;
    lockedTokensWallet= _lockedTokensWallet;
    davToken = _token;
    whitelistManager = msg.sender;
  }

  /**
   * @dev Modifier to make a function callable only if user is in whitelist A, or in whitelist B and openingTimeB has passed
   */
  modifier onlyWhitelisted(address _beneficiary) {
    require(whitelistA[_beneficiary] || (whitelistB[_beneficiary] && block.timestamp >= openingTimeB));
    _;
  }

  /**
   * @dev Throws if called by any account other than the whitelist manager
   */
  modifier onlyWhitelistManager() {
    require(msg.sender == whitelistManager);
    _;
  }

  /**
   * @dev Change the whitelist manager
   *
   * @param _whitelistManager Address of new whitelist manager
   */
  function setWhitelistManager(address _whitelistManager) external onlyOwner {
    require(_whitelistManager != address(0));
    whitelistManager= _whitelistManager;
  }

  /**
   * @dev Change the gas price limit
   *
   * @param _gasPriceLimit New gas price limit
   */
  function setGasPriceLimit(uint256 _gasPriceLimit) external onlyOwner {
    gasPriceLimit = _gasPriceLimit;
  }

  /**
   * Add a group of users to whitelist A
   *
   * @param _beneficiaries List of addresses to be whitelisted
   */
  function addUsersWhitelistA(address[] _beneficiaries) external onlyWhitelistManager {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelistA[_beneficiaries[i]] = true;
    }
  }

  /**
   * Add a group of users to whitelist B
   *
   * @param _beneficiaries List of addresses to be whitelisted
   */
  function addUsersWhitelistB(address[] _beneficiaries) external onlyWhitelistManager {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelistB[_beneficiaries[i]] = true;
    }
  }

  /**
   * Remove a group of users from whitelist A
   *
   * @param _beneficiaries List of addresses to be removed from whitelist
   */
  function removeUsersWhitelistA(address[] _beneficiaries) external onlyWhitelistManager {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelistA[_beneficiaries[i]] = false;
    }
  }

  /**
   * Remove a group of users from whitelist B
   *
   * @param _beneficiaries List of addresses to be removed from whitelist
   */
  function removeUsersWhitelistB(address[] _beneficiaries) external onlyWhitelistManager {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelistB[_beneficiaries[i]] = false;
    }
  }

  /**
   * Allow adjustment of the closing time
   *
   * @param _closingTime Time to close the sale. If in the past will set to the present
   */
  function closeEarly(uint256 _closingTime) external onlyOwner onlyWhileOpen {
    // Make sure the new closing time isn&#39;t after the old closing time
    require(_closingTime <= closingTime);
    // solium-disable-next-line security/no-block-members
    if (_closingTime < block.timestamp) {
      // If closing time is in the past, set closing time to right now
      closingTime = block.timestamp;
    } else {
      // Update the closing time
      closingTime = _closingTime;
    }
  }

  /**
   * Record a transaction that happened during the presale and transfer tokens to locked tokens wallet
   *
   * @param _weiAmount Value in wei involved in the purchase
   * @param _vinciAmount Amount of Vincis sold
   */
  function recordSale(uint256 _weiAmount, uint256 _vinciAmount) external onlyOwner {
    // Verify that the amount won&#39;t put us over the wei cap
    require(weiRaised.add(_weiAmount) <= weiCap);
    // Verify that the amount won&#39;t put us over the vinci cap
    require(vinciSold.add(_vinciAmount) <= vinciCap);
    // Verify Crowdsale hasn&#39;t been finalized yet
    require(!isFinalized);
    // Update crowdsale totals
    weiRaised = weiRaised.add(_weiAmount);
    vinciSold = vinciSold.add(_vinciAmount);
    // Transfer tokens
    token.transfer(lockedTokensWallet, _vinciAmount);
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    // Verify that the amount won&#39;t put us over the wei cap
    require(weiRaised.add(_weiAmount) <= weiCap);
    // Verify that the amount won&#39;t put us over the vinci cap
    require(vinciSold.add(_weiAmount.mul(rate)) <= vinciCap);
    // Verify amount is larger than or equal to minimal contribution
    require(_weiAmount >= minimalContribution);
    // Verify that the gas price is lower than 50 gwei
    require(tx.gasprice <= gasPriceLimit);
    // Verify that user hasn&#39;t contributed more than the individual hard cap
    require(contributions[_beneficiary].add(_weiAmount) <= maximalIndividualContribution);
  }

  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    super._updatePurchasingState(_beneficiary, _weiAmount);
    // Update user contribution total
    contributions[_beneficiary] = contributions[_beneficiary].add(_weiAmount);
    // Update total Vincis sold
    vinciSold = vinciSold.add(_weiAmount.mul(rate));
  }

  function finalization() internal {
    super.finalization();
    // transfer tokens to foundation
    uint256 foundationTokens = weiRaised.div(2).add(weiRaised);
    foundationTokens = foundationTokens.mul(rate);
    uint256 crowdsaleBalance = davToken.balanceOf(this);
    if (crowdsaleBalance < foundationTokens) {
      foundationTokens = crowdsaleBalance;
    }
    davToken.transfer(tokenWallet, foundationTokens);
    // Burn off remaining tokens
    crowdsaleBalance = davToken.balanceOf(this);
    davToken.burn(crowdsaleBalance);
    // Set token&#39;s pause cutoff time to 3 weeks from closing time
    davToken.setPauseCutoffTime(closingTime.add(1814400));
    // transfer token Ownership back to original owner
    davToken.transferOwnership(owner);
  }

}