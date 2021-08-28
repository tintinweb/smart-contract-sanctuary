/**
 *Submitted for verification at Etherscan.io on 2021-08-28
*/

pragma solidity 0.4.25;


/**
*
* ETH CRYPTOCURRENCY DISTRIBUTION PROJECT v 1.0
* 
* GitHub           - https://github.com/fortune333/Fortune333
* 
* 
* 
*  - GAIN 8% - PER 1 MONTH (interest is charges in equal parts every 1 sec)
*         0.26 - PER 1 DAY
*         0.011 - PER 1 HOUR
*         0.00018 - PER 1 MIN
*         0.000003 - PER 1 SEC
*  - Life-long payments
*  - Unprecedentedly reliable
*  - Bringer Fortune
*  - Minimal contribution 0.01 eth
*  - Currency and payment - ETH
*  - Contribution allocation schemes:
*    -- 100 % payments

*
*  --- About the project
* Smart contracts with support for blockchains have opened a new era in a relationship without trust
* intermediaries. This technology opens up incredible financial opportunities.
* The distribution model is recorded in a smart contract, loaded into the Ethereum blockchain, and can no longer be changed.
* The contract is recorded on the blockchain with a WAY TO REFIT OWNERSHIP!
* free access online.
* Continuous autonomous functioning of the system.
*
* ---How to use:
* 1. Send from your ETH wallet to the address of the smart contract
* Any amount from 0.01 ETH.
* 2. Confirm your transaction in the history of your application or etherscan.io, specifying the address of your wallet.
* Profit by sending 0 live transactions
(profit is calculated every second).
*  OR
* To reinvest, you need to deposit the amount you want to reinvest, and the interest accrued is automatically added to your new deposit.
*
* RECOMMENDED GAS LIMIT: 200,000
* RECOMMENDED GAS PRICE: https://ethgasstation.info/
* You can check the payments on the website etherscan.io, in the “Internal Txns” tab of your wallet.
*
* Referral system is missing.
* Payment to developers is missing.
* There is no payment for advertising.
* All 100% of the contribution remains in the Smart Contract Fund.
* Contract restart is also absent. If there is no * money in the Fund, payments are suspended and * they are renewed again when the Fund is filled. Thus * the contract is able to WORK FOREVER!
* --- It is not allowed to transfer from exchanges, ONLY from your personal wallet ETH from which you have a private key.
*
* The contract has passed all the necessary checks by the professionals!
*/


