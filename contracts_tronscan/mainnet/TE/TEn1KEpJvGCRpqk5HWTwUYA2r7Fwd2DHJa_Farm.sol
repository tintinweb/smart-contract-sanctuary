//SourceUnit: Farm.sol

pragma solidity ^0.4.25;

contract Farm {
  address support = msg.sender;
  uint public stage;
  uint public totalInvestors;
  
  // records registrations
  mapping (address => bool) public registered;
  // records referrers
  mapping (address => address) public referrers;
  // records referrals
  mapping (address => address[]) public referrals;
  // records goal by stage
  mapping (uint => uint) public goal;
  // records invested by stage
  mapping (uint => mapping (address => uint)) public invested;
  // records collected
  mapping (uint => uint) public collected;
  // records withdrawn by stage
  mapping (uint => mapping (address => uint)) public withdrawn;
  
  event Registered(address user);
  
  constructor() {
    goal[0] = 1000 * 1000000;
  }
  
  function _register(address referrerAddress) internal {
    if (!registered[msg.sender]) {   
      if (registered[referrerAddress] && referrerAddress != msg.sender) {
        referrers[msg.sender] = referrerAddress;
        referrals[referrerAddress].push(msg.sender);
      }

      totalInvestors++;
      registered[msg.sender] = true;

      emit Registered(msg.sender);
    }
  }
  
  function invest(address referrerAddress) external payable {
    require(msg.value >= 50000000);
    require(msg.value <= goal[stage]);
    
    _register(referrerAddress);
    
    uint fee = msg.value / 50;
    uint rest = msg.value - fee * 2;
    
    if (referrers[msg.sender] != 0x0) {
        referrers[msg.sender].transfer(fee);
        support.transfer(fee);
    } else {
        support.transfer(fee * 2);
    }
    
    uint needToFinishStage = goal[stage] - collected[stage];
    if (rest >= needToFinishStage) {
      uint diff = rest - needToFinishStage;
      invested[stage][msg.sender] += needToFinishStage;
      collected[stage] = goal[stage];
      
      if (stage == 0) {
        support.transfer(needToFinishStage);
      }
      
      stage++;
      goal[stage] = goal[stage - 1] * 6 / 5 / 1000000 * 1000000;
      invested[stage][msg.sender] += diff;
      collected[stage] += diff;
    } else {
      invested[stage][msg.sender] += rest;
      collected[stage] += rest;
      
      if (stage == 0) {
        support.transfer(rest);
      }
    }
  }
  
  function profit(uint stage, address user) public view returns (uint) {
    return stage == 0 ? 0 : invested[stage - 1][user] * collected[stage] / goal[stage - 1] - withdrawn[stage][user];
  }
  
  function withdraw(uint stage) external {
    uint amount = profit(stage, msg.sender);
    withdrawn[stage][msg.sender] += amount;
    msg.sender.transfer(amount);
  }
}