//SourceUnit: DaxTron.sol

pragma solidity 0.5.10;

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

contract DaxTron {
  using SafeMath for uint256;
  using Percent for Percent.percent;

  struct Deposit {
    uint256 amount;
    uint256 date;
  }

  struct RefInfo {
    uint256 count;
    uint256 turnover;
  }
  
  struct User {
    address referrer;
    bool status;

    RefInfo[] referrals;
    uint256 rewards;
    uint256 turnover;

    uint256 invested;
    uint256 withdrawn;

    Deposit[] deposits;
    uint256 balance;
    
    uint256 lastDate;
  }
  
  uint256 constant private ONE_DAY            = 1 days;
  uint256 constant private PROFIT_DAYS        = 100 days;
  uint256 constant private MIN_DEPOSIT        = 200 trx;
  uint256 constant private MUL_EVERY          = 5e6 trx;

  Percent.percent private PERCENT_DIVIDEND    = Percent.percent(25, 1000);
  Percent.percent private PERCENT_HOLD_BONUS  = Percent.percent(1, 1000);
  Percent.percent private PERCENT_FUND_BONUS  = Percent.percent(5, 1000);
  Percent.percent private PERCENT_PROMOTE     = Percent.percent(1, 10);
  Percent.percent[] private PERCENT_REFERRAL;

  uint256 public totalInvested;
  
  address private promote;
  mapping (address => User) public users;
  
  event Registration(address indexed user, address indexed referrer);
  event Investment(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  
  constructor(address promoteAddress) public {
    promote = promoteAddress;

    PERCENT_REFERRAL.push(Percent.percent(6, 100));
    PERCENT_REFERRAL.push(Percent.percent(2, 100));
    PERCENT_REFERRAL.push(Percent.percent(2, 100));
    PERCENT_REFERRAL.push(Percent.percent(1, 100));
    PERCENT_REFERRAL.push(Percent.percent(1, 100));
    PERCENT_REFERRAL.push(Percent.percent(1, 100));

    users[promoteAddress].status = true;
    for (uint256 i = 0; i < PERCENT_REFERRAL.length; i++) {
      users[promoteAddress].referrals.push(RefInfo(0, 0));
    }
  }

  function checkUserStatus(address user) public view returns (bool) {
    return users[user].status == true;
  }

  function referralsInfoByLevel(address user, uint256 level) external view returns (uint256, uint256) {
    return (
      users[user].referrals[level].count,
      users[user].referrals[level].turnover
    );
  }

  function getHoldBonus(address user) public view returns (uint256) {
    if (users[user].deposits.length == 0) return 0;
    return block.timestamp.sub(users[user].lastDate).div(ONE_DAY);
  }
  
  function getFundBonus() public view returns (uint256) {
    return address(this).balance.div(MUL_EVERY);
  }

  function calculateProfit(address userAddress) public view returns (uint256) {
    User memory user = users[userAddress];
    
    if (user.deposits.length == 0) return 0;
    
    uint256 profit = 0;
    for (uint256 i = 0; i < user.deposits.length; i++) {
      Deposit memory deposit = user.deposits[i];
      uint256 finish = deposit.date.add(PROFIT_DAYS);
      uint256 since = user.lastDate > deposit.date ? user.lastDate : deposit.date;
      uint256 till = block.timestamp > finish ? finish : block.timestamp;
      if (till > since) {
        uint256 leftdays = block.timestamp.sub(since).div(ONE_DAY);
        uint256 dividends = PERCENT_DIVIDEND.mul(deposit.amount).mul(till.sub(since)).div(ONE_DAY);
        uint256 holdBonus = PERCENT_HOLD_BONUS.mul(deposit.amount.mul(getHoldBonus(userAddress))) * leftdays;
        uint256 fundBonus = PERCENT_FUND_BONUS.mul(deposit.amount.mul(getFundBonus())) * leftdays;
        profit = profit.add(dividends).add(holdBonus).add(fundBonus);
      }
    }

    return profit;
  }

  function rewardReferrers(uint256 amount, address referrer) internal {
    for (uint256 i = 0; i < PERCENT_REFERRAL.length; i++) {
      if (checkUserStatus(referrer)) {
        uint256 reward = PERCENT_REFERRAL[i].mul(amount);
        users[referrer].balance = users[referrer].balance.add(reward);
        users[referrer].rewards = users[referrer].rewards.add(reward);
        users[referrer].turnover = users[referrer].turnover.add(amount);
        users[referrer].referrals[i].turnover = users[referrer].referrals[i].turnover.add(amount);
        
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
      users[msg.sender].referrals.push(RefInfo(0, 0));
      if (checkUserStatus(referrer)) {
        users[referrer].referrals[i].count++;
        referrer = users[referrer].referrer;
      }
    }

    emit Registration(msg.sender, users[msg.sender].referrer);
  }
  
  function deposit(address referrer) external payable {
    require(msg.value >= MIN_DEPOSIT, "msg.value must be >= MIN_DEPOSIT");
    if (checkUserStatus(msg.sender)) require(users[msg.sender].deposits.length <= 100, "max deposit count");
    if (!checkUserStatus(msg.sender)) register(referrer);

    uint256 amount = msg.value;
    rewardReferrers(amount, users[msg.sender].referrer);

    (bool success, ) = promote.call.value(PERCENT_PROMOTE.mul(amount))("");
    require(success, "Transfer failed");
    
    users[msg.sender].invested = users[msg.sender].invested.add(amount);
    users[msg.sender].deposits.push(Deposit(amount, block.timestamp));
    totalInvested = totalInvested.add(amount);
    
    emit Investment(msg.sender, amount);
  }

  function withdraw() external {
    require(checkUserStatus(msg.sender), "user not found");

    uint256 amount = calculateProfit(msg.sender);
    amount = amount.add(users[msg.sender].balance);
    users[msg.sender].balance = 0;
    users[msg.sender].withdrawn = users[msg.sender].withdrawn.add(amount);
    users[msg.sender].lastDate = block.timestamp;

    (bool success, ) = msg.sender.call.value(amount)("");
    require(success, "Transfer failed");
    
    emit Withdraw(msg.sender, amount);
  }
}