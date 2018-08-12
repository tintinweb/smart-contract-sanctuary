pragma solidity ^0.4.23;

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

contract Token {
  function transfer(address _to, uint256 _value) public returns (bool);
  function endIco() public returns (bool);
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
contract Crowdsale is Ownable {
  using SafeMath for uint256;

  // The token being sold
  Token public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per ether. (1 token 0.09 USD for ETH/USD = 700)
  uint256 public rate = 7778;

  // Amount of wei raised
  uint256 public weiRaised;

  // Pre ICO start and end date
  uint256 public preIcoStartTime = 1533018295;
  uint256 public preIcoEndTime = 1533018295;

  // ICO start and end date
  uint256 public icoStartTime = 1533018295;
  uint256 public icoEndTime = 1533018295;

  // discount in %
  uint256 public preIcoDiscount = 20;
  uint256 public icoDiscount = 5;

  // min contribution in wei
  uint256 public preIcoMin = 10 finney;
  uint256 public icoMin = 10 finney;

  // hardcaps in tokens
  uint256 public preIcoCap = uint256(10000000).mul(1 ether);
  uint256 public icoCap = uint256(110000000).mul(1 ether);

  // tokens sold
  uint256 public preIcoSold;
  uint256 public icoSold;

  // ICO end set
  bool icoEnd = false;

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
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(address _newOwner, address _wallet, Token _token) public {
    require(_wallet != address(0));
    require(_token != address(0));

    owner = _newOwner;
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
   * @dev setting date and time
   * @param _timestamp Can use https://www.unixtimestamp.com/ for the timestamp estimating
   */

  function setPreIcoStart (uint256 _timestamp) public onlyOwner {
    require(_timestamp > 0);
    preIcoStartTime = _timestamp;
    if (preIcoEndTime < _timestamp) preIcoEndTime = _timestamp;
    if (icoStartTime < _timestamp) icoStartTime = _timestamp;
    if (icoEndTime < _timestamp) icoEndTime = _timestamp;
  }

  /**
   * @dev setting date and time
   * @param _timestamp Can use https://www.unixtimestamp.com/ for the timestamp estimating
   */

  function setPreIcoEnd (uint256 _timestamp) public onlyOwner {
    require(_timestamp > preIcoStartTime);
    preIcoEndTime = _timestamp;
    if (icoStartTime < _timestamp) icoStartTime = _timestamp;
    if (icoEndTime < _timestamp) icoEndTime = _timestamp;
  }

  /**
   * @dev setting date and time
   * @param _timestamp Can use https://www.unixtimestamp.com/ for the timestamp estimating
   */

  function setIcoStart (uint256 _timestamp) public onlyOwner {
    require(_timestamp > preIcoEndTime);
    icoStartTime = _timestamp;
    if (icoEndTime < _timestamp) icoEndTime = _timestamp;
  }

  /**
   * @dev setting date and time
   * @param _timestamp Can use https://www.unixtimestamp.com/ for the timestamp estimating
   */

  function setIcoEnd (uint256 _timestamp) public onlyOwner {
    require(_timestamp > icoStartTime);
    icoEndTime = _timestamp;
  }

  /**
   * @dev setting cap
   * @param _cap (real amount without decimal zeroes)
   */

  function setPreIcoCap (uint256 _cap) public onlyOwner {
    preIcoCap = _cap.mul(1 ether);
  }

  /**
   * @dev setting cap
   * @param _cap (real amount without decimal zeroes)
   */

  function setIcoCap (uint256 _cap) public onlyOwner {
    icoCap = _cap.mul(1 ether);
  }

  /**
   * @dev setting discount
   * @param _discount in %
   */

  function setPreIcoDiscount (uint256 _discount) public onlyOwner {
    require(_discount >= 0);
    require(_discount < 100);
    preIcoDiscount = _discount;
  }

  /**
   * @dev setting discount
   * @param _discount in %
   */

  function setIcoDiscount (uint256 _discount) public onlyOwner {
    require(_discount >= 0);
    require(_discount < 100);
    icoDiscount = _discount;
  }

  /**
   * @dev setting minimal contribution
   * @param _min in finney (1 ether = 1000 finney)
   */

  function setPreIcoMin (uint256 _min) public onlyOwner {
    preIcoMin = _min.mul(1 finney);
  }

  /**
   * @dev setting minimal contribution
   * @param _min in finney (1 ether = 1000 finney)
   */

  function setIcoMin (uint256 _min) public onlyOwner {
    icoMin = _min.mul(1 finney);
  }

  /**
   * @dev getting stage index (pre ICO = 1, ICO = 2, pause = 0, end = 9)
   */

  function _getStageIndex () internal view returns (uint8) {
    if (now >= preIcoStartTime && now <= preIcoEndTime) return 1;
    if (now >= icoStartTime && now <= icoEndTime) return 2;
    if (now > icoEndTime) return 9;
    return 0;
  }

  /**
   * @dev getting stage name
   */

  function getStageName () public returns (string) {
    uint8 stageIndex = _getStageIndex();
    if (stageIndex == 0) return &#39;Pause&#39;;
    if (stageIndex == 1) return &#39;Pre ICO&#39;;
    if (stageIndex == 2) return &#39;ICO&#39;;
    if (stageIndex == 9) {
      if (!icoEnd && token.endIco()) icoEnd = true;
      return &#39;ICO is over&#39;;
    }
    return &#39;Pause&#39;;
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    uint8 stageIndex = _getStageIndex();

    require(!icoEnd);

    if (stageIndex == 9) {
      if (token.endIco()) icoEnd = true;
    }

    _preValidatePurchase(_beneficiary, weiAmount, stageIndex);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount, stageIndex);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    if (stageIndex == 1) preIcoSold = preIcoSold.add(tokens);
    if (stageIndex == 2) icoSold = icoSold.add(tokens);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _forwardFunds();
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
    uint256 _weiAmount,
    uint8 _stageIndex
  )
    internal view
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);

    if (_stageIndex == 1) require(_weiAmount >= preIcoMin);
    else if (_stageIndex == 2) require(_weiAmount >= icoMin);
    else revert();
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
    require(token.transfer(_beneficiary, _tokenAmount));
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
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount, uint8 _stageIndex)
    internal view returns (uint256)
  {
    uint256 discount;
    uint256 cap;
    if (_stageIndex == 1) {
      discount = preIcoDiscount;
      cap = preIcoCap.sub(preIcoSold);
    } else if (_stageIndex == 2) {
      discount = icoDiscount;
      cap = icoCap.sub(icoSold);
    }
    uint256 diff = uint256(100).sub(discount);
    uint256 rateWithDiscount = rate.mul(100).div(diff);
    uint256 tokenAmount = _weiAmount.mul(rateWithDiscount);

    require(tokenAmount <= cap);
    return tokenAmount;
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  function changeBeneficiaryAddress (address _newBeneficiaryAddress) public onlyOwner returns (bool) {
    wallet = _newBeneficiaryAddress;
    return true;
  }

  function sendTokens (address _to, uint256 _amount) public onlyOwner returns (bool) {
    uint8 stageIndex = _getStageIndex();

    require(!icoEnd);

    if (stageIndex == 9) {
      if (token.endIco()) icoEnd = true;
    }

    uint256 cap;
    if (stageIndex == 1) {
      cap = preIcoCap.sub(preIcoSold);
    } else if (stageIndex == 2) {
      cap = icoCap.sub(icoSold);
    } else {
      return false;
    }

    require(_amount <= cap);

    if (stageIndex == 1) preIcoSold = preIcoSold.add(_amount);
    else if (stageIndex == 2) icoSold = icoSold.add(_amount);
    require(token.transfer(_to, _amount));
    return true;
  }
}