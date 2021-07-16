//SourceUnit: eTrono.sol

pragma solidity 0.5.9;

/**
 * ____________________________________   ________ 
 * ___  ____/__  __/__  __ \_  __ \__  | / /_  __ \
 * __  __/  __  /  __  /_/ /  / / /_   |/ /_  / / /
 * _  /___  _  /   _  _  _// /_/ /_  /|  / / /_/ / 
 * /_____/  /_/    /_/ |_| \____/ /_/ |_/  \____/  
 *
 * eTrono - is a leading decentralized, 100% community based, a next-generation pool. 
 * Funding platform that is powered by the Tron smart contract, and the TRX coin.
 *
 * - Starting profit is 2% per day
 * - The Deposit is active for 300 days
 * - Minimum input amount is 100 TRX
 * - Minimum withdrawal amount: no limit
 * - Payment regulation: immediately
 * - 5 levels affiliate program: 5% - 3% - 2% - 1% - 1%
 *
 * Bonuses:
 * 1. Hold bonus. There is profits growth by 0.1% per day, if you're not withdrawing funds during 24 hours. 
 * In other words, user's profitability will be 3% per 24 hours after 10 days of funds holding
 * 2. Fund bonus. Every participant's profit increases by 0.1% per 24 hours for each million of Tronos on contracts balance.
 * 3. Referral bonus. Your profit increases by 0.1% per 24 hours for each million of Tronos contributed by your referrals.
 *
 * Web: https://etrono.net/
 *
 */

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
        return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

library Percent {
  struct percent {
    uint num;
    uint den;
  }
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
    if (b >= a) return 0;
    return a - b;
  }

  function add(percent storage p, uint a) internal view returns (uint) {
    return a + mul(p, a);
  }
}

