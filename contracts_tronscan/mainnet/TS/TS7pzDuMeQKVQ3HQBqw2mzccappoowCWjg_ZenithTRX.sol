//SourceUnit: ZenithTRX.sol

/*! ZenithTRX.sol | SPDX-License-Identifier: MIT License */

pragma solidity 0.5.8;

/**
* 
*                                                         
*                                                        
* ZENITHTRX THE MOST SAFE AND STILL ATRACTIVE SMARTCONTRACT EVER
* 
* Crowdfunding And Investment Program: 250% ROI in 50-250 days. 
* 10% Referral Rewards 5 Levels
* 1% to 5% daily RIO
* 
* zenithtrx 
* https://zenithtrx.com
* 
* 
**/
contract ZenithTRX  {
  using SafeMath for uint;
  
  // 25% of all earning is reinvested. referral earning is reinvested
  struct Investor {
    bool registered;
    address referer;
    mapping(uint => uint) referrals;
    uint balanceRef;
    uint totalRef;
    uint topRefBonus;
    Deposit[] deposits;

    uint reinvestableBalance;
    uint withdrawableBalance;
    uint withdrawn;
    uint paidAt;
  }

  struct Deposit {
    uint at;
    uint amount;
    uint profit;
  }
  
  uint constant multiplier = 1 trx;
  uint constant MIN_DEPOSIT = 100 * multiplier;
  uint constant ADAY = 28800;
  uint constant START_AT = 26635483;

  address payable public Dev;
  address payable internal DevAndMarketing;

  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalWithdrawn;
  mapping (address => Investor) public investors;

  uint8[] public poolBonuses;                    
  uint40 public poolLastDraw = uint40(block.timestamp);
  uint256 public poolCycle;
  mapping(uint256 => mapping(address => uint256)) public poolUsersRefsDepositsSum;
  mapping(uint8 => address) public poolTop;

  mapping(uint => address payable) internal devAndMarketing;
  mapping(uint => uint) internal units;

  event DepositAt(address indexed user, uint amount, uint indexed date);
  event Withdraw(address indexed user, uint amount);
  event TopRefPayout(address indexed user, uint amount);
  
  modifier onlyCreator() {
		require(msg.sender == Dev, 'You are not the creator');
		_;
	}

  constructor(uint stakeHolders) public {
    Dev = msg.sender;

    refRewards.push(50);
    refRewards.push(30);
    refRewards.push(10);
    refRewards.push(10);

    poolBonuses.push(7);
    poolBonuses.push(5);
    poolBonuses.push(3);
    
    investors[msg.sender].registered = true;
    investors[msg.sender].paidAt = block.number;

    for (uint i = 1; i <= stakeHolders; i++){
      devAndMarketing[i] = Dev;
      units[i] = 1;
    }
  }

  function() external payable {
    revert();
  }

  function setDev(address payable _Dev) public onlyCreator() {
      Dev = _Dev;
  }

  function setAdminUint(uint index, uint unit) public onlyCreator() {
    require(units[index] == 0, "cannot set twices");
    units[index] = unit;
  }

  function setDevAndMarketingAccount(uint index, address payable _address) public {
    require(index >= 1 && index <= 5, "index out of range");
    require(devAndMarketing[index] == msg.sender, "You are not the stakeholder");
    devAndMarketing[index] = _address;
  }


  function getBalance() public view returns (uint) {
      return address(this).balance;
  }

  function getRoi() public view returns(uint roi) {
    uint currentBalance = getBalance();
    if (currentBalance < 5000000 * multiplier) {
      return 10; // min 1%
    }

    if (currentBalance < 50000000 * multiplier) {
      uint excess = currentBalance - 5000000 * multiplier;
      return 10 + ((excess - excess%5000000*multiplier) / (5000000 * multiplier));
    }

    if (currentBalance < 160000000 * multiplier) {
      uint excess = currentBalance - 50000000 * multiplier;
      return 20 + ((excess - excess%10000000*multiplier) / (10000000 * multiplier));
    }

    if (currentBalance < 380000000 * multiplier) {
      uint excess = currentBalance - 160000000 * multiplier;
      return 30 + ((excess - excess%20000000*multiplier) / (20000000 * multiplier));
    }

    if (currentBalance < 780000000 * multiplier) {
      uint excess = currentBalance - 380000000 * multiplier;
      return 40 + ((excess - excess%40000000*multiplier) / (40000000 * multiplier));
    }

    return 50; // max 5%
  }

  function getInvestmentTerm() public view returns(uint end){
    uint roi = getRoi();
    uint _days = 2500/roi;
    return _days * ADAY;
  }

  function register(address referer) internal {
    if (investors[msg.sender].registered) return;
    totalInvestors++;
    investors[msg.sender].registered = true;
    investors[msg.sender].paidAt = block.number;
      
    if (investors[referer].registered && referer != msg.sender) {
      investors[msg.sender].referer = referer;
        
      address rec = referer;
      for (uint i = 0; i < refRewards.length; i++) {
        if (!investors[rec].registered) {
          break;
        }
        investors[rec].referrals[i]++;
          
        rec = investors[rec].referer;
      }
    }
  }
  
  function rewardReferers(uint amount, address referer) internal {
    address rec = referer;
    
    for (uint i = 0; i < refRewards.length; i++) {
      if(rec == address(0)) break;

      if (!(investors[rec].registered)) {
        break;
      }

      uint a = amount * refRewards[i] / 1000;
      investors[rec].balanceRef += a;
      
      rec = investors[rec].referer;
    }
  }
  
  function deposit(address referer) external payable {
    require(block.number >= START_AT);
    
    if(!investors[msg.sender].registered) {
      register(referer);
    }
    
    investors[msg.sender].deposits.push(Deposit({at:block.number, amount: msg.value, profit: 0}));
    totalInvested = totalInvested.add(msg.value);

    rewardReferers(msg.value, investors[msg.sender].referer);
    updateTopSponsor(msg.sender, msg.value);
    if(poolLastDraw + 14 days < block.timestamp) {
        payTopSponsors();
    }
    
    sendDevAndMarketingFund(msg.value.mul(10).div(100));
    
    emit DepositAt(msg.sender, msg.value, block.timestamp);
  }

  function reinvest() public {
    collectProfit();
    uint amount = investors[msg.sender].withdrawableBalance.add(investors[msg.sender].balanceRef).add(investors[msg.sender].reinvestableBalance);
    require(amount > 0 && amount > MIN_DEPOSIT);
    investors[msg.sender].withdrawableBalance = 0;
    investors[msg.sender].totalRef = investors[msg.sender].totalRef.add(investors[msg.sender].balanceRef);
    investors[msg.sender].balanceRef = 0;
    investors[msg.sender].reinvestableBalance = 0;
    investors[msg.sender].deposits.push(Deposit({at:block.number, amount: amount, profit: 0}));
  }

  function updateTopSponsor(address _addr, uint256 _amount) private {
    address upline = investors[_addr].referer;
    if(upline == address(0)) return;
        
    poolUsersRefsDepositsSum[poolCycle][upline] += _amount;

    for(uint8 i = 0; i < poolBonuses.length; i++) {
      if(poolTop[i] == upline) break;

      if(poolTop[i] == address(0)) {
        poolTop[i] = upline;
        break;
      }
      if(poolUsersRefsDepositsSum[poolCycle][upline] > poolUsersRefsDepositsSum[poolCycle][poolTop[i]]) {
        for(uint8 j = i + 1; j < poolBonuses.length; j++) {
          if(poolTop[j] == upline) {
            for(uint8 k = j; k <= poolBonuses.length; k++) {
              poolTop[k] = poolTop[k + 1];
            }
            break;
          }
        }
        
        for(uint8 j = uint8(poolBonuses.length - 1); j > i; j--) {
          poolTop[j] = poolTop[j - 1];
        }
        
        poolTop[i] = upline;
        break;
      }
    }
  }

  function payTopSponsors() private {
    poolLastDraw = uint40(block.timestamp);

    for(uint8 i = 0; i < poolBonuses.length; i++) {
      if(poolTop[i] == address(0)) break;

      uint256 win = poolUsersRefsDepositsSum[poolCycle][poolTop[i]] * poolBonuses[i] / 100;

      investors[poolTop[i]].topRefBonus += win;
      emit TopRefPayout(poolTop[i], win);
    }
        
    poolCycle++;
    for(uint8 i = 0; i < poolBonuses.length; i++) {
      poolTop[i] = address(0);
    }
  }

  function poolTopInfo(uint8 _index) public view returns(address user, uint amount, uint nextDraw) {
    user = poolTop[_index];
    amount = poolUsersRefsDepositsSum[poolCycle][user];
    nextDraw = poolLastDraw + 14 days;
  }

  function validateDeposit(uint _amount) internal pure returns(bool) {
    if(_amount < MIN_DEPOSIT) {
      return false;
    }
    return true;
  }

  function investInfo(address _user) public view returns(uint total, uint active) {
    Investor storage investor = investors[_user];
    for(uint i = 0; i < investor.deposits.length; i++) {
      Deposit storage dep = investor.deposits[i];
      total = total.add(dep.amount);
      if (dep.profit >= dep.amount.mul(250).div(100)) {
        continue;
      }
      active = active.add(dep.amount);
    }
  }
  
  function withdrawable(address user) public view returns (uint amount) {
    Investor storage investor = investors[user];
    uint investTotal;
    for(uint i = 0; i < investor.deposits.length; i++) {
      Deposit storage dep = investor.deposits[i];
      investTotal = investTotal.add(dep.amount);
      if(dep.profit >= dep.amount.mul(250).div(100)) {
        continue;
      }
      uint start = investor.paidAt;
      if(dep.at > start) start = dep.at;
      uint profit = dep.amount * ((block.number.sub(start)) / ADAY) * getRoi() / 1000;
      uint profit_max = dep.amount.mul(250).div(100);
      if(dep.profit.add(profit) >= profit_max) {
        profit = profit_max.sub(dep.profit);
      }
      amount = amount.add(profit);
    }

    uint payout_max = investTotal.mul(250).div(100); 
    if (investor.withdrawn.add(amount) >= payout_max) {
      amount = payout_max.sub(investor.withdrawn);
    }
  }

  function referrals(address user) public view returns(uint,uint,uint,uint) {
    Investor storage investor = investors[user];
    return (
      investor.referrals[0],
      investor.referrals[1],
      investor.referrals[2],
      investor.referrals[3]
    );
  }
  
  function collectProfit() internal {
    Investor storage investor = investors[msg.sender];
    uint investTotal;
    uint amount;
    for(uint i = 0; i < investor.deposits.length; i++) {
      Deposit storage dep = investor.deposits[i];
      investTotal = investTotal.add(dep.amount);
      if(dep.profit >= dep.amount.mul(250).div(100)) {
        continue;
      }

      uint start = investor.paidAt;
      if(dep.at > start) start = dep.at;
      uint profit = dep.amount * ((block.number.sub(start)) / ADAY) * getRoi() / 1000;
      uint profit_max = dep.amount.mul(250).div(100);
      if(dep.profit.add(profit) >= profit_max) {
        profit = profit_max.sub(dep.profit);
      }
      dep.profit = dep.profit.add(profit);
      amount = amount.add(profit);
    }

    uint payout_max = investTotal.mul(250).div(100); 
    if (investor.withdrawn.add(amount) >= payout_max) {
      amount = payout_max.sub(investor.withdrawn);
    }
    
    investor.withdrawn = investor.withdrawn.add(amount);
    investor.paidAt = block.number;
    
    if (investor.topRefBonus > 0) {
      amount = investor.topRefBonus;
      investor.topRefBonus = 0;
    }
    investor.withdrawableBalance = investor.withdrawableBalance.add(amount.mul(75).div(100));
    uint reinvestAmount = amount.mul(25).div(100);
    investor.reinvestableBalance = investor.reinvestableBalance.add(reinvestAmount);
  }
  
  function withdraw() external {
    collectProfit();
    uint amount = investors[msg.sender].withdrawableBalance;
    if (amount > address(this).balance) {
      amount = address(this).balance;
    }
    require(amount > 0, "Limit reached");
    investors[msg.sender].withdrawableBalance = 0;
    totalWithdrawn = totalWithdrawn.add(amount);
    if (msg.sender.send(amount)) {
      emit Withdraw(msg.sender, amount);
    }
  }

  function sendDevAndMarketingFund(uint amount) public {
    uint totalUnits;
    for(uint i = 1; i <= 5; i++) {
      totalUnits = totalUnits + units[i];
    }
    for(uint i = 1; i <= 5; i++) {
      devAndMarketing[i].transfer(units[i] * amount/totalUnits);
    }
  }
}

library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        require(b > 0);
        uint c = a / b;

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a);
        uint c = a - b;

        return c;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a);

        return c;
    }

}