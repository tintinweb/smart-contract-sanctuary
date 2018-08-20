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

  // ICO start timestamp
  uint256 public startTime = now;

  // periods timestamps
  uint256 round1StartTime;
  uint256 round1EndTime;
  uint256 round2StartTime;
  uint256 round2EndTime;
  uint256 round3StartTime;
  uint256 round3EndTime;
  uint256 round4StartTime;
  uint256 round4EndTime;

  // bonuses in %
  uint256 public round1Bonus = 20;
  uint256 public round2Bonus = 15;
  uint256 public round3Bonus = 5;

  // min contribution in wei
  uint256 public minContribution = 100 finney;

  // hardcaps in tokens
  uint256 public round1Cap = uint256(9e8).mul(1 ether);
  uint256 public round2Cap = uint256(12e8).mul(1 ether);
  uint256 public round3Cap = uint256(15e8).mul(1 ether);
  uint256 public round4Cap = uint256(24e8).mul(1 ether);

  // tokens sold
  uint256 public round1Sold;
  uint256 public round2Sold;
  uint256 public round3Sold;
  uint256 public round4Sold;

  // Contributions
  mapping(address => uint256) public contributions;

  // hardCap in ETH
  uint256 hardCap = 12500 ether;
  // softCap in ETH
  uint256 softCap = 1250 ether;

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
   * Event for external token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param amount amount of tokens purchased
   */
  event ExternalTokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
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
    round1StartTime = startTime;
    round1EndTime = round1StartTime.add(7 days);
    round2StartTime = round1EndTime.add(1 days);
    round2EndTime = round2StartTime.add(10 days);
    round3StartTime = round2EndTime.add(1 days);
    round3EndTime = round3StartTime.add(14 days);
    round4StartTime = round3EndTime.add(1 days);
    round4EndTime = round4StartTime.add(21 days);
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
   * @dev getting stage index
   */

  function _getStageIndex () internal view returns (uint8) {
    if (now < round1StartTime) return 0;
    if (now <= round1EndTime) return 1;
    if (now < round2StartTime) return 2;
    if (now <= round2EndTime) return 3;
    if (now < round3StartTime) return 4;
    if (now <= round3EndTime) return 5;
    if (now < round4StartTime) return 6;
    if (now <= round4EndTime) return 7;
    return 8;
  }

  /**
   * @dev getting stage name
   */

  function getStageName () public view returns (string) {
    uint8 stageIndex = _getStageIndex();
    if (stageIndex == 0) return &#39;Pause&#39;;
    if (stageIndex == 1) return &#39;Round1&#39;;
    if (stageIndex == 2) return &#39;Round1 end&#39;;
    if (stageIndex == 3) return &#39;Round2&#39;;
    if (stageIndex == 4) return &#39;Round2 end&#39;;
    if (stageIndex == 5) return &#39;Round3&#39;;
    if (stageIndex == 6) return &#39;Round3 end&#39;;
    if (stageIndex == 7) return &#39;Round4&#39;;
    if (stageIndex == 8) return &#39;Round4 end&#39;;
    return &#39;Pause&#39;;
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    uint8 stageIndex = _getStageIndex();
    require(stageIndex > 0);
    require(stageIndex <= 8);

    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount, stageIndex);

    // update state
    weiRaised = weiRaised.add(weiAmount);
    contributions[msg.sender] = contributions[msg.sender].add(weiAmount);

    if (stageIndex == 1 || stageIndex == 2) round1Sold = round1Sold.add(tokens);
    else if (stageIndex == 3 || stageIndex == 4) round2Sold = round2Sold.add(tokens);
    else if (stageIndex == 5 || stageIndex == 6) round3Sold = round3Sold.add(tokens);
    else round4Sold = round4Sold.add(tokens);

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
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal view
  {
    require(_beneficiary != address(0));
    require(_weiAmount > 0);
    require(weiRaised.add(_weiAmount) <= hardCap);

    require(_weiAmount >= minContribution);
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
      _bonus = round1Bonus;
      _cap = round1Cap.sub(round1Sold);
    } else if (_stageIndex == 2) {
      _cap = round2Cap.sub(round1Sold);
    } else if (_stageIndex == 3) {
      _bonus = round2Bonus;
      _cap = round1Cap.sub(round1Sold).add(round2Cap).sub(round2Sold);
    } else if (_stageIndex == 4) {
      _cap = round1Cap.sub(round1Sold).add(round2Cap).sub(round2Sold);
    } else if (_stageIndex == 5) {
      _bonus = round3Bonus;
      _cap = round1Cap.sub(round1Sold).add(round2Cap).sub(round2Sold).add(round3Cap).sub(round3Sold);
    }  else if (_stageIndex == 6) {
      _cap = round1Cap.sub(round1Sold).add(round2Cap).sub(round2Sold).add(round3Cap).sub(round3Sold);
    } else {
      _cap = round1Cap.sub(round1Sold).add(round2Cap).sub(round2Sold).add(round3Cap).sub(round3Sold).add(round4Cap).sub(round4Sold);
    }

    uint256 _tokenAmount = _weiAmount.mul(rate);
    if (_bonus > 0) {
      uint256 _bonusTokens = _tokenAmount.mul(_bonus).div(100);
      _tokenAmount = _tokenAmount.add(_bonusTokens);
    }
    if (_stageIndex < 8) require(_tokenAmount <= _cap);
    return _tokenAmount;
  }

  function refund () public returns (bool) {
    require(now > round4EndTime);
    require(weiRaised < softCap);
    require(contributions[msg.sender] > 0);
    uint256 refundAmount = contributions[msg.sender];
    contributions[msg.sender] = 0;
    weiRaised = weiRaised.sub(refundAmount);
    msg.sender.transfer(refundAmount);
    return true;
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(address(this).balance);
  }

  function transferSoldTokens(address _beneficiary, uint256 _tokenAmount) public onlyOwner returns (bool) {
    uint8 stageIndex = _getStageIndex();
    require(stageIndex > 0);
    require(stageIndex <= 8);

    if (stageIndex == 1 || stageIndex == 2) {
      round1Sold = round1Sold.add(_tokenAmount);
      require(round1Sold <= round1Cap);
    } else if (stageIndex == 3 || stageIndex == 4) {
      round2Sold = round2Sold.add(_tokenAmount);
      require(round2Sold <= round2Cap);
    } else if (stageIndex == 5 || stageIndex == 6) {
      round3Sold = round3Sold.add(_tokenAmount);
      require(round3Sold <= round3Cap);
    } else if (stageIndex == 7) {
      round4Sold = round4Sold.add(_tokenAmount);
      require(round4Sold <= round4Cap);
    }
    emit ExternalTokenPurchase(
      _beneficiary,
      _beneficiary,
      _tokenAmount
    );

    require(token.transfer(_beneficiary, _tokenAmount));
    return true;
  }
}