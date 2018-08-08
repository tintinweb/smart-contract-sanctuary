pragma solidity ^0.4.11;

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
  function Ownable() {
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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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
    Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract Finalizable is Ownable {
  bool public contractFinalized;

  modifier notFinalized() {
    require(!contractFinalized);
    _;
  }

  function finalizeContract() onlyOwner {
    contractFinalized = true;
  }
}

contract Shared is Ownable, Finalizable {
  uint internal constant DECIMALS = 8;
  
  address internal constant REWARDS_WALLET = 0x30b002d3AfCb7F9382394f7c803faFBb500872D8;
  address internal constant CROWDSALE_WALLET = 0x028e1Ce69E379b1678278640c7387ecc40DAa895;
  address internal constant LIFE_CHANGE_WALLET = 0xEe4284f98D0568c7f65688f18A2F74354E17B31a;
  address internal constant LIFE_CHANGE_VESTING_WALLET = 0x2D354bD67707223C9aC0232cd0E54f22b03483Cf;
}

contract Ledger is Shared {
  using SafeMath for uint;

  address public controller;
  mapping(address => uint) public balanceOf;
  mapping (address => mapping (address => uint)) public allowed;
  uint public totalSupply;

  function setController(address _address) onlyOwner notFinalized {
    controller = _address;
  }

  modifier onlyController() {
    require(msg.sender == controller);
    _;
  }

  function transfer(address _from, address _to, uint _value) onlyController returns (bool success) {
    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    return true;
  }

  function transferFrom(address _spender, address _from, address _to, uint _value) onlyController returns (bool success) {
    var _allowance = allowed[_from][_spender];
    balanceOf[_to] = balanceOf[_to].add(_value);
    balanceOf[_from] = balanceOf[_from].sub(_value);
    allowed[_from][_spender] = _allowance.sub(_value);
    return true;
  }

  function approve(address _owner, address _spender, uint _value) onlyController returns (bool success) {
    require((_value == 0) || (allowed[_owner][_spender] == 0));
    allowed[_owner][_spender] = _value;
    return true;
  }

  function allowance(address _owner, address _spender) onlyController constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  function burn(address _from, uint _amount) onlyController returns (bool success) {
    balanceOf[_from] = balanceOf[_from].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
    return true;
  }

  function mint(address _to, uint _amount) onlyController returns (bool success) {
    balanceOf[_to] += _amount;
    totalSupply += _amount;
    return true;
  }
}

contract Controller is Shared, Pausable {
  using SafeMath for uint;

  bool public initialized;

  ChristCoin public token;
  Ledger public ledger;
  address public crowdsale;

  uint public vestingAmount;
  uint public vestingPaid;
  uint public vestingStart;
  uint public vestingDuration;

  function Controller(address _token, address _ledger, address _crowdsale) {
    token = ChristCoin(_token);
    ledger = Ledger(_ledger);
    crowdsale = _crowdsale;
  }

  function setToken(address _address) onlyOwner notFinalized {
    token = ChristCoin(_address);
  }

  function setLedger(address _address) onlyOwner notFinalized {
    ledger = Ledger(_address);
  }

  function setCrowdsale(address _address) onlyOwner notFinalized {
    crowdsale = _address;
  }

  modifier onlyToken() {
    require(msg.sender == address(token));
    _;
  }

  modifier onlyCrowdsale() {
    require(msg.sender == crowdsale);
    _;
  }

  modifier onlyTokenOrCrowdsale() {
    require(msg.sender == address(token) || msg.sender == crowdsale);
    _;
  }

  modifier notVesting() {
    require(msg.sender != LIFE_CHANGE_VESTING_WALLET);
    _;
  }

  function init() onlyOwner {
    require(!initialized);
    mintWithEvent(REWARDS_WALLET, 9 * (10 ** (9 + DECIMALS))); // 9 billion
    mintWithEvent(CROWDSALE_WALLET, 900 * (10 ** (6 + DECIMALS))); // 900 million
    mintWithEvent(LIFE_CHANGE_WALLET, 100 * (10 ** (6 + DECIMALS))); // 100 million
    initialized = true;
  }

  function totalSupply() onlyToken constant returns (uint) {
    return ledger.totalSupply();
  }

  function balanceOf(address _owner) onlyTokenOrCrowdsale constant returns (uint) {
    return ledger.balanceOf(_owner);
  }

  function allowance(address _owner, address _spender) onlyToken constant returns (uint) {
    return ledger.allowance(_owner, _spender);
  }

  function transfer(address _from, address _to, uint _value) onlyToken notVesting whenNotPaused returns (bool success) {
    return ledger.transfer(_from, _to, _value);
  }

  function transferWithEvent(address _from, address _to, uint _value) onlyCrowdsale returns (bool success) {
    success = ledger.transfer(_from, _to, _value);
    if (success) {
      token.controllerTransfer(msg.sender, _to, _value);
    }
  }

  function transferFrom(address _spender, address _from, address _to, uint _value) onlyToken notVesting whenNotPaused returns (bool success) {
    return ledger.transferFrom(_spender, _from, _to, _value);
  }

  function approve(address _owner, address _spender, uint _value) onlyToken notVesting whenNotPaused returns (bool success) {
    return ledger.approve(_owner, _spender, _value);
  }

  function burn(address _owner, uint _amount) onlyToken whenNotPaused returns (bool success) {
    return ledger.burn(_owner, _amount);
  }

  function mintWithEvent(address _to, uint _amount) internal returns (bool success) {
    success = ledger.mint(_to, _amount);
    if (success) {
      token.controllerTransfer(0x0, _to, _amount);
    }
  }

  function startVesting(uint _amount, uint _duration) onlyCrowdsale {
    require(vestingAmount == 0);
    vestingAmount = _amount;
    vestingPaid = 0;
    vestingStart = now;
    vestingDuration = _duration;
  }

  function withdrawVested(address _withdrawTo) returns (uint amountWithdrawn) {
    require(msg.sender == LIFE_CHANGE_VESTING_WALLET);
    require(vestingAmount > 0);
    
    uint _elapsed = now.sub(vestingStart);
    uint _rate = vestingAmount.div(vestingDuration);
    uint _unlocked = _rate.mul(_elapsed);

    if (_unlocked > vestingAmount) {
       _unlocked = vestingAmount;
    }

    if (_unlocked <= vestingPaid) {
      amountWithdrawn = 0;
      return;
    }

    amountWithdrawn = _unlocked.sub(vestingPaid);
    vestingPaid = vestingPaid.add(amountWithdrawn);

    ledger.transfer(LIFE_CHANGE_VESTING_WALLET, _withdrawTo, amountWithdrawn);
    token.controllerTransfer(LIFE_CHANGE_VESTING_WALLET, _withdrawTo, amountWithdrawn);
  }
}

contract ChristCoin is Shared {
  using SafeMath for uint;

  string public name = "Christ Coin";
  string public symbol = "CCLC";
  uint8 public decimals = 8;

  Controller public controller;

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approval(address indexed _owner, address indexed _spender, uint _value);

  function setController(address _address) onlyOwner notFinalized {
    controller = Controller(_address);
  }

  modifier onlyController() {
    require(msg.sender == address(controller));
    _;
  }

  function balanceOf(address _owner) constant returns (uint) {
    return controller.balanceOf(_owner);
  }

  function totalSupply() constant returns (uint) {
    return controller.totalSupply();
  }

  function transfer(address _to, uint _value) returns (bool success) {
    success = controller.transfer(msg.sender, _to, _value);
    if (success) {
      Transfer(msg.sender, _to, _value);
    }
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    success = controller.transferFrom(msg.sender, _from, _to, _value);
    if (success) {
      Transfer(_from, _to, _value);
    }
  }

  function approve(address _spender, uint _value) returns (bool success) {
    success = controller.approve(msg.sender, _spender, _value);
    if (success) {
      Approval(msg.sender, _spender, _value);
    }
  }

  function allowance(address _owner, address _spender) constant returns (uint) {
    return controller.allowance(_owner, _spender);
  }

  function burn(uint _amount) onlyOwner returns (bool success) {
    success = controller.burn(msg.sender, _amount);
    if (success) {
      Transfer(msg.sender, 0x0, _amount);
    }
  }

  function controllerTransfer(address _from, address _to, uint _value) onlyController {
    Transfer(_from, _to, _value);
  }

  function controllerApproval(address _from, address _spender, uint _value) onlyController {
    Approval(_from, _spender, _value);
  }
}

contract Crowdsale is Shared, Pausable {
  using SafeMath for uint;

  uint public constant START = 1506945600;                          // October 2, 2017 7:00:00 AM CST
  uint public constant END = 1512133200;                            // December 1, 2017 7:00:00 AM CST
  uint public constant CAP = 450 * (10 ** (6 + DECIMALS));          // 450 million tokens
  
  uint public weiRaised;
  uint public tokensDistributed;
  uint public bonusTokensDistributed;
  uint public presaleTokensDistributed;
  uint public presaleBonusTokensDistributed;
  bool public crowdsaleFinalized;
  bool public presaleFinalized;

  Controller public controller;
  Round[] public rounds;
  Round public currentRound;

  struct Presale {
    address purchaser;
    uint weiAmount;
  }

  struct Round {
    uint index;
    uint endAmount;
    uint rate;
    uint incentiveDivisor;
  }

  struct Purchase {
    uint tokens;
    uint bonus;
  }

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint value, uint amount);

  function Crowdsale() {
    require(END >= START);

    rounds.push(Round(0, 75 * (10 ** (6 + DECIMALS)), 35460992907801, 4));
    rounds.push(Round(1, 150 * (10 ** (6 + DECIMALS)), 106382978723404, 10));
    rounds.push(Round(2, 250 * (10 ** (6 + DECIMALS)), 212765957446808, 0));
    rounds.push(Round(3, 450 * (10 ** (6 + DECIMALS)), 319148936170213, 0));
    currentRound = rounds[0];
  }

  function setController(address _address) onlyOwner {
    controller = Controller(_address);
  }

  function () payable whenNotPaused {
    buyTokens(msg.sender);
  }

  function buyTokens(address _beneficiary) payable whenNotPaused {
    require(_beneficiary != 0x0);
    require(validPurchase());

    processPurchase(msg.sender, _beneficiary, msg.value);
    LIFE_CHANGE_WALLET.transfer(msg.value);  
  }

  function processPurchase(address _from, address _beneficiary, uint _weiAmount) internal returns (Purchase purchase) {
    purchase = getPurchase(_weiAmount, tokensDistributed);
    require(tokensDistributed.add(purchase.tokens) <= CAP);
    uint _tokensWithBonus = purchase.tokens.add(purchase.bonus);
    bonusTokensDistributed = bonusTokensDistributed.add(purchase.bonus);
    tokensDistributed = tokensDistributed.add(purchase.tokens);
    weiRaised = weiRaised.add(_weiAmount);
    controller.transferWithEvent(CROWDSALE_WALLET, _beneficiary, _tokensWithBonus);
    TokenPurchase(_from, _beneficiary, _weiAmount, _tokensWithBonus);
  }

  function getPurchase(uint _weiAmount, uint _tokensDistributed) internal returns (Purchase purchase) {
    uint _roundTokensRemaining = currentRound.endAmount.sub(_tokensDistributed);
    uint _roundWeiRemaining = _roundTokensRemaining.mul(currentRound.rate).div(10 ** DECIMALS);
    uint _tokens = _weiAmount.div(currentRound.rate).mul(10 ** DECIMALS);
    uint _incentiveDivisor = currentRound.incentiveDivisor;
    
    if (_tokens <= _roundTokensRemaining) {
      purchase.tokens = _tokens;

      if (_incentiveDivisor > 0) {
        purchase.bonus = _tokens.div(_incentiveDivisor);
      }
    } else {
      currentRound = rounds[currentRound.index + 1];

      uint _roundBonus = 0;
      if (_incentiveDivisor > 0) {
        _roundBonus = _roundTokensRemaining.div(_incentiveDivisor);
      }
      
      purchase = getPurchase(_weiAmount.sub(_roundWeiRemaining), _tokensDistributed.add(_roundTokensRemaining));
      purchase.tokens = purchase.tokens.add(_roundTokensRemaining);
      purchase.bonus = purchase.bonus.add(_roundBonus);
    }
  }

  function validPurchase() internal constant returns (bool) {
    bool notAtCap = tokensDistributed < CAP;
    bool nonZeroPurchase = msg.value != 0;
    bool withinPeriod = now >= START && now <= END;

    return notAtCap && nonZeroPurchase && withinPeriod && presaleFinalized;
  }

  function hasEnded() constant returns (bool) {
    return crowdsaleFinalized || tokensDistributed == CAP || now > END;
  }

  function addPresale(address _beneficiary, uint _weiAmount) onlyOwner returns (bool) {
    require(!presaleFinalized);
    require(_beneficiary != 0x0);
    require(_weiAmount != 0);
    
    Purchase memory purchase = processPurchase(0x0, _beneficiary, _weiAmount);
    presaleTokensDistributed = presaleTokensDistributed.add(purchase.tokens);
    presaleBonusTokensDistributed = presaleBonusTokensDistributed.add(purchase.bonus);

    return true;
  }

  function finalizePresale() onlyOwner {
    require(!presaleFinalized);

    currentRound = rounds[1];
    presaleFinalized = true;
  }

  function finalizeCrowdsale() onlyOwner {
    require(!crowdsaleFinalized);
    require(hasEnded());
    
    uint _toVest = controller.balanceOf(CROWDSALE_WALLET);
    if (tokensDistributed == CAP) {
      _toVest = _toVest.sub(CAP.div(4)); // 25% bonus to token holders if sold out
    }

    controller.transferWithEvent(CROWDSALE_WALLET, LIFE_CHANGE_VESTING_WALLET, _toVest);
    controller.startVesting(_toVest, 7 years);

    crowdsaleFinalized = true;
  }
}