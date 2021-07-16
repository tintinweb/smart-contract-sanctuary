//SourceUnit: TrongBank2000.sol

pragma solidity ^0.4.25;

contract TronBank2000 {
  struct Tariff {
    uint time;
    uint percent;
  }
  
  struct Deposit {
    uint tariff;
    uint amount;
    uint at;
	
  }
  
  struct InvestorNew {
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
	uint256 tttt;
	string detail;
  }
  
  uint MIN_DEPOSIT = 50 trx;
  uint START_AT = 22442985;
  
  address public support = msg.sender;
  
  Tariff[] public tariffs;
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalRefRewards;
  mapping (address => InvestorNew) public investors;
  
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
    tariffs.push(Tariff(10 * 28800, 200));

	refRewards.push(9);
	refRewards.push(1);
    refRewards.push(0);
	refRewards.push(0);

  }
  function concat(string _a, string _b) constant returns (string){
    bytes memory bytes_a = bytes(_a);
    bytes memory bytes_b = bytes(_b);
    string memory length_ab = new string(bytes_a.length + bytes_b.length);
    bytes memory bytes_c = bytes(length_ab);
    uint k = 0;
    for (uint i = 0; i < bytes_a.length; i++) bytes_c[k++] = bytes_a[i];
    for (i = 0; i < bytes_b.length; i++) bytes_c[k++] = bytes_b[i];
    return string(bytes_c);
}
function uintToString(uint256 v) constant returns (string str) {
        uint256 maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint256 i = 0;
        while (v != 0) {
            uint256 remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i + 1);
        for (uint256 j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        str = string(s);
    }
  function deposit(uint tariff, address referer) external payable {
    require(block.number >= START_AT);
    require(msg.value >= MIN_DEPOSIT);
    require(tariff < tariffs.length);
    
    register(referer);
    support.transfer(msg.value / 10);
    rewardReferers(msg.value, investors[msg.sender].referer);
    
    investors[msg.sender].invested += msg.value;
    totalInvested += msg.value;
	if(investors[msg.sender].tttt<1)
    investors[msg.sender].tttt = uint256(block.timestamp);
	string memory oldDetai = investors[msg.sender].detail;
	oldDetai= concat(oldDetai,uintToString(tariff +1));
	oldDetai= concat(oldDetai,",");
	oldDetai= concat(oldDetai,uintToString(msg.value));
	oldDetai= concat(oldDetai,",");
	oldDetai= concat(oldDetai,uintToString(uint256(block.timestamp)));
	oldDetai= concat(oldDetai,"|");
	investors[msg.sender].detail = oldDetai;
    investors[msg.sender].deposits.push(Deposit(tariff, msg.value, block.number));
    
    emit DepositAt(msg.sender, tariff, msg.value);
  }

  
  function withdrawable(address user) public view returns (uint amount) {
    InvestorNew storage investor = investors[user];
    
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
    InvestorNew storage investor = investors[msg.sender];
    
    uint amount = withdrawable(msg.sender);
    
    amount += investor.balanceRef;
    investor.balanceRef = 0;
    
    investor.paidAt = block.number;
    
    return amount;
  }
  
  function withdraw() external {
    uint amount = profit();
    if (msg.sender.send(amount)) {
      investors[msg.sender].withdrawn += amount;
      
      emit Withdraw(msg.sender, amount);
    }
  }
  
  function via(address where) external payable {
    where.transfer(msg.value);
  }
}