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

  // How many token units a buyer gets per ether.
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  // Private ICO start and end date
  uint256 public privateIcoEndTime = 1533859200; // 10/08/2018

  // Pre ICO start and end date
  uint256 public preIcoStartTime = 1533859200; // 10/08/2018
  uint256 public preIcoEndTime = 1536537600; // 10/09/2018

  // Pre ICO start and end date
  uint256 public earlyBirdStartTime = 1536537600; // 10/09/2018
  uint256 public earlyBirdEndTime = 1539129600; // 10/10/2018

  // ICO start and end date
  uint256 public icoStartTime = 1539129600; // 10/10/2018
  uint256 public icoEndTime = 1541808000; // 10/11/2018

  // bonuses in %
  uint256 public privateIcoBonus = 30;
  uint256 public preIcoBonus = 20;
  uint256 public earlyBirdBonus = 5;

  // min contribution in wei
  uint256 public minContribution = 100 finney;

  // hardcaps in tokens
  uint256 public privateIcoCap = uint256(8e8).mul(1 ether);
  uint256 public preIcoCap = uint256(2e9).mul(1 ether);
  uint256 public earlyBirdCap = uint256(26e8).mul(1 ether);
  uint256 public icoCap = uint256(46e8).mul(1 ether);

  // tokens sold
  uint256 public privateIcoSold;
  uint256 public preIcoSold;
  uint256 public earlyBirdSold;
  uint256 public icoSold;

  // Contributions
  mapping(address => uint256) public contributions;

  // hardCap in ETH
  uint256 hardCap = 19075 ether;
  // softCap in ETH
  uint256 softCap = 1908 ether;

//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//For testing period only. Should be deleted in production (as well as .add(extraTime) in functions below)
  uint256 public extraTime = 0;

  function addExtraDays(uint256 _days) public {
    uint256 time = _days.mul(3600).mul(24);
    extraTime = extraTime.add(time);
  }

  function getExtraDays() public view returns (uint256) {
    return extraTime.div(3600).div(24);
  }
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

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
   * @param _rate Base rate
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _rate, address _newOwner, address _wallet, Token _token) public {
    require(_wallet != address(0));
    require(_token != address(0));
    rate = _rate;
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
   * @dev getting stage index (private ICO = 1, pre ICO = 2, early bird = 3, ICO = 4, ICO end = 5)
   */

  function _getStageIndex () internal view returns (uint8) {
    if (now.add(extraTime) <= privateIcoEndTime) return 1;
    if (now.add(extraTime) > privateIcoEndTime && now.add(extraTime) < preIcoStartTime) return 2;
    if (now.add(extraTime) >= preIcoStartTime && now.add(extraTime) <= preIcoEndTime) return 3;
    if (now.add(extraTime) > preIcoEndTime && now.add(extraTime) < earlyBirdStartTime) return 4;
    if (now.add(extraTime) >= earlyBirdStartTime && now.add(extraTime) <= earlyBirdEndTime) return 5;
    if (now.add(extraTime) > earlyBirdEndTime && now.add(extraTime) < icoStartTime) return 6;
    if (now.add(extraTime) >= icoStartTime && now.add(extraTime) <= icoEndTime) return 7;
    return 8;
  }

  /**
   * @dev getting stage index (private ICO = 1, pre ICO = 2, ICO = 3, pause = 0, end = 9)
   */

  function getStageName () public view returns (string) {
    uint8 stageIndex = _getStageIndex();
    if (stageIndex == 1) return &#39;Private ICO&#39;;
    if (stageIndex == 2) return &#39;Private ICO end&#39;;
    if (stageIndex == 3) return &#39;Pre ICO&#39;;
    if (stageIndex == 4) return &#39;Pre ICO end&#39;;
    if (stageIndex == 5) return &#39;Early Bird&#39;;
    if (stageIndex == 6) return &#39;Early Bird end&#39;;
    if (stageIndex == 7) return &#39;ICO&#39;;
    if (stageIndex == 8) return &#39;ICO is over&#39;;
    return &#39;Pause&#39;;
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    uint8 stageIndex = _getStageIndex();

    _preValidatePurchase(_beneficiary, weiAmount, stageIndex);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount, stageIndex);

    // update state
    weiRaised = weiRaised.add(weiAmount);
    contributions[msg.sender] = contributions[msg.sender].add(weiAmount);

    if (stageIndex == 1 || stageIndex == 2) privateIcoSold = privateIcoSold.add(tokens);
    else if (stageIndex == 3 || stageIndex == 4) preIcoSold = preIcoSold.add(tokens);
    else if (stageIndex == 5 || stageIndex == 6) earlyBirdSold = earlyBirdSold.add(tokens);
    else icoSold = icoSold.add(tokens);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );
    if (weiRaised >= softCap) _forwardFunds();
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
   * @param _stageIndex Stage index
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount,
    uint8 _stageIndex
  )
    internal view
  {
    require(_beneficiary != address(0));
    require(_weiAmount > 0);
    require(weiRaised.add(_weiAmount) <= hardCap);

    if (_stageIndex == 3 || _stageIndex == 5 || _stageIndex == 7) require(_weiAmount >= minContribution);
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
    uint256 _bonus = 0;
    uint256 _cap;
    if (_stageIndex == 1) {
      _bonus = privateIcoBonus;
      _cap = privateIcoCap.sub(privateIcoSold);
    } else if (_stageIndex == 2) {
      _cap = preIcoCap.sub(privateIcoSold);
    } else if (_stageIndex == 3) {
      _bonus = preIcoBonus;
      _cap = preIcoCap.sub(preIcoSold);
    } else if (_stageIndex == 4) {
      _cap = privateIcoCap.sub(privateIcoSold).add(preIcoCap).sub(preIcoSold);
    } else if (_stageIndex == 5) {
      _bonus = earlyBirdBonus;
      _cap = icoCap.sub(icoSold);
    }  else if (_stageIndex == 6) {
      _cap = privateIcoCap.sub(privateIcoSold).add(preIcoCap).sub(preIcoSold).add(earlyBirdCap).sub(earlyBirdSold);
    } else if (_stageIndex == 7) {
      _cap = icoCap.sub(icoSold);
    } else {
      _cap = privateIcoCap.sub(privateIcoSold).add(preIcoCap).sub(preIcoSold).add(earlyBirdCap).sub(earlyBirdSold).add(icoCap).sub(icoSold);
    }
    uint256 _tokenAmount = _weiAmount.mul(rate);
    uint256 _bonusTokens = _tokenAmount.mul(_bonus).div(100);
    _tokenAmount = _tokenAmount.add(_bonusTokens);

    require(_tokenAmount <= _cap);
    return _tokenAmount;
  }

  function refund () public returns (bool) {
    require(now.add(extraTime) > icoEndTime);
    require(weiRaised < softCap);
    require(contributions[msg.sender] > 0);
    uint256 refundAmount = contributions[msg.sender];
    contributions[msg.sender] = 0;
    weiRaised = weiRaised.sub(refundAmount);
    msg.sender.transfer(refundAmount);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(address(this).balance);
  }
}