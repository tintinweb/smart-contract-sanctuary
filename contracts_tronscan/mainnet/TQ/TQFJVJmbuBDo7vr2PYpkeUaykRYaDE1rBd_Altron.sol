//SourceUnit: Altron.sol

pragma solidity 0.5.10;

/**
 *   
 *     ______   __    ________  _______    ______   __    __ 
 *    /      \ |  \  |        \|       \  /      \ |  \  |  \
 *   |  $$$$$$\| $$   \$$$$$$$$| $$$$$$$\|  $$$$$$\| $$\ | $$
 *   | $$__| $$| $$     | $$   | $$__| $$| $$  | $$| $$$\| $$
 *   | $$    $$| $$     | $$   | $$    $$| $$  | $$| $$$$\ $$
 *   | $$$$$$$$| $$     | $$   | $$$$$$$\| $$  | $$| $$\$$ $$
 *   | $$  | $$| $$_____| $$   | $$  | $$| $$__/ $$| $$ \$$$$
 *   | $$  | $$| $$     \ $$   | $$  | $$ \$$    $$| $$  \$$$
 *    \$$   \$$ \$$$$$$$$\$$    \$$   \$$  \$$$$$$  \$$   \$$
 *                                                           
 *                                                           
 *                           _                     _                  _   
 *  ___ _ __ ___   __ _ _ __| |_    ___ ___  _ __ | |_ _ __ __ _  ___| |_ 
 * / __| '_ ` _ \ / _` | '__| __|  / __/ _ \| '_ \| __| '__/ _` |/ __| __|
 * \__ \ | | | | | (_| | |  | |_  | (_| (_) | | | | |_| | | (_| | (__| |_ 
 * |___/_| |_| |_|\__,_|_|   \__|  \___\___/|_| |_|\__|_|  \__,_|\___|\__|
 *                                                                                                                                    
 *                                                     
 *                                                        
 *                                                       
 * 
 * ALTRON - is a leading decentralized, 100% community based, a next-generation pool. 
 * Funding platform that is powered by the Tron smart contract, and the TRX coin.
 * Verified, audited, safe and legit!
 * 
 * - Starting profit is 2% per day
 * - The Deposit is active for 150 days
 * - Minimum input amount is 100 TRX
 * - Maximum input amount is 1 000 000 TRX
 * - Minimum withdrawal amount: no limit
 * - Payment regulation: immediately
 * - 5 levels affiliate program: 5% - 3% - 2% - 1% - 1%
 *
 * - Bonuses:
 * 1. Hold bonus. There is profits growth by 0.1% per day, if you're not withdrawing funds during 24 hours. 
 * 2. Fund bonus. Every participant's profit increases by 0.1% per 24 hours for each million of Tronos on contracts balance.
 * 3. Referral bonus. Your profit increases by 0.1% per 24 hours for each million of Tronos contributed by your referrals.
 * 
 * 
 * [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Banko
 *   2) Send any TRX amount (100 TRX minimum) using our website invest button
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 * 
 *  
 * JOIN US ON TELEGRAM: https://t.me/altron_eng
 * 
 * 
 * Web: https://altron.space/
 *
 *
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
    uint256 num;
    uint256 den;
  }
  function mul(percent storage p, uint256 a) internal view returns (uint256) {
    if (a == 0) {
      return 0;
    }
    return a*p.num/p.den;
  }

  function div(percent storage p, uint256 a) internal view returns (uint256) {
    return a/p.num*p.den;
  }

  function sub(percent storage p, uint256 a) internal view returns (uint256) {
    uint256 b = mul(p, a);
    if (b >= a) return 0;
    return a - b;
  }

  function add(percent storage p, uint256 a) internal view returns (uint256) {
    return a + mul(p, a);
  }
}

contract Altron {
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
  
  uint256 constant private ONE_DAY            = 1 days;
  uint256 constant private PROFIT_DAYS        = 150 days;
  uint256 constant private MIN_DEPOSIT        = 100 trx;
  uint256 constant private ONE_MILLION        = 1e6 trx;

  Percent.percent private PERCENT_DIVIDEND    = Percent.percent(2, 100);
  Percent.percent private PERCENT_BONUS       = Percent.percent(1, 1000);
  Percent.percent private PERCENT_PROMOTE     = Percent.percent(15, 100);
  Percent.percent[] private PERCENT_REFERRAL;

  uint256 public totalInvested;
  uint256 public totalRewards;
  
  address public promote;
  mapping (address => User) public users;
  
  event Registration(address indexed user, address indexed referrer);
  event Investment(address indexed user, uint256 amount);
  event Withdraw(address indexed user, uint256 amount);
  
  constructor(address promoteAddress) public {
    promote = promoteAddress;

    PERCENT_REFERRAL.push(Percent.percent(5, 100));
    PERCENT_REFERRAL.push(Percent.percent(3, 100));
    PERCENT_REFERRAL.push(Percent.percent(2, 100));
    PERCENT_REFERRAL.push(Percent.percent(1, 100));
    PERCENT_REFERRAL.push(Percent.percent(1, 100));

    users[promoteAddress].status = true;
    users[promoteAddress].lastDate = block.timestamp;
    for (uint256 i = 0; i < PERCENT_REFERRAL.length; i++) {
      users[promoteAddress].referrals.push(0);
    }
  }

  function checkUserStatus(address user) public view returns (bool) {
    return users[user].status == true;
  }

  function referralsCount(address user) external view returns (uint256, uint256, uint256, uint256, uint256) {
    return (
      users[user].referrals[0],
      users[user].referrals[1],
      users[user].referrals[2],
      users[user].referrals[3],
      users[user].referrals[4]
    );
  }

  function getHoldBonus(address user) public view returns (uint256) {
    if (users[user].lastDate == 0) return 0;
    return block.timestamp.sub(users[user].lastDate).div(ONE_DAY);
  }
  
  function getFundBonus() public view returns (uint256) {
    return address(this).balance.div(ONE_MILLION);
  }

  function getRefBonus(address user) public view returns (uint256) {
    return users[user].turnover.div(ONE_MILLION);
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
        uint256 totalBonuses = getHoldBonus(userAddress) + getFundBonus() + getRefBonus(userAddress);
        uint256 bonus = PERCENT_BONUS.mul(deposit.amount.mul(totalBonuses)).mul(leftdays);
        profit = profit.add(dividends).add(bonus);
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

    emit Registration(msg.sender, users[msg.sender].referrer);
  }
  
  function deposit(address referrer) external payable {
    require(msg.value >= MIN_DEPOSIT, "msg.value must be >= MIN_DEPOSIT");
    require(msg.value <= ONE_MILLION, "msg.value must be >= ONE_MILLION");
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