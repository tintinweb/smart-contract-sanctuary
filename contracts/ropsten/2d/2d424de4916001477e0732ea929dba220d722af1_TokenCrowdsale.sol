pragma solidity ^0.4.25;

contract token {
    function transfer(address receiver, uint256 amount) public;
    function balanceOf(address _owner) public constant returns (uint256 balance);
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

contract owned {
        address public owner;

        constructor() public {
            owner = msg.sender;
        }

        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }

        function transferOwnership(address newOwner) onlyOwner public {
            owner = newOwner;
        }
}

contract TokenCrowdsale is owned{
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
    bool returnFunds = false;
	
	event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);

    /**
     * Constrctor function
     *
     * Setup the owner
     */
    constructor() public {
        beneficiary = msg.sender;
        fundingGoal = 2100 ether;
        preSaleStartdate = now;
        preSaleDeadline = now + 10 days;
        mainSaleStartdate = now + 10 days;
        mainSaleDeadline = now + 20 days;
        price = 0.0004 ether;
        tokenReward = token(0xEd8a10acb47bB261Bd6907303e1DAbaB77f3094E);
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
        require(!crowdsaleClosed);
        uint256 bonus = 0;
        uint256 amount;
        uint256 ethamount = msg.value;
        balanceOf[msg.sender] = balanceOf[msg.sender].add(ethamount);
        amountRaised = amountRaised.add(ethamount);
        
        //add bounus for funders
        if(now >= preSaleStartdate && now <= preSaleStartdate + 15 minutes ){
            amount =  ethamount.div(price);
            bonus = amount * 40 / 100;
            amount = amount.add(bonus);
        }
        else if(now >= preSaleStartdate + 15 minutes && now <= preSaleStartdate + 20 minutes){
            amount =  ethamount.div(price);
            bonus = amount * 20/100;
            amount = amount.add(bonus);
        }
        else if(now >= preSaleStartdate + 20 minutes && now <= preSaleStartdate + 25 minutes){
            amount =  ethamount.div(price);
            bonus = amount * 15/100;
            amount = amount.add(bonus);
        }
        else if(now >= preSaleStartdate + 25 minutes && now <= preSaleStartdate + 30 minutes){
            amount =  ethamount.div(price);
            bonus = amount * 10/100;
            amount = amount.add(bonus);
        }
        
        amount = amount.mul(1000000000000000000);
        tokenReward.transfer(msg.sender, amount);
		emit FundTransfer(msg.sender, ethamount, true);
    }

    modifier afterDeadline() { if (now >= mainSaleDeadline) _; }

    /**
     *ends the campaign after deadline
     */
     
    function endCrowdsale() public afterDeadline  onlyOwner {
          crowdsaleClosed = true;
    }
    
    function EnableReturnFunds() public onlyOwner {
          returnFunds = true;
    }
    
    function DisableReturnFunds() public onlyOwner {
          returnFunds = false;
    }
	
	function ChangePrice(uint256 _price) public onlyOwner {
		  price = _price;	
	 }
	 
    function ChangePreSaleDates(uint256 _preSaleStartdate, uint256 _preSaleDeadline) onlyOwner public{
          if(_preSaleStartdate != 0){
               preSaleStartdate = _preSaleStartdate;
          }
          if(_preSaleDeadline != 0){
               preSaleDeadline = _preSaleDeadline;
          }
		  
		  if(crowdsaleClosed == true){
			 crowdsaleClosed = false;
		  }
    }
    
    function ChangeMainSaleDates(uint256 _mainSaleStartdate, uint256 _mainSaleDeadline) onlyOwner public{
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
    
    function getTokensBack() onlyOwner public{
        uint256 remaining = tokenReward.balanceOf(this);
        tokenReward.transfer(beneficiary, remaining);
    }
    
    function safeWithdrawal() public afterDeadline {
	   if (returnFunds) {
			uint amount = balanceOf[msg.sender];
			if (amount > 0) {
				if (msg.sender.send(amount)) {
				   emit FundTransfer(msg.sender, amount, false);
				   balanceOf[msg.sender] = 0;
				   fundTransferred = fundTransferred.add(amount);
				} 
			}
		}

		if (returnFunds == false && beneficiary == msg.sender) {
		    uint256 ethToSend = amountRaised - fundTransferred;
			if (beneficiary.send(ethToSend)) {
			  fundTransferred = fundTransferred.add(ethToSend);
			} 
		}
    }
}