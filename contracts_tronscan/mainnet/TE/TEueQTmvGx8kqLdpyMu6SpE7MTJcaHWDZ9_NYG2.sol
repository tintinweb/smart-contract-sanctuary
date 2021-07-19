//SourceUnit: CONTRACT.sol

pragma solidity ^0.4.25;

contract NYG2 {
  struct Investor {
    bool registered;
    address referrer;
    uint staked;
    uint stakedAt;
    uint stakeProfit;
  }
  
  uint public TOKEN_ID = 1003662;
  uint DAY = 1 days;
  uint START_AT = 1610352000;
  
  uint public totalStaked;
  address public support = msg.sender;
  uint[] public refRewards;
  uint public totalInvestors;
  uint public totalInvested;
  mapping (address => Investor) public investors;
  mapping (address => mapping (uint => uint)) public referrals;
  mapping (address => mapping (uint => uint)) public refProfits;
  
  modifier playtime() {
    require(block.timestamp >= START_AT, 'not started');
    _;
  }
  
  function register(address referrer) internal {
    if (!investors[msg.sender].registered) {
      investors[msg.sender].registered = true;
      totalInvestors++;
      
      if (investors[referrer].registered && referrer != msg.sender) {
        investors[msg.sender].referrer = referrer;
        
        address rec = referrer;
        for (uint i = 0; i < refRewards.length; i++) {
          if (!investors[rec].registered) {
            break;
          }
          
          referrals[rec][i]++;
          
          rec = investors[rec].referrer;
        }
      }
    }
  }
  
  function rewardReferers(uint amount, address referrer) internal {
    address rec = referrer;
    
    for (uint i = 0; i < refRewards.length; i++) {
      if (!investors[rec].registered) {
        break;
      }
      
      uint a = amount * refRewards[i] / 100;
      rec.transfer(a);
      refProfits[rec][i] += a;
      
      rec = investors[rec].referrer;
    }
  }
  
  constructor() public {
    refRewards.push(4);
    refRewards.push(3);
    refRewards.push(2);
    refRewards.push(1);
  }
  
  function getBuyTokenPrice() public view returns (uint) {
    return 10000 + (block.timestamp <= START_AT ? 0 : 10000 * (block.timestamp - START_AT) / DAY);
  }
  
  function getSellTokenPrice() public view returns (uint) {
    return getBuyTokenPrice() * 4 / 5;
  }
  
  function getProfitFromStaked(address user) public view returns (uint) {
    Investor storage investor = investors[user];
    
    if (investor.staked == 0 || block.timestamp <= START_AT) {
      return 0;
    }
    
    return totalInvested * (block.timestamp - investor.stakedAt) * investor.staked / 20 / (block.timestamp - START_AT) / totalStaked;
  }
  
  function saveProfitFromStaked() internal {
    Investor storage investor = investors[msg.sender];
    
    investor.stakeProfit += getProfitFromStaked(msg.sender);
    investor.stakedAt = block.timestamp < START_AT ? START_AT : block.timestamp;
  }
  
  function stake() external payable playtime {
    require(msg.tokenid == TOKEN_ID, 'wrong token id');
    require(msg.tokenvalue >= 10 trx, 'too low amount');
    
    Investor storage investor = investors[msg.sender];
    saveProfitFromStaked();
    
    investor.staked += msg.tokenvalue;
    totalStaked += msg.tokenvalue;
  }
  
  function unstake() external playtime {
    Investor storage investor = investors[msg.sender];
    saveProfitFromStaked();
    
    totalStaked -= investor.staked;
    msg.sender.transferToken(investor.staked, TOKEN_ID);
    investor.staked = 0;
  }
  
  function claim() external playtime {
    Investor storage investor = investors[msg.sender];
    saveProfitFromStaked();
    
    msg.sender.transfer(investor.stakeProfit);
    investor.stakeProfit = 0;
  }
  
  function buy(address referrer) external payable playtime {
    require(msg.value >= 100 trx, 'too low amount');
    
    register(referrer);
    
    Investor storage investor = investors[msg.sender];
    
    rewardReferers(msg.value, investor.referrer);
    totalInvested += msg.value;
    msg.sender.transferToken(msg.value * 1000000 / getBuyTokenPrice(), TOKEN_ID);
    support.transfer(msg.value / 10);
  }
  
  function sell() external payable playtime {
    require(msg.tokenid == TOKEN_ID, 'wrong token id');
    require(msg.tokenvalue >= 10 trx, 'too low amount');
    msg.sender.transfer(msg.tokenvalue * getSellTokenPrice() / 1000000);
  }
}