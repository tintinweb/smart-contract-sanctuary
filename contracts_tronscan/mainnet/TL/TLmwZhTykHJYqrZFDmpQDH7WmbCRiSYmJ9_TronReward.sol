//SourceUnit: tronReward.sol

pragma solidity ^0.4.25;

contract TronReward
{
  struct Deposit {
    Tariff tariff;
    uint256 amount;
    uint256 date;
    bool isExpired;
    bool isEndPlan;
    uint256 endTime;
    uint256 withdraw;
    uint256 lastPaidDate;
  }

  struct Tariff {
    uint256 id;
    uint256 time;
    uint256 percent;
  }

  struct Reward {
    bool[12] rewards;
    uint256[12] counts;
    uint256[12] amounts;
    uint256 amountReward;
    uint256 totalReward;
  }
  struct Referral {
    uint256 level;
    uint256 percent;
    uint256 count;
  }

  struct BonusDay{
    address addr;
    uint256 bonus;
    uint256 day;
  }

  struct Investor {
    bool registered;
    address referer;
    Referral[] referrals;
    uint256 balanceRef;
    uint256 totalRef;
    Deposit[] deposits;
    uint256 invested;
    uint256 twithdraw;
    Reward reward;
    uint256[5] amounts;
  }

  uint256 private constant MIN_DEPOSIT = 100000000;
  uint256 private constant START_AT =1602082800;
  uint256 private constant OWNER_RATE = 3;
  uint256 private constant ADMIN_RATE = 2;
  uint256 private constant MARKETING_RATE = 5;

  address  private owner = msg.sender;
  address  private admin;
  address  private marketing;
  address  private defaultReference;

  Tariff[] private tariffs;
  uint256 public totalInvestors;
  uint256 public first50Investors;
  uint256 public totalInvested;
  uint256 public totalRefRewards;
  BonusDay public bonusDay;
  BonusDay public lastBonusDay;
  bool[12] _rewards =[false,false,false,false,false,false,false,false,false,false,false,false];
  uint256[12] _counts =[0,0,0,0,0,0,0,0,0,0,0,0];
  uint256[12] _amounts =[0,0,0,0,0,0,0,0,0,0,0,0];
  mapping (address => Investor) public investors;


  event WinnerBonus(address user,uint256 amount);
  event UpdateBonus(address user,uint256 amount);


  constructor(address _admin, address _marketing, address _df) public {

    admin = _admin;
    marketing = _marketing;
    defaultReference = _df;

    tariffs.push(Tariff(0, 25*60*60*24, 125));
    tariffs.push(Tariff(1, 27*60*60*24, 130));
    tariffs.push(Tariff(2, 29*60*60*24, 134));
    tariffs.push(Tariff(3, 32*60*60*24, 141));

    bonusDay.addr = defaultReference;
    bonusDay.bonus = 0;
    bonusDay.day = block.timestamp / 1 days;
    lastBonusDay = bonusDay;
  }

  function getUserReferrals(address user) public view returns ( uint256[] memory levels , uint256[] memory percents ,uint256[] memory counts){
    levels =  new uint256[](investors[user].referrals.length);
    percents =  new uint256[](investors[user].referrals.length);
    counts =  new uint256[](investors[user].referrals.length);

    for (uint256 i = 0; i <investors[user].referrals.length; i++) {
       levels[i] = investors[user].referrals[i].level;
       percents[i] = investors[user].referrals[i].percent;
       counts[i] = investors[user].referrals[i].count;
    }
    return (levels,percents,counts);
  }
  function cleanAmountReward() private {

    for (uint256 i = 0; i < investors[msg.sender].reward.rewards.length; i++) {
      if (investors[msg.sender].reward.rewards[i]) {
          investors[msg.sender].reward.amounts[i] = 0;
      }
    }

  }
  function rewardsDeposit(address user,uint256 depId) internal {
    if (investors[user].deposits[depId].amount >= 15000000000 && !investors[user].reward.rewards[0]) {
        investors[user].reward.rewards[0] = true;
        investors[user].reward.amounts[0] = investors[user].deposits[depId].amount * 5 / 100;
        investors[user].reward.amountReward += investors[user].reward.amounts[0];
        investors[user].reward.counts[0]++;
    }
    if (investors[user].deposits[depId].amount >= 7000000000 && investors[user].deposits[depId].amount < 15000000000 && !investors[user].reward.rewards[1]) {
        investors[user].reward.counts[1]++;
        investors[user].amounts[0] += investors[user].deposits[depId].amount;
       if (investors[user].reward.counts[1] == 2 ) {
         investors[user].reward.rewards[1] = true;
         investors[user].reward.amounts[1] = investors[user].amounts[0] * 4 / 100;
         investors[user].reward.amountReward += investors[user].reward.amounts[1];
       }
    }
    if (investors[user].deposits[depId].amount >= 4000000000 && investors[user].deposits[depId].amount < 7000000000 && !investors[user].reward.rewards[2] ) {
       investors[user].reward.counts[2]++;
       investors[user].amounts[1] += investors[user].deposits[depId].amount;
       if (investors[user].reward.counts[2] == 3 ) {
         investors[user].reward.rewards[2] = true;
         investors[user].reward.amounts[2] = investors[user].amounts[1] * 3 / 100;
         investors[user].reward.amountReward += investors[user].reward.amounts[2];
       }
    }
    if (investors[user].deposits[depId].amount >= 2000000000 && investors[user].deposits[depId].amount < 4000000000 && !investors[user].reward.rewards[3]) {
       investors[user].reward.counts[3]++;
       investors[user].amounts[2] += investors[user].deposits[depId].amount;
       if (investors[user].reward.counts[3] == 4) {
         investors[user].reward.rewards[3] = true;
         investors[user].reward.amounts[3] = investors[user].amounts[2] * 2 / 100;
         investors[user].reward.amountReward += investors[user].reward.amounts[3];
       }
    }
    if (investors[user].deposits[depId].amount >= 1000000000 && investors[user].deposits[depId].amount < 2000000000 && !investors[user].reward.rewards[4]) {
       investors[user].reward.counts[4]++;
       investors[user].amounts[3] += investors[user].deposits[depId].amount;
       if (investors[user].reward.counts[4] == 5) {
         investors[user].reward.rewards[4] = true;
         investors[user].reward.amounts[4] = investors[user].amounts[3] * 1 / 100;
         investors[user].reward.amountReward += investors[user].reward.amounts[4];
       }
    }
    if (investors[user].deposits[depId].amount >= 500000000 && investors[user].deposits[depId].amount < 1000000000 && !investors[user].reward.rewards[5]) {
       investors[user].reward.counts[5]++;
       investors[user].amounts[4] += investors[user].deposits[depId].amount;
       if (investors[user].reward.counts[5] == 6) {
         investors[user].reward.rewards[5] = true;
         investors[user].reward.amounts[5] = investors[user].amounts[4] * 5 / 1000;
         investors[user].reward.amountReward += investors[user].reward.amounts[5];
       }
    }
  }
  function rewardsReffer(address user) internal {
    if (investors[user].referrals[0].count + investors[user].referrals[1].count >= 10 && !investors[user].reward.rewards[9]) {
          investors[user].reward.rewards[9] = true;

          for (uint256 j = 0; j < investors[user].referrals.length; j++) {
             investors[user].referrals[j].percent +=1;
          }
    }
    if (investors[user].referrals[0].count + investors[user].referrals[1].count >= 15 && !investors[user].reward.rewards[10]) {
          investors[user].reward.rewards[10] = true;
          investors[user].referrals.push(Referral(5,1,0));
    }
  }
  function rewardsTotalPlan(address user,uint256 depId) internal {
    if (block.timestamp >= investors[user].deposits[depId].endTime && investors[user].deposits[depId].withdraw == 0 ) {
        if (!investors[user].deposits[depId].isEndPlan) {
          investors[user].reward.rewards[7]=true;
          investors[user].reward.counts[7]++;
          uint256 amount=0;
          uint256 tariff= investors[user].deposits[depId].tariff.id;
          if (tariff == 0) {
            amount = investors[user].deposits[depId].amount * 25 / 100;
          }else if (tariff == 1) {
            amount = investors[user].deposits[depId].amount * 35 / 100;
          }else if (tariff == 2) {
            amount = investors[user].deposits[depId].amount * 45 / 100;
          }else if (tariff == 3) {
            amount = investors[user].deposits[depId].amount * 55 / 100;
          }
          investors[user].reward.amounts[7] += amount;
          investors[user].reward.amountReward += amount;
          investors[user].deposits[depId].isEndPlan = true;
        }
    }
  }
  function rewardsBestPlan(address user) internal {
    if ((investors[user].reward.rewards[0] || investors[user].reward.rewards[1] || investors[user].reward.rewards[2])
          && investors[user].reward.rewards[9] && investors[user].reward.rewards[10] && investors[user].reward.rewards[6] && investors[user].reward.rewards[7] && investors[user].reward.rewards[8] && !investors[user].reward.rewards[11]) {
       uint256 amount=0;
       for (uint256 i = 0; i < investors[user].deposits.length; i++) {
         if (investors[user].deposits[i].endTime > block.timestamp) {
             amount += investors[user].deposits[i].amount;
         }
       }
       investors[user].reward.rewards[11] = true;
       investors[user].reward.counts[11]++;
       investors[user].reward.amounts[11] = amount * 30 / 100;
       investors[user].reward.amountReward += investors[user].reward.amounts[11];

    }
  }
  function getInvestReward() public view returns (bool[] memory rewards , uint256[] memory amounts, uint256[] memory counts, uint256 amountReward,uint256 totalReward)  {
      require(investors[msg.sender].registered, "The user need to be registered as an investor");
      rewards =  new bool[](investors[msg.sender].reward.rewards.length);
      amounts =  new uint256[](investors[msg.sender].reward.amounts.length);
      counts =  new uint256[](investors[msg.sender].reward.counts.length);
      amountReward = investors[msg.sender].reward.amountReward;
      totalReward = investors[msg.sender].reward.totalReward;
      for (uint256 i = 0; i < investors[msg.sender].reward.rewards.length; i++) {
         rewards[i] = investors[msg.sender].reward.rewards[i];
         amounts[i] = investors[msg.sender].reward.amounts[i];
         counts[i] = investors[msg.sender].reward.counts[i];
      }
      return (rewards, amounts, counts, amountReward,totalReward);
  }
  function register(address referer) internal {

      investors[msg.sender].registered = true;
      totalInvestors++;
      investors[msg.sender].referrals.push(Referral(1,4,0));
      investors[msg.sender].referrals.push(Referral(2,3,0));
      investors[msg.sender].referrals.push(Referral(3,2,0));
      investors[msg.sender].referrals.push(Referral(4,1,0));

      investors[msg.sender].referer = defaultReference;
      investors[msg.sender].reward= Reward(_rewards,_counts,_amounts,0,0);
      investors[msg.sender].twithdraw = 0;
      if (investors[referer].registered && referer != msg.sender) {
        investors[msg.sender].referer = referer;
        rewardReferers(msg.value,investors[msg.sender].referer);
        address rec = referer;
        for (uint256 i = 0; i < investors[rec].referrals.length; i++) {
          if (!investors[rec].registered) {
            break;
          }
          investors[rec].referrals[i].count++;
          if (i < 2) {
            investors[rec].reward.counts[9]++;
            investors[rec].reward.counts[10]++;

            if (investors[rec].reward.counts[9] >= 10) {
                rewardsReffer(rec);
            }
            if (investors[rec].reward.counts[10] >= 15) {
                rewardsBestPlan(rec);
            }
          }

          rec = investors[rec].referer;
        }
      }

  }
  function rewardReferers(uint256 amount, address referer) internal {
    address rec = referer;

    for (uint256 i = 0; i < investors[rec].referrals.length; i++) {
      if (!investors[rec].registered) {
        break;
      }
      uint256 a = amount * (investors[rec].referrals[i].percent) / 100;
      investors[rec].balanceRef += a;
      totalRefRewards += a;
      rec = investors[rec].referer;
    }
  }
  function deposit(uint256 tariff, address referer) public payable  {
    require(uint256(block.timestamp) > START_AT, "Not launched");
    require(msg.value >= MIN_DEPOSIT, "Less than the minimum amount of deposit requirement");
    require(tariff < tariffs.length && tariff >= 0, "Wrong investment tariff id");

    if(msg.value >= 5000000000 && first50Investors < 50){
        msg.sender.transfer(msg.value * 2 / 100);
        first50Investors++;
      }
    if (!investors[msg.sender].registered) {
      register(referer);
    }else {
      rewardReferers(msg.value, investors[msg.sender].referer);
    }
    owner.transfer(msg.value * OWNER_RATE / 100);
    admin.transfer(msg.value * ADMIN_RATE / 100);
    marketing.transfer(msg.value * MARKETING_RATE / 100);

    investors[msg.sender].invested += msg.value;
    totalInvested = totalInvested + msg.value;

    investors[msg.sender].deposits.push(Deposit(tariffs[tariff], msg.value, block.timestamp,false,false,block.timestamp + tariffs[tariff].time,0,block.timestamp));

    if (msg.value > bonusDay.bonus) {
       bonusDay.bonus = msg.value;
       bonusDay.addr = msg.sender;
       emit UpdateBonus(bonusDay.addr, bonusDay.bonus);
    }
    rewardsDeposit(msg.sender,investors[msg.sender].deposits.length-1);
    rewardsBestPlan(msg.sender);
  }
  function reinvest(uint256 tariff,uint256 investId) public payable {
    uint256 amount = withdrawableInvest(msg.sender,investId);
    require(tariff < tariffs.length && tariff >= 0, "Wrong investment tariff id");
    require(investors[msg.sender].registered, "You need to be registered as an investor to invest");

    if (address(this).balance > amount * (OWNER_RATE+ADMIN_RATE) / 100) {
      owner.transfer(amount * OWNER_RATE / 100);
      admin.transfer(amount * ADMIN_RATE / 100);
    }
    investors[msg.sender].invested += amount;
    totalInvested += amount;
    investors[msg.sender].deposits.push(Deposit(tariffs[tariff], amount, block.timestamp,false,false,block.timestamp + tariffs[tariff].time,0,block.timestamp));

    if (amount >= investors[msg.sender].deposits[investId].amount * 40/100) {
      investors[msg.sender].reward.rewards[6] = true;
      investors[msg.sender].reward.amounts[6] += amount * 5 / 100;
      investors[msg.sender].reward.counts[6]++;
      investors[msg.sender].reward.amountReward += amount * 5 / 100;
    }

    if (block.timestamp >= investors[msg.sender].deposits[investId].endTime) {
        investors[msg.sender].deposits[investId].isExpired = true;
        rewardsTotalPlan(msg.sender,investId);
    }
    rewardsDeposit(msg.sender,investors[msg.sender].deposits.length-1);
    rewardsBestPlan(msg.sender);
    investors[msg.sender].deposits[investId].lastPaidDate = block.timestamp;

  }
  function withdrawable(address user) public view returns (uint256 amount) {
    require(investors[user].registered, "The user need to be registered as an investor");

    for (uint256 i = 0; i < investors[user].deposits.length; i++) {

      if (investors[user].deposits[i].isExpired) {
        continue;
      }
      amount += withdrawableInvest(user,i);
    }
    return amount;
  }
  function withdrawableInvest(address user, uint256 depId) public view returns (uint256 amount ) {

      uint256 since = investors[user].deposits[depId].lastPaidDate > investors[user].deposits[depId].date ? investors[user].deposits[depId].lastPaidDate : investors[user].deposits[depId].date;
      uint256 till = block.timestamp > investors[user].deposits[depId].endTime ? investors[user].deposits[depId].endTime : block.timestamp;

      if (since < till) {
        amount = investors[user].deposits[depId].amount * (till - since) * investors[user].deposits[depId].tariff.percent / investors[user].deposits[depId].tariff.time/100;
      }

      return amount;

  }
  function withdrawReward() external  {
    require(investors[msg.sender].registered, "You need to be registered as an investor");
    require(address(this).balance >= investors[msg.sender].reward.amountReward);

    if (msg.sender.send(investors[msg.sender].reward.amountReward)) {
       cleanAmountReward();
       investors[msg.sender].reward.totalReward += investors[msg.sender].reward.amountReward;
       investors[msg.sender].reward.amountReward = 0;

    }
  }
  function withdrawReffer() external {
    require(investors[msg.sender].registered, "You need to be registered as an investor");
    require(address(this).balance >=  investors[msg.sender].balanceRef);

    if (msg.sender.send(investors[msg.sender].balanceRef)) {
      investors[msg.sender].totalRef += investors[msg.sender].balanceRef;
      investors[msg.sender].balanceRef = 0;
    }
  }
  function withdraw() external {
    require(investors[msg.sender].registered, "You need to be registered as an investor");
    uint256 totalAmount = withdrawable(msg.sender);
    require(address(this).balance >= totalAmount);
    if (totalAmount > 0) {
      if (msg.sender.send(totalAmount)) {
        for (uint256 j = 0; j < investors[msg.sender].deposits.length; j++) {

          if (investors[msg.sender].deposits[j].isExpired) {
            continue;
          }

          if (block.timestamp >= investors[msg.sender].deposits[j].endTime) {
            investors[msg.sender].deposits[j].isExpired = true;
            rewardsTotalPlan(msg.sender,j);
          }
          investors[msg.sender].deposits[j].withdraw += withdrawableInvest(msg.sender,j);
          investors[msg.sender].deposits[j].lastPaidDate = block.timestamp;
        }
        investors[msg.sender].twithdraw += totalAmount;
        rewardsBestPlan(msg.sender);
      }
     }
  }
  function withdrawInvest(uint256 investId) external {
    require(investors[msg.sender].registered, "You need to be registered as an investor");
    require(investId >= 0 && investId < investors[msg.sender].deposits.length);
    require(!investors[msg.sender].deposits[investId].isExpired);
    uint256 amount = withdrawableInvest(msg.sender,investId);
    require(address(this).balance >= amount);

    if (msg.sender.send(amount)) {
      if (block.timestamp >= investors[msg.sender].deposits[investId].endTime) {
          investors[msg.sender].deposits[investId].isExpired = true;
          rewardsTotalPlan(msg.sender,investId);
      }
      investors[msg.sender].twithdraw += amount;
      investors[msg.sender].deposits[investId].withdraw += amount;
      investors[msg.sender].deposits[investId].lastPaidDate = block.timestamp;
      rewardsBestPlan(msg.sender);
    }
  }
  function getInvestmentsByAddr(address _addr) public view returns (uint256[] memory tariffIds , uint256[] memory dates,uint256[] memory endTimes, uint256[] memory amounts , uint256[] memory withdrawns , bool[] memory isExpireds, uint256[] memory newDividends) {
      if (address(msg.sender) != owner) {
          require(address(msg.sender) == _addr, "only owner or self can check the investment plan info.");
      }


       tariffIds = new  uint256[](investors[msg.sender].deposits.length);
       dates = new  uint256[](investors[msg.sender].deposits.length);
       endTimes = new  uint256[](investors[msg.sender].deposits.length);
       amounts = new  uint256[](investors[msg.sender].deposits.length);
       withdrawns = new  uint256[](investors[msg.sender].deposits.length);
       isExpireds = new  bool[](investors[msg.sender].deposits.length);
       newDividends = new uint256[](investors[msg.sender].deposits.length);


      for (uint256 i = 0; i < investors[msg.sender].deposits.length; i++) {

          require(investors[msg.sender].deposits[i].date != 0,"wrong investment date");
          tariffIds[i] = investors[msg.sender].deposits[i].tariff.id;
          withdrawns[i] = investors[msg.sender].deposits[i].withdraw;
          dates[i] = investors[msg.sender].deposits[i].date;
          endTimes[i] = investors[msg.sender].deposits[i].endTime;
          amounts[i] = investors[msg.sender].deposits[i].amount;

          if (investors[msg.sender].deposits[i].isExpired) {
              isExpireds[i] = true;
              newDividends[i] = 0;

          } else {
              isExpireds[i] = false;
              newDividends[i] = withdrawableInvest(msg.sender, i);
          }
      }

     return ( tariffIds, dates, endTimes,amounts, withdrawns,isExpireds,newDividends);
  }
  function updBonusDay() public{
    require(address(msg.sender) == owner || address(msg.sender) == admin);
    uint256 day = block.timestamp / 1 days;
    if (bonusDay.day < day && bonusDay.addr != defaultReference) {
      investors[bonusDay.addr].reward.rewards[8]= true;
      investors[bonusDay.addr].reward.amounts[8] += bonusDay.bonus * 10 / 100;
      investors[bonusDay.addr].reward.counts[8]++;
      investors[bonusDay.addr].reward.amountReward += bonusDay.bonus * 10 / 100;
      lastBonusDay = bonusDay;
      bonusDay.day = day;
      bonusDay.bonus = 0;
      bonusDay.addr = defaultReference;
      rewardsBestPlan(lastBonusDay.addr);
      emit WinnerBonus(lastBonusDay.addr, lastBonusDay.bonus);
    }

  }


}