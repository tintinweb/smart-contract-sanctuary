pragma solidity 0.4.25;



library Zero {
  function requireNotZero(address addr) internal pure {
    require(addr != address(0), "require not zero address");
  }

  function requireNotZero(uint val) internal pure {
    require(val != 0, "require not zero value");
  }

  function notZero(address addr) internal pure returns(bool) {
    return !(addr == address(0));
  }

  function isZero(address addr) internal pure returns(bool) {
    return addr == address(0);
  }

  function isZero(uint a) internal pure returns(bool) {
    return a == 0;
  }

  function notZero(uint a) internal pure returns(bool) {
    return a != 0;
  }
}


library Percent {
  // Solidity automatically throws when dividing by 0
  struct percent {
    uint num;
    uint den;
  }
  
  // storage
  function mul(percent storage p, uint a) internal view returns (uint) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }

  function div(percent storage p, uint a) internal view returns (uint) {
    return a/p.num*p.den;
  }

  function sub(percent storage p, uint a) internal view returns (uint) {
    uint b = mul(p, a);
    if (b >= a) {
      return 0;
    }
    return a - b;
  }

  function add(percent storage p, uint a) internal view returns (uint) {
    return a + mul(p, a);
  }

  function toMemory(percent storage p) internal view returns (Percent.percent memory) {
    return Percent.percent(p.num, p.den);
  }

  // memory 
  function mmul(percent memory p, uint a) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }

  function mdiv(percent memory p, uint a) internal pure returns (uint) {
    return a/p.num*p.den;
  }

  function msub(percent memory p, uint a) internal pure returns (uint) {
    uint b = mmul(p, a);
    if (b >= a) {
      return 0;
    }
    return a - b;
  }

  function madd(percent memory p, uint a) internal pure returns (uint) {
    return a + mmul(p, a);
  }
}

library Address {
  function toAddress(bytes source) internal pure returns(address addr) {
    // solium-disable security/no-inline-assembly
    assembly { addr := mload(add(source,0x14)) }
    return addr;
  }

  function isNotContract(address addr) internal view returns(bool) {
    // solium-disable security/no-inline-assembly
    uint length;
    assembly { length := extcodesize(addr) }
    return length == 0;
  }
}


contract Accessibility {
  address private owner;
  modifier onlyOwner() {
    require(msg.sender == owner, "access denied");
    _;
  }

  constructor() public {
    owner = msg.sender;
  }

  function disown() internal {
    delete owner;
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}


library Timer {
  using SafeMath for uint;
  struct timer {
    uint duration;
    uint startup;
  }
  function start(timer storage t, uint duration) internal {
    t.startup = now;
    t.duration = duration;
  }

  function timeLeft(timer storage t) internal view returns (uint) {
    if (now >= t.startup.add(t.duration)) {
      return 0;
    }
    return (t.startup+t.duration).sub(now);
  }
}


library Bet {
  struct bet {
    address bettor;
    uint amount;
    uint excess;
    uint duration;
  }

  function New(address bettor, uint value) internal pure returns(bet memory b ) {
    
    (uint[3] memory vals, uint[3] memory durs) = bets();
    if (value >= vals[0]) {
      b.amount = vals[0];
      b.duration = durs[0];
    } else if (vals[1] <= value && value < vals[0]) {
      b.amount = vals[1];
      b.duration = durs[1];
    } else if (vals[2] <= value && value < vals[1]) {
      b.amount = vals[2];
      b.duration = durs[2];
    } else {
      return b;
    }

    b.bettor = bettor;
    b.excess = value - b.amount;
  }

  function bets() internal pure returns(uint[3] memory vals, uint[3] memory durs) {
    (vals[0], vals[1], vals[2]) = (1 ether, 0.1 ether, 0.01 ether); 
    (durs[0], durs[1], durs[2]) = (3 minutes + 33 seconds, 6 minutes + 33 seconds, 9 minutes + 33 seconds);
  }

  function transferExcess(bet memory b) internal {
    b.bettor.transfer(b.excess);
  }
}



contract LastHero is Accessibility {
  using Percent for Percent.percent;
  using Timer for Timer.timer;
  using Address for address;
  using Bet for Bet.bet;
  using Zero for *;
  
  Percent.percent private m_bankPercent = Percent.percent(50,100);
  Percent.percent private m_nextLevelPercent = Percent.percent(40,100);
  Percent.percent private m_adminsPercent = Percent.percent(10,100);
  
  uint public nextLevelBankAmount;
  uint public bankAmount;
  uint public level;
  address public bettor;
  address public adminsAddress;
  Timer.timer private m_timer;

  modifier notFromContract() {
    require(msg.sender.isNotContract(), "only externally accounts");
    _;
  }

  event LogSendExcessOfEther(address indexed addr, uint excess, uint when);
  event LogNewWinner(address indexed addr, uint indexed level, uint amount, uint when);
  event LogNewLevel(uint indexed level, uint bankAmount, uint when);
  event LogNewBet(address indexed addr, uint indexed amount, uint duration, uint indexed level, uint when);
  event LogDisown(uint when);


  constructor() public {
    level = 1;
    emit LogNewLevel(level, address(this).balance, now);
    adminsAddress = msg.sender;
    m_timer.duration = uint(-1);
  }

  function() public payable {
    doBet();
  }

  function doDisown() public onlyOwner {
    disown();
    emit LogDisown(now);
  }

  function setAdminsAddress(address addr) public onlyOwner {
    addr.requireNotZero();
    adminsAddress = addr;
  }

  function bankPercent() public view returns(uint numerator, uint denominator) {
    (numerator, denominator) = (m_bankPercent.num, m_bankPercent.den);
  }

  function nextLevelPercent() public view returns(uint numerator, uint denominator) {
    (numerator, denominator) = (m_nextLevelPercent.num, m_nextLevelPercent.den);
  }

  function adminsPercent() public view returns(uint numerator, uint denominator) {
    (numerator, denominator) = (m_adminsPercent.num, m_adminsPercent.den);
  }

  function timeLeft() public view returns(uint duration) {
    duration = m_timer.timeLeft();
  }

  function timerInfo() public view returns(uint startup, uint duration) {
    (startup, duration) = (m_timer.startup, m_timer.duration);
  }

  function durationForBetAmount(uint betAmount) public view returns(uint duration) {
    Bet.bet memory bet = Bet.New(msg.sender, betAmount);
    duration = bet.duration;
  }

  function availableBets() public view returns(uint[3] memory vals, uint[3] memory durs) {
    (vals, durs) = Bet.bets();
  }

  function doBet() public payable notFromContract {

    // send ether to bettor if needed
    if (m_timer.timeLeft().isZero()) {
      bettor.transfer(bankAmount);
      emit LogNewWinner(bettor, level, bankAmount, now);

      bankAmount = nextLevelBankAmount;
      nextLevelBankAmount = 0;
      level++;
      emit LogNewLevel(level, bankAmount, now);
    }

    Bet.bet memory bet = Bet.New(msg.sender, msg.value);
    bet.amount.requireNotZero();

    // send bet`s excess of ether if needed
    if (bet.excess.notZero()) {
      bet.transferExcess();
      emit LogSendExcessOfEther(bet.bettor, bet.excess, now);
    }

    // commision
    nextLevelBankAmount += m_nextLevelPercent.mul(bet.amount);
    bankAmount += m_bankPercent.mul(bet.amount);
    adminsAddress.send(m_adminsPercent.mul(bet.amount));
  
    m_timer.start(bet.duration);
    bettor = bet.bettor;

    emit LogNewBet(bet.bettor, bet.amount, bet.duration, level, now);
  }
}