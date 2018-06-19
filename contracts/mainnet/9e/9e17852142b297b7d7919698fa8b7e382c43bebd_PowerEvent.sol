pragma solidity ^0.4.11;

contract Controller {


  // list of admins, council at first spot
  address[] public admins;

  function Governable() {
    admins.length = 1;
    admins[0] = msg.sender;
  }

  modifier onlyAdmins() {
    bool isAdmin = false;
    for (uint256 i = 0; i < admins.length; i++) {
      if (msg.sender == admins[i]) {
        isAdmin = true;
      }
    }
    require(isAdmin == true);
    _;
  }

  function addAdmin(address _admin) public onlyAdmins {
    for (uint256 i = 0; i < admins.length; i++) {
      require(_admin != admins[i]);
    }
    require(admins.length < 10);
    admins[admins.length++] = _admin;
  }

  function removeAdmin(address _admin) public onlyAdmins {
    uint256 pos = admins.length;
    for (uint256 i = 0; i < admins.length; i++) {
      if (_admin == admins[i]) {
        pos = i;
      }
    }
    require(pos < admins.length);
    // if not last element, switch with last
    if (pos < admins.length - 1) {
      admins[pos] = admins[admins.length - 1];
    }
    // then cut off the tail
    admins.length--;
  }

  // State Variables
  bool public paused;
  function nutzAddr() constant returns (address);
  function powerAddr() constant returns (address);
  
  function moveCeiling(uint256 _newPurchasePrice);
  function moveFloor(uint256 _newPurchasePrice);

  // Nutz functions
  function babzBalanceOf(address _owner) constant returns (uint256);
  function activeSupply() constant returns (uint256);
  function burnPool() constant returns (uint256);
  function powerPool() constant returns (uint256);
  function totalSupply() constant returns (uint256);
  function allowance(address _owner, address _spender) constant returns (uint256);

  function approve(address _owner, address _spender, uint256 _amountBabz) public;
  function transfer(address _from, address _to, uint256 _amountBabz, bytes _data) public;
  function transferFrom(address _sender, address _from, address _to, uint256 _amountBabz, bytes _data) public;

  // Market functions
  function floor() constant returns (uint256);
  function ceiling() constant returns (uint256);

  function purchase(address _sender, uint256 _value, uint256 _price) public returns (uint256);
  function sell(address _from, uint256 _price, uint256 _amountBabz);

  // Power functions
  function powerBalanceOf(address _owner) constant returns (uint256);
  function outstandingPower() constant returns (uint256);
  function authorizedPower() constant returns (uint256);
  function powerTotalSupply() constant returns (uint256);

  function powerUp(address _sender, address _from, uint256 _amountBabz) public;
  function downTick(address _owner, uint256 _now) public;
  function createDownRequest(address _owner, uint256 _amountPower) public;
  function downs(address _owner) constant public returns(uint256, uint256, uint256);
  function downtime() constant returns (uint256);

  // this is called when NTZ are deposited into the burn pool
  function dilutePower(uint256 _amountBabz, uint256 _amountPower);
    function setMaxPower(uint256 _maxPower);
    

  // withdraw excessive reserve - i.e. milestones
  function allocateEther(uint256 _amountWei, address _beneficiary);

}



/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


