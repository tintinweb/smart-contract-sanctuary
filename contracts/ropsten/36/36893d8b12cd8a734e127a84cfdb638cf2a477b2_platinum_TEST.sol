pragma solidity ^0.4.24;

/**

We are Testing TESTING

 */

contract platinum_TEST {
    using SafeMath for uint256;
    
    mapping (address => uint256) public investedETH;
    mapping (address => uint256) public withdrawnETH;
    mapping (address => uint256) public lastInvest;
    mapping (address => uint256) public affiliateCommision;
    
    /** Creator */
    address admin = 0xBa21d01125D6932ce8ABf3625977899Fd2C7fa30;    // testing A1
     /** Future  */
    address promo1 = 0xEDa159d4AD09bEdeB9fDE7124E0F5304c30F7790; // testing A2
    /** Community Returns */
    address securityFund = 0x6a5D9648381b90AF0e6881c26739efA4379c19B2; //testing A3
    
    //  0.225% per hour
    uint public dailyStartPercent = 225;    //  5.4%
    uint public dailyLowPersent = 325;      //  7.8%
    uint public dailyMiddlePersent = 375;   //  9.0%
    uint public dailyHighPersent = 425;     //  10.2%

    uint public stepLow = 1000 ether;
    uint public stepMiddle = 3000 ether;
    uint public stepHigh = 5000 ether;
    
    function persentRate() public view returns(uint) {
        uint balance = address(this).balance;
        
        if (balance < stepLow) {
            return dailyStartPercent;
        }
        if (balance >= stepLow && balance < stepMiddle) {
            return dailyLowPersent;
        }
        if (balance >= stepMiddle && balance < stepHigh) {
            return dailyMiddlePersent;
        }
        if (balance >= stepHigh) {
            return dailyHighPersent;
        }
    }
    
    function investETH(address referral) public payable {
        //  TODO: add messages to all require
        require(msg.value >= 0.05 ether, "ERROR: minimum investment == 0.05 ether");
        
        if(getProfit(msg.sender) > 0){
            uint256 profit = getProfit(msg.sender);
            lastInvest[msg.sender] = now;
            msg.sender.transfer(profit);
        }
        
        uint256 amount = msg.value;
        //  TODO: update in all places
        uint256 commision = amount.div(20); //affiliate commission 100/20 is 5% 
        if(referral != msg.sender && referral != address(0)){
            // affiliateCommision[referral] = SafeMath.add(affiliateCommision[referral], commision);
            affiliateCommision[referral] = affiliateCommision[referral].add(commision);
        }
        
        admin.transfer(msg.value.div(100).mul(5));
        promo1.transfer(msg.value.div(100).mul(5));
        securityFund.transfer(msg.value.div(100).mul(2));
        
        investedETH[msg.sender] = investedETH[msg.sender].add(amount);
        withdrawnETH[msg.sender] = 0;
        lastInvest[msg.sender] = now;
    }
    
    function withdraw() public{
        require(lastInvest[msg.sender] > 0, "ERROR: no investments");
        
        uint256 payoutAmount = getProfit(msg.sender);
        
        require(payoutAmount > 0.01 ether, "ERROR: minimum payout not reached");
        
        if(withdrawnETH[msg.sender].add(payoutAmount) <= investedETH[msg.sender].mul(3)) {
            withdrawnETH[msg.sender] = withdrawnETH[msg.sender].add(payoutAmount);
            msg.sender.transfer(payoutAmount);
        } else {
            uint256 payout = investedETH[msg.sender].mul(3);
            investedETH[msg.sender] = 0;
            withdrawnETH[msg.sender] = 0;
            msg.sender.transfer(payout);
        }
    }
    
    //  suggest to remove and use getProfit(msg.sender) directly from JS
    function getProfitFromSender() public view returns(uint256){
        return getProfit(msg.sender);
    }

    function getProfit(address customer) public view returns(uint256){
        uint256 hourDifference = now.sub(lastInvest[customer]).div(60);   // TODO: 3600
        uint256 rate = persentRate();
        uint256 calculatedPercent = hourDifference.mul(rate);
        return investedETH[customer].div(100000).mul(calculatedPercent);
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
    
    //  suggest to remove and use investedETH[msg.sender] directly from JS
    function getInvested() public view returns(uint256){
        return investedETH[msg.sender];
    }
    
    //  suggest to remove and use web3 directly from JS
    function getBalance() public view returns(uint256){
        return address(this).balance;
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