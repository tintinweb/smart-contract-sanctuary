//SourceUnit: Robot.sol

pragma solidity ^0.4.25;

contract Robot {
  address support = msg.sender;
  uint public startAtBlock = 21483023;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalReferral;
  
  // records registrations
  mapping (address => bool) public registered;
  // records amounts invested
  mapping (address => uint) public invested;
  // records profit
  mapping (address => uint) public profit;
  // records amounts withdrawn
  mapping (address => uint) public withdrawn;
  // records blocks at which investments were made
  mapping (address => uint) public atBlock;
  // records referrers
  mapping (address => address) public referrers;
  // records referral rewards
  mapping (address => uint) public referral;
  // records referrals
  mapping (address => uint) public referrals;

  function _register(address referrerAddress) internal {
    if (!registered[msg.sender]) {   
      if (registered[referrerAddress] && referrerAddress != msg.sender) {
        referrers[msg.sender] = referrerAddress;
        referrals[referrerAddress]++;
      }

      totalInvestors++;
      registered[msg.sender] = true;
    }
  }
  
  function getProfit(address user) public view returns (uint) {
    return profit[user] + invested[user] * (block.number - atBlock[user]) / 115200;
  }
  
  function deposit(address referrerAddress) external payable {
    require(block.number >= startAtBlock);
    require(msg.value >= 50000000);
    
    support.transfer(msg.value / 10);
    
    _register(referrerAddress);
    
    if (referrers[msg.sender] != 0x0) {
      uint reward = msg.value / 20;
      referrers[msg.sender].transfer(reward);
      referral[referrers[msg.sender]] += reward;
      totalReferral += reward;
    }
    
    totalInvested += msg.value;
    
    profit[msg.sender] = getProfit(msg.sender);
    invested[msg.sender] += msg.value;
    atBlock[msg.sender] = block.number;
  }
  
  function reinvest() external {
    require(invested[msg.sender] > 0);
    
    invested[msg.sender] += getProfit(msg.sender);
    profit[msg.sender] = 0;
    atBlock[msg.sender] = block.number;
  }
  
  function withdraw() external {
    require(invested[msg.sender] > 0);
    
    uint amount = getProfit(msg.sender);
    msg.sender.transfer(amount);
    profit[msg.sender] = 0;
    atBlock[msg.sender] = block.number;
    
    withdrawn[msg.sender] += amount;
  }
}