contract eTrono {
  using SafeMath for uint256;
  using Percent for Percent.percent;

  struct Deposit {
    uint256 amount;
    uint256 date;
  }
  
  struct User {
    address referrer;
    bool status;

    uint256[] referrals;
    uint256 rewards;
    uint256 turnover;

    uint256 invested;
    uint256 withdrawn;

    Deposit[] deposits;
    uint256 balance;
    
    uint256 lastDate;
  }
  
  uint256 constant private ONE_DAY          = 1 days;
  uint256 constant private PROFIT_DAYS      = 150 days;
  uint256 constant private MIN_DEPOSIT      = 100 trx;
  uint256 constant private MUL_EVERY        = 1e6 trx;

  Percent.percent private PERCENT_DIVIDEND  = Percent.percent(2, 100);
  Percent.percent private PERCENT_BONUS     = Percent.percent(1, 1000);
  Percent.percent private PERCENT_PROMOTE   = Percent.percent(1, 10);
  Percent.percent[] private PERCENT_REFERRAL;

  uint256 public totalInvested;
  uint256 public totalRewards;
  
  address public promote;
  mapping (address => User) public users;
  
  event Registration(address indexed user, address indexed referrer);
  event Investment(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  
  constructor() public {
    promote = msg.sender;

    PERCENT_REFERRAL.push(Percent.percent(5, 100));
    PERCENT_REFERRAL.push(Percent.percent(3, 100));
    PERCENT_REFERRAL.push(Percent.percent(2, 100));
    PERCENT_REFERRAL.push(Percent.percent(1, 100));
    PERCENT_REFERRAL.push(Percent.percent(1, 100));

    users[msg.sender].status = true;
    for (uint256 i = 0; i < PERCENT_REFERRAL.length; i++) {
      users[msg.sender].referrals.push(0);
    }
  }

  function checkUserStatus(address user) public view returns (bool) {
    return users[user].status == true;
  }

  function referralsCountByLevel(address user, uint256 level) public view returns (uint256) {
    return users[user].referrals[level];
  }
  
  function referralsCount(address user) public view returns (uint256, uint256, uint256, uint256, uint256) {
    return (
      users[user].referrals[0],
      users[user].referrals[1],
      users[user].referrals[2],
      users[user].referrals[3],
      users[user].referrals[4]
    );
  }

  function getHoldBonus(address user) public view returns (uint256) {
    if (!checkUserStatus(user)) return 0;
    return (block.timestamp - users[user].lastDate) / ONE_DAY;
  }
  
  function getFundBonus() public view returns (uint256) {
    return address(this).balance / MUL_EVERY;
  }
  
  function getRefBonus(address user) public view returns (uint256) {
    return users[user].turnover / MUL_EVERY;
  }

  function calculateProfit(address userAddress) public view returns (uint256) {
    User memory user = users[userAddress];
    
    if (user.deposits.length == 0) return 0;
    
    uint256 profit = 0;
    for (uint256 i = 0; i < user.deposits.length; i++) {
      Deposit memory deposit = user.deposits[i];
      uint256 finish = deposit.date.add(PROFIT_DAYS);
      uint256 till = block.timestamp > finish ? finish : block.timestamp;
      if (till > user.lastDate) profit += PERCENT_DIVIDEND.mul(deposit.amount) * (till - user.lastDate) / ONE_DAY;
    }

    uint256 bonus = getHoldBonus(userAddress) + getFundBonus() + getRefBonus(userAddress);
    profit += PERCENT_BONUS.mul(profit * bonus);

    return profit;
  }

  function rewardReferrers(uint256 amount, address referrer) internal {
    for (uint256 i = 0; i < PERCENT_REFERRAL.length; i++) {
      if (checkUserStatus(referrer)) {
        uint256 reward = PERCENT_REFERRAL[i].mul(amount);
        users[referrer].balance += reward;
        users[referrer].rewards += reward;
        users[referrer].turnover += amount;
        totalRewards += reward;
        
        referrer = users[referrer].referrer;
      } else break;
    }
  }

  function register(address referrer) internal {
    require(!checkUserStatus(msg.sender), "user already exists");
    require(referrer != address(0), "require not zero address");
    require(referrer != msg.sender, "referrer error");
    require(checkUserStatus(referrer), "referrer not found");

    users[msg.sender].status = true;
    users[msg.sender].referrer = referrer;
    users[msg.sender].lastDate = block.timestamp;

    for (uint256 i = 0; i < PERCENT_REFERRAL.length; i++) {
      users[msg.sender].referrals.push(0);
      if (checkUserStatus(referrer)) {
        users[referrer].referrals[i]++;
        referrer = users[referrer].referrer;
      }
    }

    emit Registration(msg.sender, referrer);
  }
  
  function deposit(address referrer) external payable {
    require(msg.value >= MIN_DEPOSIT, "msg.value must be >= MIN_DEPOSIT");
    if (checkUserStatus(msg.sender)) require(users[msg.sender].deposits.length <= 100, "max deposit count");
    if (!checkUserStatus(msg.sender)) register(referrer);

    uint256 amount = msg.value;
    rewardReferrers(amount, users[msg.sender].referrer);

    (bool success, ) = promote.call.value(PERCENT_PROMOTE.mul(amount))("");
    require(success, "Transfer failed");
    
    users[msg.sender].invested += uint256(amount);
    users[msg.sender].deposits.push(Deposit(amount, block.timestamp));

    totalInvested += amount;
    
    emit Investment(msg.sender, amount);
  }

  function withdraw() external {
    require(checkUserStatus(msg.sender), "user not found");

    uint256 amount = calculateProfit(msg.sender);
    amount += users[msg.sender].balance;
    users[msg.sender].balance = 0;
    users[msg.sender].withdrawn += amount;
    users[msg.sender].lastDate = block.timestamp;

    (bool success, ) = msg.sender.call.value(amount)("");
    require(success, "Transfer failed");
    
    emit Withdraw(msg.sender, amount);
  }
}