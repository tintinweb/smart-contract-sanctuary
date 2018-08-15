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
  function balanceOf(address who) public view returns (uint256);
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

  // How many usd per 10000 tokens.
  uint256 public rate = 7142;

  // usd cents per 1 ETH
  uint256 public ethRate = 27500;

  // Amount of wei raised
  uint256 public weiRaised;

  // Seconds in a week
  uint256 public week = 604800;

  // ICO start time
  uint256 public icoStartTime;

  // bonuses in %
  uint256 public privateIcoBonus = 50;
  uint256 public preIcoBonus = 30;
  uint256 public ico1Bonus = 15;
  uint256 public ico2Bonus = 10;
  uint256 public ico3Bonus = 5;
  uint256 public ico4Bonus = 0;

  // min contribution in wei
  uint256 public privateIcoMin = 1 ether;
  uint256 public preIcoMin = 1 ether;
  uint256 public ico1Min = 1 ether;
  uint256 public ico2Min = 1 ether;
  uint256 public ico3Min = 1 ether;
  uint256 public ico4Min = 1 ether; 

  // max contribution in wei
  uint256 public privateIcoMax = 350 ether;
  uint256 public preIcoMax = 10000 ether;
  uint256 public ico1Max = 10000 ether;
  uint256 public ico2Max = 10000 ether;
  uint256 public ico3Max = 10000 ether;
  uint256 public ico4Max = 10000 ether;


  // hardcaps in tokens
  uint256 public privateIcoCap = uint256(322532).mul(1e8);
  uint256 public preIcoCap = uint256(8094791).mul(1e8);
  uint256 public ico1Cap = uint256(28643106).mul(1e8);
  uint256 public ico2Cap = uint256(17123596).mul(1e8);
  uint256 public ico3Cap = uint256(9807150).mul(1e8);
  uint256 public ico4Cap = uint256(6008825).mul(1e8);

  // tokens sold
  uint256 public privateIcoSold;
  uint256 public preIcoSold;
  uint256 public ico1Sold;
  uint256 public ico2Sold;
  uint256 public ico3Sold;
  uint256 public ico4Sold;

  //whitelist
  mapping(address => bool) public whitelist; 
  //whitelisters addresses
  mapping(address => bool) public whitelisters;

  modifier isWhitelister() {
    require(whitelisters[msg.sender]);
    _;
  }

  modifier isWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

  // Sale stages
  enum Stages {Pause, PrivateIco, PrivateIcoEnd, PreIco, PreIcoEnd, Ico1, Ico2, Ico3, Ico4, IcoEnd}

  Stages currentStage;

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

  /** Event emitted when _account is Whitelisted / UnWhitelisted */
  event WhitelistUpdated(address indexed _account, uint8 _phase);

  /**
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(address _newOwner, address _wallet, Token _token) public {
    require(_newOwner != address(0));
    require(_wallet != address(0));
    require(_token != address(0));

    owner = _newOwner;
    wallet = _wallet;
    token = _token;

    currentStage = Stages.Pause;
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
   * @dev sale stage start
   */

  function startPrivateIco() public onlyOwner returns (bool) {
    require(currentStage == Stages.Pause);
    currentStage = Stages.PrivateIco;
    return true;
  }

  /**
   * @dev sale stage end
   */

  function endPrivateIco() public onlyOwner returns (bool) {
    require(currentStage == Stages.PrivateIco);
    currentStage = Stages.PrivateIcoEnd;
    return true;
  }

  /**
   * @dev sale stage start
   */

  function startPreIco() public onlyOwner returns (bool) {
    require(currentStage == Stages.PrivateIcoEnd);
    currentStage = Stages.PreIco;
    return true;
  }

  /**
   * @dev sale stage end
   */

  function endPreIco() public onlyOwner returns (bool) {
    require(currentStage == Stages.PreIco);
    currentStage = Stages.PreIcoEnd;
    return true;
  }

  /**
   * @dev sale stage start
   */

  function startIco() public onlyOwner returns (bool) {
    require(currentStage == Stages.PreIcoEnd);
    currentStage = Stages.Ico1;
    icoStartTime = now;
    return true;
  }


  /**
   * @dev getting stage index (private ICO = 1, pre ICO = 2, ICO = 3, pause = 0, end = 9)
   */

  function getStageName () public view returns (string) {
    if (currentStage == Stages.Pause) return &#39;Pause&#39;;
    if (currentStage == Stages.PrivateIco) return &#39;Private ICO&#39;;
    if (currentStage == Stages.PrivateIcoEnd) return &#39;Private ICO end&#39;;
    if (currentStage == Stages.PreIco) return &#39;Prte ICO&#39;;
    if (currentStage == Stages.PreIcoEnd) return &#39;Pre ICO end&#39;;
    if (currentStage == Stages.Ico1) return &#39;ICO 1-st week&#39;;
    if (currentStage == Stages.Ico2) return &#39;ICO 2-d week&#39;;
    if (currentStage == Stages.Ico3) return &#39;ICO 3-d week&#39;;
    if (currentStage == Stages.Ico4) return &#39;ICO 4-th week&#39;;
    return &#39;ICO is over&#39;;
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable isWhitelisted {

    uint256 weiAmount = msg.value;
    uint256 time;
    uint256 weeksPassed;

    require(currentStage != Stages.Pause);
    require(currentStage != Stages.PrivateIcoEnd);
    require(currentStage != Stages.PreIcoEnd);
    require(currentStage != Stages.IcoEnd);

    if (currentStage == Stages.Ico1 || currentStage == Stages.Ico2 || currentStage == Stages.Ico3 || currentStage == Stages.Ico4) {
      time = now.sub(icoStartTime);
      weeksPassed = time.div(week);

      if (currentStage == Stages.Ico1) {
        if (weeksPassed == 1) currentStage = Stages.Ico2;
        else if (weeksPassed == 2) currentStage = Stages.Ico3;
        else if (weeksPassed == 3) currentStage = Stages.Ico4;
        else if (weeksPassed > 3) currentStage = Stages.IcoEnd;
      } else if (currentStage == Stages.Ico2) {
        if (weeksPassed == 2) currentStage = Stages.Ico3;
        else if (weeksPassed == 3) currentStage = Stages.Ico4;
        else if (weeksPassed > 3) currentStage = Stages.IcoEnd;
      } else if (currentStage == Stages.Ico3) {
        if (weeksPassed == 3) currentStage = Stages.Ico4;
        else if (weeksPassed > 3) currentStage = Stages.IcoEnd;
      } else if (currentStage == Stages.Ico4) {
        if (weeksPassed > 3) currentStage = Stages.IcoEnd;
      }
    }

    if (currentStage != Stages.IcoEnd) {
      _preValidatePurchase(_beneficiary, weiAmount);

      // calculate token amount to be created
      uint256 tokens = _getTokenAmount(weiAmount);

      // update state
      weiRaised = weiRaised.add(weiAmount);

      if (currentStage == Stages.PrivateIco) privateIcoSold = privateIcoSold.add(tokens);
      if (currentStage == Stages.PreIco) preIcoSold = preIcoSold.add(tokens);
      if (currentStage == Stages.Ico1) ico1Sold = ico1Sold.add(tokens);
      if (currentStage == Stages.Ico2) ico2Sold = ico2Sold.add(tokens);
      if (currentStage == Stages.Ico3) ico3Sold = ico3Sold.add(tokens);
      if (currentStage == Stages.Ico4) ico4Sold = ico4Sold.add(tokens);

      _processPurchase(_beneficiary, tokens);
      emit TokenPurchase(
        msg.sender,
        _beneficiary,
        weiAmount,
        tokens
      );

      _forwardFunds();
    } else {
      msg.sender.transfer(msg.value);
    }
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
    require(_weiAmount != 0);

    if (currentStage == Stages.PrivateIco) {
      require(_weiAmount >= privateIcoMin);
      require(_weiAmount <= privateIcoMax);
    } else if (currentStage == Stages.PreIco) {
      require(_weiAmount >= preIcoMin);
      require(_weiAmount <= preIcoMax);
    } else if (currentStage == Stages.Ico1) {
      require(_weiAmount >= ico1Min);
      require(_weiAmount <= ico1Max);
    } else if (currentStage == Stages.Ico2) {
      require(_weiAmount >= ico2Min);
      require(_weiAmount <= ico2Max);
    } else if (currentStage == Stages.Ico3) {
      require(_weiAmount >= ico3Min);
      require(_weiAmount <= ico3Max);
    } else if (currentStage == Stages.Ico4) {
      require(_weiAmount >= ico4Min);
      require(_weiAmount <= ico4Max);
    }
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
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    uint256 bonus;
    uint256 cap;

    if (currentStage == Stages.PrivateIco) {
      bonus = privateIcoBonus;
      cap = privateIcoCap.sub(privateIcoSold);
    } else if (currentStage == Stages.PreIco) {
      bonus = preIcoBonus;
      cap = preIcoCap.sub(preIcoSold);
    } else if (currentStage == Stages.Ico1) {
      bonus = ico1Bonus;
      cap = ico1Cap.sub(ico1Sold);
    } else if (currentStage == Stages.Ico2) {
      bonus = ico2Bonus;
      cap = ico2Cap.sub(ico2Sold);
    } else if (currentStage == Stages.Ico3) {
      bonus = ico3Bonus;
      cap = ico3Cap.sub(ico3Sold);
    } else if (currentStage == Stages.Ico4) {
      bonus = ico4Bonus;
      cap = ico4Cap.sub(ico4Sold);
    }
    uint256 tokenAmount = _weiAmount.mul(ethRate).div(rate).div(1e8);
    uint256 bonusTokens = tokenAmount.mul(bonus).div(100);
    tokenAmount = tokenAmount.add(bonusTokens);

    require(tokenAmount <= cap);
    return tokenAmount;
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  function withdrawTokens() public onlyOwner returns (bool) {
    uint256 time;
    uint256 weeksPassed;

    if (currentStage == Stages.Ico1 || currentStage == Stages.Ico2 || currentStage == Stages.Ico3 || currentStage == Stages.Ico4) {
      time = now.sub(icoStartTime);
      weeksPassed = time.div(week);

      if (weeksPassed > 3) currentStage = Stages.IcoEnd;
    }
    require(currentStage == Stages.IcoEnd);

    uint256 balance = token.balanceOf(address(this));
    if (balance > 0) {
      require(token.transfer(owner, balance));
    }
  }

  /**
   * @dev Direct tokens sending
   * @param _to address
   * @param _amount tokens amount
   */
  function SendTokens(address _to, uint256 _amount) public onlyOwner returns (bool) {
    uint256 time;
    uint256 weeksPassed;

    require(_to != address(0));
    require(currentStage != Stages.Pause);
    require(currentStage != Stages.PrivateIcoEnd);
    require(currentStage != Stages.PreIcoEnd);
    require(currentStage != Stages.IcoEnd);

    if (currentStage == Stages.Ico1 || currentStage == Stages.Ico2 || currentStage == Stages.Ico3 || currentStage == Stages.Ico4) {
      time = now.sub(icoStartTime);
      weeksPassed = time.div(week);

      if (currentStage == Stages.Ico1) {
        if (weeksPassed == 1) currentStage = Stages.Ico2;
        else if (weeksPassed == 2) currentStage = Stages.Ico3;
        else if (weeksPassed == 3) currentStage = Stages.Ico4;
        else if (weeksPassed > 3) currentStage = Stages.IcoEnd;
      } else if (currentStage == Stages.Ico2) {
        if (weeksPassed == 2) currentStage = Stages.Ico3;
        else if (weeksPassed == 3) currentStage = Stages.Ico4;
        else if (weeksPassed > 3) currentStage = Stages.IcoEnd;
      } else if (currentStage == Stages.Ico3) {
        if (weeksPassed == 3) currentStage = Stages.Ico4;
        else if (weeksPassed > 3) currentStage = Stages.IcoEnd;
      } else if (currentStage == Stages.Ico4) {
        if (weeksPassed > 3) currentStage = Stages.IcoEnd;
      }
    }

    if (currentStage != Stages.IcoEnd) {
      uint256 cap;
      if (currentStage == Stages.PrivateIco) {
        cap = privateIcoCap.sub(privateIcoSold);
      } else if (currentStage == Stages.PreIco) {
        cap = preIcoCap.sub(preIcoSold);
      } else if (currentStage == Stages.Ico1) {
        cap = ico1Cap.sub(ico1Sold);
      } else if (currentStage == Stages.Ico2) {
        cap = ico2Cap.sub(ico2Sold);
      } else if (currentStage == Stages.Ico3) {
        cap = ico3Cap.sub(ico3Sold);
      } else if (currentStage == Stages.Ico4) {
        cap = ico4Cap.sub(ico4Sold);
      }

      require(_amount <= cap);

      if (currentStage == Stages.PrivateIco) privateIcoSold = privateIcoSold.add(_amount);
      if (currentStage == Stages.PreIco) preIcoSold = preIcoSold.add(_amount);
      if (currentStage == Stages.Ico1) ico1Sold = ico1Sold.add(_amount);
      if (currentStage == Stages.Ico2) ico2Sold = ico2Sold.add(_amount);
      if (currentStage == Stages.Ico3) ico3Sold = ico3Sold.add(_amount);
      if (currentStage == Stages.Ico4) ico4Sold = ico4Sold.add(_amount);
    } else {
      return false;
    }
    require(token.transfer(_to, _amount));
  }

    /// @dev Adds account addresses to whitelist.
    /// @param _account address.
    /// @param _phase 1 to add, 0 to remove.
    function updateWhitelist (address _account, uint8 _phase) external isWhitelister returns (bool) {
      require(_account != address(0));
      require(_phase <= 1);
      if (_phase == 1) whitelist[_account] = true;
      else whitelist[_account] = false;
      emit WhitelistUpdated(_account, _phase);
      return true;
    }

    /// @dev Adds new whitelister
    /// @param _address new whitelister address.
    function addWhitelister (address _address) public onlyOwner returns (bool) {
      whitelisters[_address] = true;
      return true;
    }

    /// @dev Removes whitelister
    /// @param _address address to remove.
    function removeWhitelister (address _address) public onlyOwner returns (bool) {
      whitelisters[_address] = false;
      return true;
    }

    function setUsdRate (uint256 _usdCents) public onlyOwner returns (bool) {
      ethRate = _usdCents;
      return true;
    }
}