/*
 * ERC20Basic
 * Simpler version of ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20Basic {
  function totalSupply() constant returns (uint256);
  function balanceOf(address _owner) constant returns (uint256);
  function transfer(address _to, uint256 _value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}


contract ERC223Basic is ERC20Basic {
    function transfer(address to, uint value, bytes data) returns (bool);
}

/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC223Basic {
  // active supply of tokens
  function activeSupply() constant returns (uint256);
  function allowance(address _owner, address _spender) constant returns (uint256);
  function transferFrom(address _from, address _to, uint _value) returns (bool);
  function approve(address _spender, uint256 _value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract PowerEvent {
  using SafeMath for uint;

  // states
  //   - waiting, initial state
  //   - collecting, after waiting, before collection stopped
  //   - failed, after collecting, if softcap missed
  //   - closed, after collecting, if softcap reached
  //   - complete, after closed or failed, when job done
  enum EventState { Waiting, Collecting, Closed, Failed, Complete }
  EventState public state;
  uint256 public RATE_FACTOR = 1000000;

  // Terms
  uint256 public startTime;
  uint256 public minDuration;
  uint256 public maxDuration;
  uint256 public softCap;
  uint256 public hardCap;
  uint256 public discountRate; // if rate 30%, this will be 300,000
  uint256 public amountPower;
  address[] public milestoneRecipients;
  uint256[] public milestoneShares;

  // Params
  address public controllerAddr;
  address public powerAddr;
  address public nutzAddr;
  uint256 public initialReserve;
  uint256 public initialSupply;

  function PowerEvent(address _controllerAddr, uint256 _startTime, uint256 _minDuration, uint256 _maxDuration, uint256 _softCap, uint256 _hardCap, uint256 _discount, uint256 _amountPower, address[] _milestoneRecipients, uint256[] _milestoneShares)
  areValidMileStones(_milestoneRecipients, _milestoneShares) {
    require(_minDuration <= _maxDuration);
    require(_softCap <= _hardCap);
    controllerAddr = _controllerAddr;
    startTime = _startTime;
    minDuration = _minDuration;
    maxDuration = _maxDuration;
    softCap = _softCap;
    hardCap = _hardCap;
    discountRate = _discount;
    amountPower = _amountPower;
    state = EventState.Waiting;
    milestoneRecipients = _milestoneRecipients;
    milestoneShares = _milestoneShares;
  }

  modifier isState(EventState _state) {
    require(state == _state);
    _;
  }

  modifier areValidMileStones(address[] _milestoneRecipients, uint256[] _milestoneShares) {
    require(checkMilestones(_milestoneRecipients, _milestoneShares));
    _;
  }

  function checkMilestones(address[] _milestoneRecipients, uint256[] _milestoneShares) internal returns (bool) {
    require(_milestoneRecipients.length == _milestoneShares.length && _milestoneShares.length <= 4);
    uint256 totalPercentage;
    for(uint8 i = 0; i < _milestoneShares.length; i++) {
      require(_milestoneShares[i] >= 0 && _milestoneShares[i] <= 1000000);
      totalPercentage = totalPercentage.add(_milestoneShares[i]);
    }
    require(totalPercentage >= 0 && totalPercentage <= 1000000);
    return true;
  }

  function tick() public {
    if (state == EventState.Waiting) {
      startCollection();
    } else if (state == EventState.Collecting) {
      stopCollection();
    } else if (state == EventState.Failed) {
      completeFailed();
    } else if (state == EventState.Closed) {
      completeClosed();
    } else {
      throw;
    }
  }

  function startCollection() isState(EventState.Waiting) {
    // check time
    require(now > startTime);
    // assert(now < startTime.add(minDuration));
    // read initial values
    var contr = Controller(controllerAddr);
    powerAddr = contr.powerAddr();
    nutzAddr = contr.nutzAddr();
    initialSupply = contr.activeSupply().add(contr.powerPool()).add(contr.burnPool());
    initialReserve = nutzAddr.balance;
    uint256 ceiling = contr.ceiling();
    // move ceiling
    uint256 newCeiling = ceiling.mul(discountRate).div(RATE_FACTOR);
    contr.moveCeiling(newCeiling);
    // set state
    state = EventState.Collecting;
  }

  function stopCollection() isState(EventState.Collecting) {
    uint256 collected = nutzAddr.balance.sub(initialReserve);
    if (now > startTime.add(maxDuration)) {
      if (collected >= softCap) {
        // softCap reached, close
        state = EventState.Closed;
        return;
      } else {
        // softCap missed, fail
        state = EventState.Failed;
        return;
      }
    } else if (now > startTime.add(minDuration)) {
      if (collected >= hardCap) {
        // hardCap reached, close
        state = EventState.Closed;
        return;
      } else {
        // keep going
        revert();
      }
    }
    // keep going
    revert();
  }

  function completeFailed() isState(EventState.Failed) {
    var contr = Controller(controllerAddr);
    // move floor (set ceiling or max floor)
    uint256 ceiling = contr.ceiling();
    contr.moveFloor(ceiling);
    // remove access
    contr.removeAdmin(address(this));
    // set state
    state = EventState.Complete;
  }

  function completeClosed() isState(EventState.Closed) {
    var contr = Controller(controllerAddr);
    // move ceiling
    uint256 ceiling = contr.ceiling();
    uint256 newCeiling = ceiling.mul(RATE_FACTOR).div(discountRate);
    contr.moveCeiling(newCeiling);
    // dilute power
    uint256 totalSupply = contr.activeSupply().add(contr.powerPool()).add(contr.burnPool());
    uint256 newSupply = totalSupply.sub(initialSupply);
    contr.dilutePower(newSupply, amountPower);
    // set max power
    var PowerContract = ERC20(powerAddr);
    uint256 authorizedPower = PowerContract.totalSupply();
    contr.setMaxPower(authorizedPower);
    // pay out milestone
    uint256 collected = nutzAddr.balance.sub(initialReserve);
    for (uint256 i = 0; i < milestoneRecipients.length; i++) {
      uint256 payoutAmount = collected.mul(milestoneShares[i]).div(RATE_FACTOR);
      contr.allocateEther(payoutAmount, milestoneRecipients[i]);
    }
    // remove access
    contr.removeAdmin(address(this));
    // set state
    state = EventState.Complete;
  }

}