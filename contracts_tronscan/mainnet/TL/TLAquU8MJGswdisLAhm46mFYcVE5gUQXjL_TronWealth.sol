//SourceUnit: TronWealth.sol

 /*  

  ▀▀█▀▀ ▒█▀▀█ ▒█▀▀▀█ ▒█▄░▒█ 　 ▒█░░▒█ ▒█▀▀▀ ░█▀▀█ ▒█░░░ ▀▀█▀▀ ▒█░▒█ 
  ░▒█░░ ▒█▄▄▀ ▒█░░▒█ ▒█▒█▒█ 　 ▒█▒█▒█ ▒█▀▀▀ ▒█▄▄█ ▒█░░░ ░▒█░░ ▒█▀▀█ 
  ░▒█░░ ▒█░▒█ ▒█▄▄▄█ ▒█░░▀█ 　 ▒█▄▀▄█ ▒█▄▄▄ ▒█░▒█ ▒█▄▄█ ░▒█░░ ▒█░▒█

  SMART CONTRACT PROPERTIES

  - 4% daily passive income.
  - 4 referral levels: 5%, 3%, 2%, 3%.
  - 90 days - maximal deposit active time.
  - 360% total ROI.
  - Minimal 100 TRX deposit.
  - No limits for amount of deposits/withdrawals.

  REFERRAL PROGRAM

  - We have 4 referral levels in our smart contract: 5%, 3%, 2%, 3%.
  - You need to make 1 or more deposits to activate your referral link.
  - You can still join without referral link. devAddress will be automatically linked with your account.
  - You cannot change your referral after first deposit.

  TRX DISTRIBUTION

  - 72% Contract balance for contributors' rewards
  - 13% Referral program rewards
  - 9% Developer fee
  - 6% Marketing fee

*/

