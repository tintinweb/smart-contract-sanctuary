pragma solidity ^0.4.25;

contract token {
    function transfer(address receiver, uint256 amount);
    function balanceOf(address _owner) constant returns (uint256 balance);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  
}

contract TokenCrowdsale {
    using SafeMath for uint256;
    
    address public beneficiary;
    uint256 public fundingGoal;
    uint256 public amountRaised;
    uint256 public preSaleStartdate;
    uint256 public preSaleDeadline;
    uint256 public mainSaleStartdate;
    uint256 public mainSaleDeadline;
    uint256 public price;
    uint256 public fundTransferred;
    token public tokenReward;
    mapping(address => uint256) public balanceOf;
    bool crowdsaleClosed = false;

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function TokenCrowdsale() {
        beneficiary = 0xC8fa3E17B6A8388A960Db3fd2a744cC214Bb8aE6;
        fundingGoal = 2100 ether;
        preSaleStartdate = 1538478772;
        preSaleDeadline = 1538565172;
        mainSaleStartdate = 1538651572;
        mainSaleDeadline = 1541329972;
        price = 0.0004166 ether;
        tokenReward = token(0xb9d4375e83b93D06Dd35242b8eD9B6E77A99bCa6);
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable {
        require(!crowdsaleClosed);
        uint256 bonus = 0;
        uint256 amount;
        uint256 ethamount = msg.value;
        balanceOf[msg.sender] = balanceOf[msg.sender].add(ethamount);
        amountRaised = amountRaised.add(ethamount);
        
        //add bounus for funders
        if(now >= preSaleStartdate && now <= preSaleDeadline ){
            amount =  ethamount.div(price);
            bonus = amount.div(8);
            amount = amount.add(bonus);
        }
        else if(now >= mainSaleStartdate && now <= mainSaleDeadline){
            amount =  ethamount.div(price);
        }
        
        amount = amount.mul(100000000);
        tokenReward.transfer(msg.sender, amount);
        beneficiary.send(ethamount);
        fundTransferred = fundTransferred.add(ethamount);
    }

    modifier afterDeadline() { if (now >= mainSaleDeadline) _; }

    /**
     *ends the campaign after deadline
     */
     
    function endCrowdsale() afterDeadline {
	   if(msg.sender == beneficiary){
         crowdsaleClosed = true;
	  }
    }
	
    function ChangeDates(uint256 _preSaleStartdate, uint256 _preSaleDeadline, uint256 _mainSaleStartdate, uint256 _mainSaleDeadline) {
        if(msg.sender == beneficiary){
              if(_preSaleStartdate != 0){
                   preSaleStartdate = _preSaleStartdate;
              }
              if(_preSaleDeadline != 0){
                   preSaleDeadline = _preSaleDeadline;
              }
              if(_mainSaleStartdate != 0){
                   mainSaleStartdate = _mainSaleStartdate;
              }
              if(_mainSaleDeadline != 0){
                   mainSaleDeadline = _mainSaleDeadline; 
              }
			  
			  if(crowdsaleClosed == true){
				 crowdsaleClosed = false;
			  }
        }
    }
    
    function getTokensBack() {
        uint256 remaining = tokenReward.balanceOf(this);
        if(msg.sender == beneficiary){
           tokenReward.transfer(beneficiary, remaining); 
        }
    }
}