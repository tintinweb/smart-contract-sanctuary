pragma solidity ^0.4.18;

contract ExodusStaking{
    
    mapping (address => uint256) public investedETH;
    mapping (address => uint256) public lastInvest;
    
    mapping (address => uint256) public affiliateCommision;
    
    // Card holders  
    address promoter = 0xfd281400db3C0487478dD1f198b2B7e49E73e6D3;
    address promoter1 = 0xfd281400db3C0487478dD1f198b2B7e49E73e6D3;
    
    function investETH(address referral) public payable {
        
        require(msg.value >= 0.1 ether);
        
        if(getProfit(msg.sender) > 0){
            uint256 profit = getProfit(msg.sender);
            lastInvest[msg.sender] = now;
            msg.sender.transfer(profit);
        }
        
        uint256 amount = msg.value;
        uint256 commision = SafeMath.div(amount, 20);
        if(referral != msg.sender && referral != 0x1 && referral != promoter && referral != promoter1){
            affiliateCommision[referral] = SafeMath.add(affiliateCommision[referral], commision);
        }
        
        affiliateCommision[promoter] = SafeMath.add(affiliateCommision[promoter], commision);
        affiliateCommision[promoter1] = SafeMath.add(affiliateCommision[promoter1], commision);
        
        investedETH[msg.sender] = SafeMath.add(investedETH[msg.sender], amount);
        lastInvest[msg.sender] = now;
    }
    
    function divestETH() public {
        uint256 profit = getProfit(msg.sender);
        lastInvest[msg.sender] = now;
        
        //20% fee on taking capital out
        uint256 capital = investedETH[msg.sender];
        uint256 fee = SafeMath.div(capital, 5);
        capital = SafeMath.sub(capital, fee);
        
        uint256 total = SafeMath.add(capital, profit);
        require(total > 0);
        investedETH[msg.sender] = 0;
        msg.sender.transfer(total);
    }
    
    function withdraw() public{
        uint256 profit = getProfit(msg.sender);
        require(profit > 0);
        lastInvest[msg.sender] = now;
        msg.sender.transfer(profit);
    }
    
    function getProfitFromSender() public view returns(uint256){
        return getProfit(msg.sender);
    }

    function getProfit(address customer) public view returns(uint256){
        uint256 secondsPassed = SafeMath.sub(now, lastInvest[customer]);
        uint256 profit = SafeMath.div(SafeMath.mul(secondsPassed, investedETH[customer]), 8640000);
        uint256 bonus = getBonus();
        if(bonus == 0){
            return profit;
        }
        return SafeMath.add(profit, SafeMath.div(SafeMath.mul(profit, bonus), 100));
    }
    
    function getBonus() public view returns(uint256){
        uint256 invested = getInvested();
        if(invested >= 0.1 ether && 1 ether >= invested){
            return 20;
        }else if(invested >= 1.01 ether && 2 ether >= invested){
            return 30;
        }else if(invested >= 2.01 ether && 3 ether >= invested){
            return 50;
        }else if(invested >= 3.01 ether && 4 ether >= invested){
            return 75;
        }else if(invested >= 5.01 ether){
            return 90;
        }
    }
    
    function reinvestProfit() public {
        uint256 profit = getProfit(msg.sender);
        require(profit > 0);
        lastInvest[msg.sender] = now;
        investedETH[msg.sender] = SafeMath.add(investedETH[msg.sender], profit);
    }
    
    function getAffiliateCommision() public view returns(uint256){
        return affiliateCommision[msg.sender];
    }
    
    function withdrawAffiliateCommision() public {
        require(affiliateCommision[msg.sender] > 0);
        uint256 commision = affiliateCommision[msg.sender];
        affiliateCommision[msg.sender] = 0;
        msg.sender.transfer(commision);
    }
    
    function getInvested() public view returns(uint256){
        return investedETH[msg.sender];
    }
    
    function getBalance() public view returns(uint256){
        return this.balance;
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
    
    function max(uint256 a, uint256 b) private pure returns (uint256) {
        return a > b ? a : b;
    }
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}