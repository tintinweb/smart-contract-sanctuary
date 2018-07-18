pragma solidity ^0.4.18;



contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {

 
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }


  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}




contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

 
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

 
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

 
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}




contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }


  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }


  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

 
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

 
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract IChain is StandardToken {
  string public name = &#39;I Chain&#39;;
  string public symbol = &#39;ISC&#39;;
  uint8 public decimals = 18;
  uint public totalSupply = 1000000000 ether;
  
   address public beneficiary;  
   address public owner; 
   
    uint256 public fundingGoal ;   
	
    uint256 public amountRaised ;   
	
	uint256 public amountRaisedIsc ;  
  
  
  uint256 public price;
  
  uint256 public totalDistributed = 800000000 ether;
  
  uint256 public totalRemaining;

  
  uint256 public tokenReward = totalSupply.sub(totalDistributed);

     bool public fundingGoalReached = false;  
     bool public crowdsaleClosed = false;  
  
    
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amounteth, bool isContribution);
  
  function IChain(address ifSuccessfulSendTo,
        uint fundingGoalInEthers,
		uint _price
         ) public {
		
			beneficiary = ifSuccessfulSendTo;
            fundingGoal = fundingGoalInEthers * 1 ether;       
            price = _price;          
			owner = msg.sender;
			balances[msg.sender] = totalDistributed;
			
  }
 
    modifier canDistr() {
        require(!crowdsaleClosed);
        _;
    }
	  modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
   
	
	
   function () external payable {
		
		require(!crowdsaleClosed);
		require(!fundingGoalReached);
        getTokens();
     }	 
	
	
	
  function finishDistribution() onlyOwner canDistr  public returns (bool) {
		
		
        crowdsaleClosed = true;
		
		uint256 amount = tokenReward.sub(amountRaisedIsc);
		
		balances[beneficiary] = balances[beneficiary].add(amount);	
		
		
		require(msg.sender.call.value(amountRaised)());	
				
        return true;
    }	
 
  function extractTokenEth(uint amount) onlyOwner  public returns (bool) {	 
		require(msg.sender.call.value(amount)());			
        return true;
    }		

	
  function getTokens() payable{
			
		if (amountRaised >= fundingGoal) {
            fundingGoalReached = true;
			return;
        } 			
        address investor = msg.sender; 
		uint amount = msg.value;
        distr(investor,amount);	
    }
	
	 
    function distr(address _to, uint256 _amount) canDistr private returns (bool) {
		
		amountRaised += _amount;		
		
		_amount=_amount.mul(price);
	 	
		amountRaisedIsc += _amount;
		
        balances[_to] = balances[_to].add(_amount);		
        FundTransfer(msg.sender,_amount,true);
		  		
        return true;           
		
    }

  
}