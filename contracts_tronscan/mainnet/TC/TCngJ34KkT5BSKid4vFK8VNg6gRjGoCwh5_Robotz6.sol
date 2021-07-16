//SourceUnit: EpicVillage.sol

pragma solidity ^0.4.25;

contract Robotz6 {
  address support = msg.sender;
  
  uint public PAUSE = 86400;
  
  uint public PRICE_1 = 50 * 1000000;
  uint public PRICE_2 = 100 * 1000000;
  uint public PRICE_3 = 200 * 1000000;
  uint public PRICE_4 = 500 * 1000000;
  uint public PRICE_5 = 1000 * 1000000;
  uint public PRICE_6 = 5000 * 1000000;
  uint public PRICE_7 = 10000 * 1000000;
  uint public PRICE_8 = 100000 * 1000000;
  uint public PRICE_9 = 200000 * 1000000;
  
  uint public PERCENT_1 = 1000;
  uint public PERCENT_2 = 1010;
  uint public PERCENT_3 = 1020;
  uint public PERCENT_4 = 1030;
  uint public PERCENT_5 = 1040;
  uint public PERCENT_6 = 1050;
  uint public PERCENT_7 = 1060;
  uint public PERCENT_8 = 1070;
  uint public PERCENT_9 = 1080;
  
  uint REF_TIER_1 = 4;
  uint REF_TIER_2 = 3;
  uint REF_TIER_3 = 2;
  uint REF_TIER_4 = 1;
  
  uint public totalInvestors;
  uint public stage;
  
  // records registrations
  mapping (address => bool) public registered;
  // records amounts invested
  mapping (uint => mapping (address => mapping (uint => uint))) public invested;
  // records blocks at which investments were made
  mapping (uint => mapping (address => uint)) public atBlock;
  // records referrers
  mapping (address => address) public referrers;
  // records referrals
  mapping (address => uint) public referrals_tier1;
  mapping (address => uint) public referrals_tier2;
  mapping (address => uint) public referrals_tier3;
  mapping (address => uint) public referrals_tier4;
  // records referral rewards
  mapping (address => uint) public referral_tier1;
  mapping (address => uint) public referral_tier2;
  mapping (address => uint) public referral_tier3;
  mapping (address => uint) public referral_tier4;
  // records objects
  mapping (uint => mapping (address => mapping (uint => uint))) public objects;
  // investor balances
  mapping (uint => mapping (address => uint)) public investorBalances;
  // withdrawal balances
  mapping (uint => mapping (address => uint)) public withdrawalBalances;
  // deposited by user total (all stages)
  mapping (address => uint) public depositedByUser;
  // total invested
  mapping (uint => uint) public totalInvested;
  // total deposited
  mapping (uint => uint) public totalDeposited;
  // total withdrawn
  mapping (uint => uint) public totalWithdrawn;
  // round starts
  mapping (uint => uint) public starts;
  
  constructor() {
    starts[0] = block.number;
  }

  function _register(address referrerAddress) internal {
    if (!registered[msg.sender]) {   
      if (registered[referrerAddress] && referrerAddress != msg.sender) {
        referrers[msg.sender] = referrerAddress;
        referrals_tier1[referrerAddress]++;
        
        address referer = referrers[referrerAddress];
        if (referer != 0x0) {
          referrals_tier2[referer]++;
          
          referer = referrers[referer];
          if (referer != 0x0) {
            referrals_tier3[referer]++;
          }
          
          referer = referrers[referer];
          if (referer != 0x0) {
            referrals_tier4[referer]++;
          }
        }
      }

      totalInvestors++;
      registered[msg.sender] = true;
    }
  }
  
  function deposit(address referrerAddress) external payable {
    require(block.number >= starts[stage] + PAUSE);
    require(msg.value >= 50000000);
    
    _register(referrerAddress);
    
    investorBalances[stage][msg.sender] += msg.value;
    
    support.transfer(msg.value / 10);
    
    address referer = referrers[msg.sender];
    if (referer != 0x0) {
      uint reward = msg.value * REF_TIER_1 / 100;
      referer.transfer(reward);
      referral_tier1[referer] += reward;
      
      referer = referrers[referer];
      if (referer != 0x0) {
        reward = msg.value * REF_TIER_2 / 100;
        referer.transfer(reward);
        referral_tier2[referer] += reward;
        
        referer = referrers[referer];
        if (referer != 0x0) {
          reward = msg.value * REF_TIER_3 / 100;
          referer.transfer(reward);
          referral_tier3[referer] += reward;
          
          referer = referrers[referer];
          if (referer != 0x0) {
            reward = msg.value * REF_TIER_4 / 100;
            referer.transfer(reward);
            referral_tier4[referer] += reward;
          }
        }
      }
    }
    
    depositedByUser[msg.sender] += msg.value;
    totalDeposited[stage] += msg.value;
  }
  
  function withdraw(uint amount) external {
    getAllProfit();
    
    require(withdrawalBalances[stage][msg.sender] >= amount);
    
    uint amountToTransfer = amount;
    uint max = address(this).balance;
    
    bool nextStage = amountToTransfer > max;
    
    if (nextStage) {
      amountToTransfer = max;
    }
    
    withdrawalBalances[stage][msg.sender] -= amountToTransfer;
    msg.sender.transfer(amountToTransfer);
    
    totalWithdrawn[stage] += amountToTransfer;
    
    if (nextStage) {
      stage++;
      starts[stage] = block.number;
    }
  }

  function buy(uint amount) external {
    require(amount == PRICE_1 || amount == PRICE_2 || amount == PRICE_3 || amount == PRICE_4 || amount == PRICE_5 || amount == PRICE_6 || amount == PRICE_7 || amount == PRICE_8 || amount == PRICE_9);
    
    getAllProfit();
    
    require(investorBalances[stage][msg.sender] + withdrawalBalances[stage][msg.sender] >= amount);
    if (investorBalances[stage][msg.sender] >= amount) {
      investorBalances[stage][msg.sender] -= amount;
    } else {
      withdrawalBalances[stage][msg.sender] -= amount - investorBalances[stage][msg.sender];
      investorBalances[stage][msg.sender] = 0;
    }
    
    objects[stage][msg.sender][amount]++;
    
    invested[stage][msg.sender][amount] += amount;
    totalInvested[stage] += amount;
  }

  function getProfitFrom(address user, uint price, uint percentage, uint stage) internal view returns (uint) {
    return invested[stage][user][price] * percentage / 1000 * (block.number - atBlock[stage][user]) / 864000;
  }

  function getAllProfitAmount(address user, uint stage) public view returns (uint) {
    return
      getProfitFrom(user, PRICE_1, PERCENT_1, stage) +
      getProfitFrom(user, PRICE_2, PERCENT_2, stage) +
      getProfitFrom(user, PRICE_3, PERCENT_3, stage) +
      getProfitFrom(user, PRICE_4, PERCENT_4, stage) +
      getProfitFrom(user, PRICE_5, PERCENT_5, stage) +
      getProfitFrom(user, PRICE_6, PERCENT_6, stage) +
      getProfitFrom(user, PRICE_7, PERCENT_7, stage) +
      getProfitFrom(user, PRICE_8, PERCENT_8, stage) +
      getProfitFrom(user, PRICE_9, PERCENT_9, stage);
  }

  function getAllProfit() internal {
    if (atBlock[stage][msg.sender] > 0) {
      uint amount = getAllProfitAmount(msg.sender, stage) / 2;
      investorBalances[stage][msg.sender] += amount;
      withdrawalBalances[stage][msg.sender] += amount;
    }

    atBlock[stage][msg.sender] = block.number;
  }
  
  function setPrices(uint p1, uint p2, uint p3, uint p4, uint p5, uint p6, uint p7, uint p8, uint p9) external {
    require(msg.sender == support);
    require(block.number < starts[stage] + PAUSE);
    
    PRICE_1 = p1;
    PRICE_2 = p2;
    PRICE_3 = p3;
    PRICE_4 = p4;
    PRICE_5 = p5;
    PRICE_6 = p6;
    PRICE_7 = p7;
    PRICE_8 = p8;
    PRICE_9 = p9;
  }
  
  function setPercents(uint p1, uint p2, uint p3, uint p4, uint p5, uint p6, uint p7, uint p8, uint p9) external {
    require(msg.sender == support);
    require(block.number < starts[stage] + PAUSE);
    
    PERCENT_1 = p1;
    PERCENT_2 = p2;
    PERCENT_3 = p3;
    PERCENT_4 = p4;
    PERCENT_5 = p5;
    PERCENT_6 = p6;
    PERCENT_7 = p7;
    PERCENT_8 = p8;
    PERCENT_9 = p9;
  }
}