pragma solidity ^0.5.9;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract TronWealth {
  using SafeMath for uint256;

  address payable public devAddress; // Developer team
  address payable public marketAddress; // Marketing team
  address payable public owner; // Smart contract deployer

  // shares in percents:
  uint256[] public refRewards = [5, 3, 2, 3]; // 4 referral levels
  uint256 public constant devReward = 9; // 9% fee for developer team
  uint256 public constant marketReward = 6; // 6% fee for marketing team

  uint256 public constant rewardDays = 90; // Maximal deposit duration
  uint256 public constant rewardAmountPerDay = 4; // Reward per day - 4%

  uint256 public constant minDeposit = 100 trx;
  uint256 public constant release = 1627473600; // Time of contract start in unix format

  uint256 public totalDeposited;
  uint256 public totalWithdrawn;
  uint256 public totalInvestors;

  struct Deposits {
    uint256 amount;
    uint256 timestamp;
  }

  struct Withdrawals {
    uint256 amount;
    uint256 timestamp;
  }

  struct User {
    address addr;
    address referrer;
    uint256 totalDeposited;
    uint256 totalWithdrawn;
    uint256 lastPayout;

    uint256 account;
    uint256 totalRefRewards;
    uint256[4] refsAtLevel;

    Deposits[] deposits;
    Withdrawals[] withdrawals;
  }

  mapping(address => User) private users;

  event Deposit(address indexed addr, uint256 amount);
  event Withdraw(address indexed addr, uint256 amount);

  constructor(address payable _devAddress, address payable _marketAddress) public {
    devAddress = _devAddress;
    marketAddress = _marketAddress;
    owner = msg.sender;
  }

  function deposit(address _refAddress) external payable {
    require(msg.value >= minDeposit, "Your deposit amount is too low.");
    require(uint256(block.timestamp) > release, "Contract not started yet.");
    User storage currentUser = users[msg.sender];
    currentUser.addr = msg.sender;

    if (currentUser.referrer == address(0)) {
      if (users[_refAddress].totalDeposited > 0) currentUser.referrer = _refAddress;
      else currentUser.referrer = devAddress;
    }
    
    if (currentUser.totalDeposited == 0) {
      totalInvestors++;

      address referrerAddr = currentUser.referrer;
      for(uint256 i=0; i<refRewards.length; i++) {
        users[referrerAddr].refsAtLevel[i] += 1;

        if (users[referrerAddr].referrer == address(0)) break;
        referrerAddr = users[referrerAddr].referrer;
      }
    }

    uint256 _devReward = msg.value.mul(devReward).div(100);
    uint256 _marketReward = msg.value.mul(marketReward).div(100);
    if (canPayout(_devReward.add(_marketReward))) {
      devAddress.transfer(_devReward);
      marketAddress.transfer(_marketReward);
    }

    currentUser.totalDeposited += msg.value;
    totalDeposited += msg.value;
    
    currentUser.deposits.push(Deposits({
      amount: msg.value,
      timestamp: block.timestamp
    }));

    _addRewards(msg.sender,msg.value);
    emit Deposit(msg.sender, msg.value);
  }

  function canPayout(uint256 _amount) view public returns(bool res) {
    return address(this).balance > _amount;
  }

  function _addRewards(address origin, uint256 _amount) private {
    User storage currentUser = users[origin];
    for(uint256 i=0; i<refRewards.length; i++) {
      users[currentUser.referrer].totalRefRewards += _amount.mul(refRewards[i]).div(100);

      currentUser = users[currentUser.referrer];
      if (currentUser.referrer == address(0)) break;
    }
  }

  function withdraw() public {
    require(address(this).balance > 0, "Cannot withdraw right now.");
    User storage currentUser = users[msg.sender];

    uint256 profit = calcProfit(msg.sender).add(currentUser.totalRefRewards).add(currentUser.account);
    require(profit > 0, "No funds to withdraw.");
    currentUser.totalRefRewards = 0;

    if (!canPayout(profit)) {
      currentUser.account = profit.sub(address(this).balance);
      profit = address(this).balance;
    } else {
      currentUser.account = 0;
    }

    currentUser.lastPayout = block.timestamp;

    currentUser.totalWithdrawn += profit;
    totalWithdrawn += profit;

    currentUser.withdrawals.push(Withdrawals({
      amount: profit,
      timestamp: block.timestamp
    }));

    msg.sender.transfer(profit);
    emit Withdraw(msg.sender, profit);
  }

  function calcProfit(address _addr) view public returns(uint256 amount) {
    User memory currentUser = users[_addr];

    for(uint256 i=0; i<currentUser.deposits.length; i++) {
      Deposits memory dep = currentUser.deposits[i];

      uint256 maxRewardTime = dep.timestamp + rewardDays * 86400;

      uint256 limitUp = maxRewardTime > block.timestamp ? block.timestamp : maxRewardTime;
      uint256 limitDown = currentUser.lastPayout > dep.timestamp ? currentUser.lastPayout : dep.timestamp;
      if(limitUp > limitDown) {
        uint256 reward = dep.amount.mul(limitUp-limitDown).mul(rewardAmountPerDay).div(8640000);
        amount = amount.add(reward);
      }
    }
    return amount;
  }

  function userInfo(address _addr) view public returns(
    uint256 profit,
    uint256 referral_rewards,
    uint256 total_deposited,
    uint256 total_withdrawn,
    uint256 last_payout,
    uint256[4] memory refsAtLevel
  ) {
    User memory currentUser = users[_addr];
    profit = calcProfit(_addr);

    return (
      profit,
      currentUser.totalRefRewards,
      currentUser.totalDeposited,
      currentUser.totalWithdrawn,
      currentUser.lastPayout,
      currentUser.refsAtLevel
    );
  }

  function contractInfo() view public returns(
    uint256 total_deposited,
    uint256 total_withdrawn,
    uint256 total_investors
  ) {
    return (
      totalDeposited,
      totalWithdrawn,
      totalInvestors
    );
  }

  function withdrawalsOf(address _addr) view external returns(uint256[] memory amounts, uint256[] memory timestamps) {
    User storage currentUser = users[_addr];

    uint256[] memory _amounts = new uint256[](currentUser.withdrawals.length);
    uint256[] memory _timestamps = new uint256[](currentUser.withdrawals.length);

    for(uint256 i=0; i<currentUser.withdrawals.length; i++) {
      _amounts[i]=currentUser.withdrawals[i].amount;
      _timestamps[i]=currentUser.withdrawals[i].timestamp;
    }

    return (
      _amounts,
      _timestamps
    );
  }

  function depositsOf(address _addr) view external returns(uint256[] memory amounts, uint256[] memory timestamps) {
    User memory currentUser = users[_addr];

    uint256[] memory _amounts = new uint256[](currentUser.deposits.length);
    uint256[] memory _timestamps = new uint256[](currentUser.deposits.length);

    for(uint256 i=0; i<currentUser.deposits.length; i++) {
      _amounts[i]=currentUser.deposits[i].amount;
      _timestamps[i]=currentUser.deposits[i].timestamp;
    }

    return (
      _amounts,
      _timestamps
    );
  }
}