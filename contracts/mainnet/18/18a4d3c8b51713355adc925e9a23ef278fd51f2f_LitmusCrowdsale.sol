pragma solidity ^0.4.11;

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

contract ERC20 {
	using SafeMath for uint256;
	uint256 public totalSupply;
	address public contractHolder;
	string public constant name = "LITMUS";
	string public constant symbol = "LIT";
	uint8 public constant decimals = 0;
	

    event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
	
	mapping(address => uint256) balances;
	mapping (address => mapping (address => uint256)) internal allowed;
	

	function ERC20 (){
	contractHolder = msg.sender;
	
	}
	
    modifier ifHolder(){
    require(contractHolder == msg.sender);
    _;
    }
	
	function allocate(address _to, uint256 _amount)  ifHolder public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Transfer(0x0, _to, _amount);
    return true;
	}
	
    function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
	}
  
    function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
	}

	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
	}


	function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
	}


	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
	}
  

	function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
	}

	function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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


contract LitmusCrowdsale {
	using SafeMath for uint256;
	uint256 public weiRaised = 0;
	uint256 public rate = 1000000000000000;
	uint256 public goal = 1000000000000000000000;
	uint256 public cap = 5000000000000000000000;
	
	uint256 public startTime =  1506556800;
	uint256 public bonusTime = 1507248000;
	uint256 public endTime =  1509235200;

	bool public fundersClaimed = false;
	address public issuer;
	
    ERC20 public token;
	mapping (address => uint256) contributions;
	event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
	
	function LitmusCrowdsale (){	
	issuer = msg.sender;
	token = createTokenContract();
	}
	
	modifier ifIssuer(){
    require(issuer == msg.sender);
    _;
    }

    function createTokenContract() internal returns (ERC20) {
    return new ERC20();
	}
    
	function timeElapsed() internal constant returns (bool) {
	bool assertTime = now > endTime;
	return assertTime;
	}
	
	
    function goalReached() internal constant returns (bool) {
    return weiRaised >= goal;
	}
	
	function icoFunded() internal constant returns (bool) {
    bool softCap = goalReached() && timeElapsed();
	bool hardCap = weiRaised >= cap;
	return softCap || hardCap;
	}
	
	function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
	bool withinCap = weiRaised.add(msg.value) <= cap;
    return withinPeriod && withinCap;
	}
	
	function accruedBonus(uint256 senderWei, uint256 _tokens) internal constant returns (uint256 bonus) {
    require(_tokens != 0);
	if (now <= bonusTime || senderWei >= 1 ether) {
		return _tokens.div(20);
		}
		return 0;
	}
	
	function buyTokens() public payable {
    require(msg.value >= 50 finney);
	require(validPurchase());
	address backer =  msg.sender;
    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.div(rate);
	tokens = tokens.add(accruedBonus(weiAmount,tokens));
    weiRaised = weiRaised.add(weiAmount);
    token.allocate(backer, tokens);
	contributions[backer] = contributions[backer].add(weiAmount);
	TokenPurchase(msg.sender, msg.sender, weiAmount, tokens);
    }
	
	function claimRefund() public {
	require(!goalReached() && timeElapsed());		
	address investor = msg.sender;
	uint256 invested = contributions[investor];
	require(invested > 0);
	contributions[investor] = 0;
	investor.transfer(invested);
	}
	
	function finalise() ifIssuer public {		
	require(icoFunded());
	issuer.transfer(this.balance);
	}
  
	function init() ifIssuer public {	
	require(!fundersClaimed);
	fundersClaimed = true;
	token.allocate(issuer, 5750000);
	}
	
	function mop() ifIssuer public {
	require(now > endTime + 31 days);
	issuer.transfer(this.balance);
	} 
    
    function verifyYourBalance(address _YourWallet) public constant returns (uint256 balance) {
	return token.balanceOf(_YourWallet);
    }

	function () payable {
    buyTokens();
	}

}