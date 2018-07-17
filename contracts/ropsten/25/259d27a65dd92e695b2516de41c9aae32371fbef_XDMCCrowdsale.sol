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
contract XDMCCrowdsale is Ownable {
  using SafeMath for uint256;

  event Log(string _a, uint256 _b);

  // The token being sold
  ERC20 public token;

  address wallet; //address for contribution receiving

  uint256 public icoRate = 0; // will be set manually when ico starts
  uint256 public icoOver1 = 0; // will be set manually when ico starts
  uint256 public icoBonus1 = 0; // will be set manually when ico starts
  uint256 public icoOver2 = 0; // will be set manually when ico starts
  uint256 public icoBonus2 = 0; // will be set manually when ico starts
  uint256 public icoOver3 = 0; // will be set manually when ico starts
  uint256 public icoBonus3 = 0; // will be set manually when ico starts
  uint256 public icoOver4 = 0; // will be set manually when ico starts
  uint256 public icoBonus4 = 0; // will be set manually when ico starts
  uint256 public icoOver5 = 0; // will be set manually when ico starts
  uint256 public icoBonus5 = 0; // will be set manually when ico starts
  uint256 public ico1cap = uint256(224502081).mul(1 ether);
  uint256 public ico2cap = uint256(190996929).mul(1 ether);
  uint256 public ico3cap = uint256(127331286).mul(1 ether);
  enum Stages {Pause, Ico1, Ico1End, Ico2, Ico2End, Ico3, Ico3End}
  Stages currentStage;
  address public teamAddress = 0x4B58EBeEb96b7551Bb752Ea9512771615C554De3;
  uint256 public vestingStartTime = 0;
  uint256 public vestingPeriod = 15552000; // 180 days
  uint256 public teamTokens = uint256(198639670).mul(1 ether);
  uint256 public teamTokensPerPeriod = uint256(33768743).mul(1 ether);
  uint256 public teamTokensReleased = 0;
  uint256 public devTokensIco1 = uint256(52060948).mul(1 ether);
  uint256 public devTokensIco2 = uint256(52060948).mul(1 ether);
  uint256 public devTokensIco3 = uint256(53638554).mul(1 ether);
  uint256 public ico1endTime = 0;
  uint256 public ico2endTime = 0;
  uint256 public ico3endTime = 0;
  uint256 public getUnsoldPeriod = 8640000; // 100 days
  uint256 public ico1total = 0;
  uint256 public ico2total = 0;
  uint256 public ico3total = 0;
  uint256 public ico1receivedTotal = 0;
  uint256 public ico2receivedTotal = 0;
  uint256 public ico3receivedTotal = 0;
  mapping(address => uint256) ico1amount;
  mapping(address => uint256) ico2amount;
  mapping(address => uint256) ico3amount;
  mapping(address => uint256) ico1received;
  mapping(address => uint256) ico2received;
  mapping(address => uint256) ico3received;

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

  event TokenPriceDescription(
    uint256 basePrice,
    uint256 bonus,
    uint256 tokens
  );

  /**
   * 
   * @param _owner Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(address _owner, address _wallet, ERC20 _token) public {
    require(_owner != address(0));
    require(_wallet != address(0));
    require(_token != address(0));
    currentStage = Stages.Pause;
    vestingStartTime = now;
    owner = _owner;
    token = _token;
    wallet = _wallet;
    teamTokensReleased = teamTokensReleased.add(teamTokensPerPeriod);
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

  function startIco1(
    uint256 _rate, 
    uint256 _over1, 
    uint256 _bonus1, 
    uint256 _over2, 
    uint256 _bonus2, 
    uint256 _over3, 
    uint256 _bonus3, 
    uint256 _over4, 
    uint256 _bonus4, 
    uint256 _over5, 
    uint256 _bonus5
  ) public onlyOwner returns (bool) {
    require(currentStage == Stages.Pause);
    require(token.balanceOf(address(this)) >= uint256(865461673).mul(1 ether));
    require(_rate > 0);
    currentStage = Stages.Ico1;
    icoRate = _rate;
    icoOver1 = _over1.mul(1 ether);
    icoBonus1 = _bonus1;
    icoOver2 = _over2.mul(1 ether);
    icoBonus2 = _bonus2;
    icoOver3 = _over3.mul(1 ether);
    icoBonus3 = _bonus3;
    icoOver4 = _over4.mul(1 ether);
    icoBonus4 = _bonus4;
    icoOver5 = _over5.mul(1 ether);
    icoBonus5 = _bonus5;
    require(token.transfer(owner, devTokensIco1));
    return true;
  }

  function endIco1() public onlyOwner returns (bool) {
    require(currentStage == Stages.Ico1);
    currentStage = Stages.Ico1End;
    ico1endTime = now;
    return true;
  }

  function startIco2(
    uint256 _rate, 
    uint256 _over1, 
    uint256 _bonus1, 
    uint256 _over2, 
    uint256 _bonus2, 
    uint256 _over3, 
    uint256 _bonus3, 
    uint256 _over4, 
    uint256 _bonus4, 
    uint256 _over5, 
    uint256 _bonus5
  ) public onlyOwner returns (bool) {
    require(currentStage == Stages.Ico1End);
    currentStage = Stages.Ico2;
    if (_rate > 0) icoRate = _rate;
    icoOver1 = _over1.mul(1 ether);
    icoBonus1 = _bonus1;
    icoOver2 = _over2.mul(1 ether);
    icoBonus2 = _bonus2;
    icoOver3 = _over3.mul(1 ether);
    icoBonus3 = _bonus3;
    icoOver4 = _over4.mul(1 ether);
    icoBonus4 = _bonus4;
    icoOver5 = _over5.mul(1 ether);
    icoBonus5 = _bonus5;
    require(token.transfer(owner, devTokensIco2));
    return true;
  }

  function endIco2() public onlyOwner returns (bool) {
    require(currentStage == Stages.Ico2);
    currentStage = Stages.Ico2End;
    ico2endTime = now;
    return true;
  }

  function startIco3(
    uint256 _rate, 
    uint256 _over1, 
    uint256 _bonus1, 
    uint256 _over2, 
    uint256 _bonus2, 
    uint256 _over3, 
    uint256 _bonus3, 
    uint256 _over4, 
    uint256 _bonus4, 
    uint256 _over5, 
    uint256 _bonus5
  ) public onlyOwner returns (bool) {
    require(currentStage == Stages.Ico2End);
    currentStage = Stages.Ico3;
    if (_rate > 0) icoRate = _rate;
    icoOver1 = _over1.mul(1 ether);
    icoBonus1 = _bonus1;
    icoOver2 = _over2.mul(1 ether);
    icoBonus2 = _bonus2;
    icoOver3 = _over3.mul(1 ether);
    icoBonus3 = _bonus3;
    icoOver4 = _over4.mul(1 ether);
    icoBonus4 = _bonus4;
    icoOver5 = _over5.mul(1 ether);
    icoBonus5 = _bonus5;
    require(token.transfer(owner, devTokensIco3));
    return true;
  }

  function endIco3() public onlyOwner returns (bool) {
    require(currentStage == Stages.Ico3);
    currentStage = Stages.Ico3End;
    ico3endTime = now;
    return true;
  }

  function getUnsoldReceived(uint256 _stage, address _address) public view returns (uint256) {
    if (_stage == 1) return ico1received[_address];
    else if (_stage == 2) return ico2received[_address];
    else if (_stage == 3) return ico3received[_address];
    else return 0;
  }

  function getStageAmount(uint256 _stage, address _address) public view returns (uint256) {
    if (_stage == 1) return ico1amount[_address];
    else if (_stage == 2) return ico2amount[_address];
    else if (_stage == 3) return ico3amount[_address];
    else return 0;
  }

  function getStageName() public view returns (string) {
    if (currentStage == Stages.Pause) return &#39;ICO is not started yet&#39;;
    else if (currentStage == Stages.Ico1) return &#39;ICO 1&#39;;
    else if (currentStage == Stages.Ico1End) return &#39;ICO 1 end&#39;;
    else if (currentStage == Stages.Ico2) return &#39;ICO 2&#39;;
    else if (currentStage == Stages.Ico2End) return &#39;ICO 2 end&#39;;
    else if (currentStage == Stages.Ico3) return &#39;ICO 3&#39;;
    else if (currentStage == Stages.Ico3End) return &#39;ICO 3 end&#39;;
    return &#39;Undefined&#39;;
  }

  function getPrice() public view returns (uint256) {
    if (currentStage == Stages.Ico1) return icoRate;
    else if (currentStage == Stages.Ico2) return icoRate;
    else if (currentStage == Stages.Ico3) return icoRate;
    return 0;
  }

  function getBonus(uint256 _ether) public view returns (uint256) {
    return _getBonus(_ether.mul(1 ether));
  }

  function _getBonus(uint256 _wei) internal view returns (uint256) {
    if (
        currentStage == Stages.Ico1 || 
        currentStage == Stages.Ico2 || 
        currentStage == Stages.Ico3
      ) {
      if (_wei >= icoOver1) return icoBonus1;
      else if (_wei >= icoOver2) return icoBonus2;
      else if (_wei >= icoOver3) return icoBonus3;
      else if (_wei >= icoOver4) return icoBonus4;
      else if (_wei >= icoOver5) return icoBonus5;
      return 0;
    }
    return 0;
  }

  function getVestingPeriodNumber() public view returns (uint256) {
    if (vestingStartTime == 0) return 0;
    return now.sub(vestingStartTime).div(vestingPeriod).add(1);
  }

  function getTeamToken() public {
    uint256 vestingPeriodNumber = getVestingPeriodNumber();
    require(vestingPeriodNumber > 1);
    require(teamTokensReleased < teamTokens);
    uint256 toRelease;
    if (vestingPeriodNumber >= 6) toRelease = teamTokens;
    else toRelease = vestingPeriodNumber.mul(teamTokensPerPeriod);
    if (toRelease > teamTokens) toRelease = teamTokens;
    toRelease = toRelease.sub(teamTokensReleased);
    require(toRelease > 0);
    teamTokensReleased = teamTokensReleased.add(toRelease);
    require(token.transfer(teamAddress, toRelease));
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

    _validateTokensAmount(tokens);

    if (currentStage == Stages.Ico1) {
      ico1amount[msg.sender] = ico1amount[msg.sender].add(tokens);
      ico1total = ico1total.add(tokens);
    } else if (currentStage == Stages.Ico2) {
      ico2amount[msg.sender] = ico2amount[msg.sender].add(tokens);
      ico2total = ico2total.add(tokens);
    } else if (currentStage == Stages.Ico3) {
      ico3amount[msg.sender] = ico3amount[msg.sender].add(tokens);
      ico3total = ico3total.add(tokens);
    }

    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);

    emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _forwardFunds(weiAmount);
  }

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view {
    require(_beneficiary != address(0));
    require(_weiAmount >= 100 finney);
    if (currentStage == Stages.Ico1) require(_weiAmount <= 1000 ether);
    else if (currentStage == Stages.Ico2) require(_weiAmount <= 500 ether);
    else if (currentStage == Stages.Ico3) require(_weiAmount <= 500 ether);
    else revert();
  }

  function _validateTokensAmount(uint256 _tokens) internal view {
    require(_tokens > 0);
    if (currentStage == Stages.Ico1) require(_tokens <= ico1cap);
    else if (currentStage == Stages.Ico2) require(_tokens <= ico2cap);
    else if (currentStage == Stages.Ico3) require(_tokens <= ico3cap);
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(token.transfer(_beneficiary, _tokenAmount));
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
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount) internal returns (uint256) {
    uint256 basePrice = icoRate;
    uint256 tokens = _weiAmount.mul(basePrice);
    uint256 bonuses = _getBonus(_weiAmount);
    if (bonuses > 0) {
      uint256 bonusTokens = tokens.mul(bonuses).div(100);
      tokens = tokens.add(bonusTokens);
    }

    emit TokenPriceDescription(basePrice, bonuses, tokens);
    return tokens;
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds(uint256 _weiAmount) internal {
    require(wallet != address(0));
    wallet.transfer(_weiAmount);
  }

  function getUnsoldOwner() public onlyOwner returns (bool) {
    uint256 unsoldTokensRemains = 0;
    uint256 stageRemains;
    if (
      ico1endTime > 0 && 
      now.sub(ico1endTime) > getUnsoldPeriod && 
      ico1receivedTotal < ico1cap.sub(ico1total)
    ) {
      stageRemains = ico1cap.sub(ico1total).sub(ico1receivedTotal);
      unsoldTokensRemains = unsoldTokensRemains.add(stageRemains);
      ico1receivedTotal = ico1cap.sub(ico1total);
    }
    if (
      ico2endTime > 0 && 
      now.sub(ico2endTime) > getUnsoldPeriod && 
      ico2receivedTotal < ico2cap.sub(ico1total)
    ) {
      stageRemains = ico2cap.sub(ico2total).sub(ico2receivedTotal);
      unsoldTokensRemains = unsoldTokensRemains.add(stageRemains);
      ico2receivedTotal = ico2cap.sub(ico2total);
    }
    if (
      ico3endTime > 0 && 
      now.sub(ico3endTime) > getUnsoldPeriod && 
      ico3receivedTotal < ico3cap.sub(ico3total)
    ) {
      stageRemains = ico3cap.sub(ico3total).sub(ico3receivedTotal);
      unsoldTokensRemains = unsoldTokensRemains.add(stageRemains);
      ico3receivedTotal = ico3cap.sub(ico3total);
    }

    require(unsoldTokensRemains > 0);
    require(token.transfer(owner, unsoldTokensRemains));

    return true;
  }

  function getUnsold() public returns (bool) {
    uint256 unsoldTokensShare = 0;
    uint256 tokenBalance = token.balanceOf(msg.sender);
    uint256 stageShare;
    uint256 stageRemains;

    if (
      ico1endTime > 0 && 
      now.sub(ico1endTime) < getUnsoldPeriod && 
      ico1received[msg.sender] == 0 &&
      tokenBalance >= ico1amount[msg.sender]
    ) {
      tokenBalance = tokenBalance.sub(ico1amount[msg.sender]);
      stageRemains = ico1cap.sub(ico1total);
      stageShare = stageRemains.mul(ico1amount[msg.sender]).div(ico1total);
      unsoldTokensShare = unsoldTokensShare.add(stageShare);
      ico1received[msg.sender] = stageShare;
      ico1receivedTotal = ico1receivedTotal.add(stageShare);
      require(ico1receivedTotal <= ico1cap.sub(ico1total));
    }

    if (
      ico2endTime > 0 && 
      now.sub(ico2endTime) < getUnsoldPeriod && 
      ico2received[msg.sender] == 0 &&
      tokenBalance >= ico2amount[msg.sender]
    ) {
      tokenBalance = tokenBalance.sub(ico2amount[msg.sender]);
      stageRemains = ico2cap.sub(ico2total);
      stageShare = stageRemains.mul(ico2amount[msg.sender]).div(ico2total);
      unsoldTokensShare = unsoldTokensShare.add(stageShare);
      ico2received[msg.sender] = stageShare;
      ico2receivedTotal = ico2receivedTotal.add(stageShare);
      require(ico2receivedTotal <= ico2cap.sub(ico2total));
    }

    if (
      ico3endTime > 0 && 
      now.sub(ico3endTime) < getUnsoldPeriod && 
      ico3received[msg.sender] == 0 &&
      tokenBalance >= ico3amount[msg.sender]
    ) {
      stageRemains = ico3cap.sub(ico3total);
      stageShare = stageRemains.mul(ico3amount[msg.sender]).div(ico3total);
      unsoldTokensShare = unsoldTokensShare.add(stageShare);
      ico3received[msg.sender] = stageShare;
      ico3receivedTotal = ico3receivedTotal.add(stageShare);
      require(ico3receivedTotal <= ico3cap.sub(ico3total));
    }

    require(unsoldTokensShare > 0);
    require(token.transfer(msg.sender, unsoldTokensShare));

    return true;
  }
}