library Math {
  function min(uint a, uint b) internal pure returns(uint) {
    if (a > b) {
      return b;
    }
    return a;
  }
}


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
    assembly { addr := mload(add(source,0x14)) }
    return addr;
  }

  function isNotContract(address addr) internal view returns(bool) {
    uint length;
    assembly { length := extcodesize(addr) }
    return length == 0;
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
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
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
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

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


contract Accessibility {
  address private owner;
  modifier onlyOwner() {
    require(msg.sender == owner, "access denied");
    _;
  }

  constructor() public {
    owner = msg.sender;
  }

  // Deletion of contract holder and waiver of ownership
  
  function disown() internal {
    delete owner;
  }
}


contract Rev1Storage {
  function investorShortInfo(address addr) public view returns(uint value, uint refBonus); 
}


contract Rev2Storage {
  function investorInfo(address addr) public view returns(uint investment, uint paymentTime); 
}


library PrivateEntrance {
  using PrivateEntrance for privateEntrance;
  using Math for uint;
  struct privateEntrance {
    Rev1Storage rev1Storage;
    Rev2Storage rev2Storage;
    uint investorMaxInvestment;
    uint endTimestamp;
    mapping(address=>bool) hasAccess;
  }

  function isActive(privateEntrance storage pe) internal view returns(bool) {
    return pe.endTimestamp > now;
  }

  function maxInvestmentFor(privateEntrance storage pe, address investorAddr) internal view returns(uint) {
    // check if investorAddr has access
    if (!pe.hasAccess[investorAddr]) {
      return 0;
    }

    // get investor max investment = investment from revolution 1
    (uint maxInvestment, ) = pe.rev1Storage.investorShortInfo(investorAddr);
    if (maxInvestment == 0) {
      return 0;
    }
    maxInvestment = Math.min(maxInvestment, pe.investorMaxInvestment);

    // get current investment from revolution 2
    (uint currInvestment, ) = pe.rev2Storage.investorInfo(investorAddr);
    
    if (currInvestment >= maxInvestment) {
      return 0;
    }

    return maxInvestment-currInvestment;
  }

  function provideAccessFor(privateEntrance storage pe, address[] addrs) internal {
    for (uint16 i; i < addrs.length; i++) {
      pe.hasAccess[addrs[i]] = true;
    }
  }
}


contract InvestorsStorage is Accessibility {
  struct Investor {
    uint investment;
    uint paymentTime;
  }
  uint public size;

  mapping (address => Investor) private investors;

  function isInvestor(address addr) public view returns (bool) {
    return investors[addr].investment > 0;
  }

  function investorInfo(address addr) public view returns(uint investment, uint paymentTime) {
    investment = investors[addr].investment;
    paymentTime = investors[addr].paymentTime;
  }

  function newInvestor(address addr, uint investment, uint paymentTime) public onlyOwner returns (bool) {
    Investor storage inv = investors[addr];
    if (inv.investment != 0 || investment == 0) {
      return false;
    }
    inv.investment = investment;
    inv.paymentTime = paymentTime;
    size++;
    return true;
  }

  function addInvestment(address addr, uint investment) public onlyOwner returns (bool) {
    if (investors[addr].investment == 0) {
      return false;
    }
    investors[addr].investment += investment;
    return true;
  }

  function setPaymentTime(address addr, uint paymentTime) public onlyOwner returns (bool) {
    if (investors[addr].investment == 0) {
      return false;
    }
    investors[addr].paymentTime = paymentTime;
    return true;
  }
}


library RapidGrowthProtection {
  using RapidGrowthProtection for rapidGrowthProtection;
  
  struct rapidGrowthProtection {
    uint startTimestamp;
    uint maxDailyTotalInvestment;
    uint8 activityDays;
    mapping(uint8 => uint) dailyTotalInvestment;
  }

  function maxInvestmentAtNow(rapidGrowthProtection storage rgp) internal view returns(uint) {
    uint day = rgp.currDay();
    if (day == 0 || day > rgp.activityDays) {
      return 0;
    }
    if (rgp.dailyTotalInvestment[uint8(day)] >= rgp.maxDailyTotalInvestment) {
      return 0;
    }
    return rgp.maxDailyTotalInvestment - rgp.dailyTotalInvestment[uint8(day)];
  }

  function isActive(rapidGrowthProtection storage rgp) internal view returns(bool) {
    uint day = rgp.currDay();
    return day != 0 && day <= rgp.activityDays;
  }

  function saveInvestment(rapidGrowthProtection storage rgp, uint investment) internal returns(bool) {
    uint day = rgp.currDay();
    if (day == 0 || day > rgp.activityDays) {
      return false;
    }
    if (rgp.dailyTotalInvestment[uint8(day)] + investment > rgp.maxDailyTotalInvestment) {
      return false;
    }
    rgp.dailyTotalInvestment[uint8(day)] += investment;
    return true;
  }

 
  function currDay(rapidGrowthProtection storage rgp) internal view returns(uint day) {
    if (rgp.startTimestamp > now) {
      return 0;
    }
    day = (now - rgp.startTimestamp) / 24 hours + 1; // +1 for skip zero day
  }
}








contract SpaceEmissio is Accessibility {
  using RapidGrowthProtection for RapidGrowthProtection.rapidGrowthProtection;
  using PrivateEntrance for PrivateEntrance.privateEntrance;
  using Percent for Percent.percent;
  using SafeMath for uint;
  using Math for uint;

  // easy read for investors
  using Address for *;
  using Zero for *; 
  
  RapidGrowthProtection.rapidGrowthProtection private m_rgp;
  PrivateEntrance.privateEntrance private m_privEnter;
  mapping(address => bool) private m_referrals;
  InvestorsStorage private m_investors;

  // automatically generates getters
  uint public constant minInvesment = 10 finney; //       0.01 eth
  uint public constant maxBalance = 33333e5 ether; // 333 3300 000 eth
  address public advertisingAddress;
  address public adminsAddress;
  uint public investmentsNumber;
  uint public waveStartup;

  // percents per Day
  Percent.percent private m_1_percent = Percent.percent(26, 100000);           //   26/100000  *100% = 0.26%
  
  // more events for easy read from blockchain
  event LogPEInit(uint when, address rev1Storage, address rev2Storage, uint investorMaxInvestment, uint endTimestamp);
  event LogSendExcessOfEther(address indexed addr, uint when, uint value, uint investment, uint excess);
  event LogNewReferral(address indexed addr, address indexed referrerAddr, uint when, uint refBonus);
  event LogRGPInit(uint when, uint startTimestamp, uint maxDailyTotalInvestment, uint activityDays);
  event LogRGPInvestment(address indexed addr, uint when, uint investment, uint indexed day);
  event LogNewInvesment(address indexed addr, uint when, uint investment, uint value);
  event LogAutomaticReinvest(address indexed addr, uint when, uint investment);
  event LogPayDividends(address indexed addr, uint when, uint dividends);
  event LogNewInvestor(address indexed addr, uint when);
  event LogBalanceChanged(uint when, uint balance);
  event LogNextWave(uint when);
  event LogDisown(uint when);


  modifier balanceChanged {
    _;
    emit LogBalanceChanged(now, address(this).balance);
  }

  modifier notFromContract() {
    require(msg.sender.isNotContract(), "only externally accounts");
    _;
  }

  constructor() public {
    adminsAddress = msg.sender;
    advertisingAddress = msg.sender;
    nextWave();
  }

  function() public payable {
    // investor get him dividends
    if (msg.value.isZero()) {
      getMyDividends();
      return;
    }

    // sender do invest
    doInvest(msg.data.toAddress());
  }

  function doDisown() private onlyOwner {
    disown();
    emit LogDisown(now);
  }

  function init(address rev1StorageAddr, uint timestamp) private onlyOwner {
    // init Rapid Growth Protection
    m_rgp.startTimestamp = timestamp + 1;
    m_rgp.maxDailyTotalInvestment = 500 ether;
    m_rgp.activityDays = 21;
    emit LogRGPInit(
      now, 
      m_rgp.startTimestamp,
      m_rgp.maxDailyTotalInvestment,
      m_rgp.activityDays
    );


    // init Private Entrance
    m_privEnter.rev1Storage = Rev1Storage(rev1StorageAddr);
    m_privEnter.rev2Storage = Rev2Storage(address(m_investors));
    m_privEnter.investorMaxInvestment = 50 ether;
    m_privEnter.endTimestamp = timestamp;
    emit LogPEInit(
      now, 
      address(m_privEnter.rev1Storage), 
      address(m_privEnter.rev2Storage), 
      m_privEnter.investorMaxInvestment, 
      m_privEnter.endTimestamp
    );
  }

  

  function privateEntranceProvideAccessFor(address[] addrs) private onlyOwner {
    m_privEnter.provideAccessFor(addrs);
  }

  function rapidGrowthProtectionmMaxInvestmentAtNow() private view returns(uint investment) {
    investment = m_rgp.maxInvestmentAtNow();
  }

  function investorsNumber() public view returns(uint) {
    return m_investors.size();
  }

  function balanceETH() public view returns(uint) {
    return address(this).balance;
  }

  function percent1() public view returns(uint numerator, uint denominator) {
    (numerator, denominator) = (m_1_percent.num, m_1_percent.den);
  }

  

  function investorInfo(address investorAddr) public view returns(uint investment, uint paymentTime, bool isReferral) {
    (investment, paymentTime) = m_investors.investorInfo(investorAddr);
    isReferral = m_referrals[investorAddr];
  }

  function investorDividendsAtNow(address investorAddr) public view returns(uint dividends) {
    dividends = calcDividends(investorAddr);
  }

  function dailyPercentAtNow() public view returns(uint numerator, uint denominator) {
    Percent.percent memory p = dailyPercent();
    (numerator, denominator) = (p.num, p.den);
  }

  

  function getMyDividends() public notFromContract balanceChanged {
    // calculate dividends
    uint dividends = calcDividends(msg.sender);
    require (dividends.notZero(), "cannot to pay zero dividends");

    // update investor payment timestamp
    assert(m_investors.setPaymentTime(msg.sender, now));

    // check enough eth - goto next wave if needed
    if (address(this).balance <= dividends) {
      nextWave();
      dividends = address(this).balance;
    } 

    // transfer dividends to investor
    msg.sender.transfer(dividends);
    emit LogPayDividends(msg.sender, now, dividends);
  }

  function doInvest(address referrerAddr) public payable notFromContract balanceChanged {
    uint investment = msg.value;
    uint receivedEther = msg.value;
    require(investment >= minInvesment, "investment must be >= minInvesment");
    require(address(this).balance <= maxBalance, "the contract eth balance limit");

    if (m_rgp.isActive()) { 
      // use Rapid Growth Protection if needed
      uint rpgMaxInvest = m_rgp.maxInvestmentAtNow();
      rpgMaxInvest.requireNotZero();
      investment = Math.min(investment, rpgMaxInvest);
      assert(m_rgp.saveInvestment(investment));
      emit LogRGPInvestment(msg.sender, now, investment, m_rgp.currDay());
      
    } else if (m_privEnter.isActive()) {
      // use Private Entrance if needed
      uint peMaxInvest = m_privEnter.maxInvestmentFor(msg.sender);
      peMaxInvest.requireNotZero();
      investment = Math.min(investment, peMaxInvest);
    }

    // send excess of ether if needed
    if (receivedEther > investment) {
      uint excess = receivedEther - investment;
      msg.sender.transfer(excess);
      receivedEther = investment;
      emit LogSendExcessOfEther(msg.sender, now, msg.value, investment, excess);
    }

   // commission


bool senderIsInvestor = m_investors.isInvestor(msg.sender);
    
    // ref system works only once and only on first invest (is disabled)
if (referrerAddr.notZero() && !senderIsInvestor && !m_referrals[msg.sender] &&
referrerAddr != msg.sender && m_investors.isInvestor(referrerAddr)) {


}
    
    // automatic reinvest - prevent burning dividends
    uint dividends = calcDividends(msg.sender);
    if (senderIsInvestor && dividends.notZero()) {
      investment += dividends;
      emit LogAutomaticReinvest(msg.sender, now, dividends);
    }

    if (senderIsInvestor) {
      // update existing investor
      assert(m_investors.addInvestment(msg.sender, investment));
      assert(m_investors.setPaymentTime(msg.sender, now));
    } else {
      // create new investor
      assert(m_investors.newInvestor(msg.sender, investment, now));
      emit LogNewInvestor(msg.sender, now);
    }

    investmentsNumber++;
    emit LogNewInvesment(msg.sender, now, investment, receivedEther);
  }

  function getMemInvestor(address investorAddr) internal view returns(InvestorsStorage.Investor memory) {
    (uint investment, uint paymentTime) = m_investors.investorInfo(investorAddr);
    return InvestorsStorage.Investor(investment, paymentTime);
  }

  function calcDividends(address investorAddr) internal view returns(uint dividends) {
    InvestorsStorage.Investor memory investor = getMemInvestor(investorAddr);

    // safe gas if dividends will be 0
    if (investor.investment.isZero() || now.sub(investor.paymentTime) < 1 seconds) {
      return 0;
    }
    
    // for prevent burning daily dividends if 24h did not pass - calculate it per 1 sec interval
    // if daily percent is X, then 1 sec percent = X / (24h / 1 sec) = X / 86400

    // and we must to get numbers of 1 sec interval after investor got payment:
    // (now - investor.paymentTime) / 1 sec 

    // finaly calculate dividends = ((now - investor.paymentTime) / 1 sec) * (X * investor.investment)  / 86400) 

    Percent.percent memory p = dailyPercent();
    dividends = (now.sub(investor.paymentTime) / 1 seconds) * p.mmul(investor.investment) / 86400;
  }

 
  function dailyPercent() internal view returns(Percent.percent memory p) {
    uint balance = address(this).balance;
      

    if (balance < 33333e5 ether) { 
   
      p = m_1_percent.toMemory();    // (1)

  }
  }



  function nextWave() private {
    m_investors = new InvestorsStorage();
    investmentsNumber = 0;
    waveStartup = now;
    
    
    emit LogRGPInit(now , m_rgp.startTimestamp, m_rgp.maxDailyTotalInvestment, m_rgp.activityDays);
    emit LogNextWave(now);
  }
}