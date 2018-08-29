pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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
	uint public totalSupply = 1653200;
	function balanceOf(address who) constant returns (uint);
	function transfer(address to, uint value);
	function allowance(address owner, address spender) constant returns (uint);

	function transferFrom(address from, address to, uint value);
	function approve(address spender, uint value);

	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}

contract CNODStandart is ERC20 {
    using SafeMath for uint;
    
	string  public name        = "Crypto Noda";
    string  public symbol      = "CNOD";
    uint8   public decimals    = 0;

	mapping (address => mapping (address => uint)) allowed;
	mapping (address => uint) balances;

	function transferFrom(address _from, address _to, uint _value) {
		balances[_from] = balances[_from].sub(_value);
		allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(_from, _to, _value);
	}

	function approve(address _spender, uint _value) {
		allowed[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
	}

	function allowance(address _owner, address _spender) constant returns (uint remaining) {
		return allowed[_owner][_spender];
	}

	function transfer(address _to, uint _value) {
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
	}

	function balanceOf(address _owner) constant returns (uint balance) {
		return balances[_owner];
	}
}

contract owned {
    
    address public owner;
    address public newOwner;
	
    function owned() public payable {
        owner = msg.sender;
    }
	
    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }
	
    function changeOwner(address _owner) onlyOwner public {
        require(_owner != 0);
        newOwner = _owner;
    }
    
    function confirmOwner() public {
        require(newOwner == msg.sender);
        owner = newOwner;
        delete newOwner;
    }
}
 
contract Crowdsale is owned, CNODStandart {
    
	using SafeMath for uint;
	uint public start;
	uint public period;
	uint public hardcap;
	uint public softcap;
	uint public min_contribution;
	uint public totalEther;
	uint public wei25;
	uint public wei20;
 
	function Crowdsale() {
		start = 1535328000;
		period = 45;
		hardcap = 400000000000000000000;
		softcap = 180000000000000000000;
		min_contribution = 50000000000000000;
		totalEther = 0;

		wei25 = 234410000000000;
		wei20 = 250000000000000;
	}
 
	modifier saleIsOn() {
		require(now > start && now < start + period * 1 days);
		_;
	}

	modifier isUnderHardCap() {
		require(totalEther <= hardcap);
		_;
	}
	
	function changeTotalSupply(uint _totalSupply) onlyOwner public {
        totalSupply = _totalSupply;
    }
	
	function minContribution(uint _min) onlyOwner public {
        min_contribution = _min;
    }

	function refund() {
		require(this.balance < softcap && now > start + period * 1 days);
		uint value = balances[msg.sender]; 
		balances[msg.sender] = 0; 
		msg.sender.transfer(value); 
	}

	function createTokens() isUnderHardCap saleIsOn payable {
		require(msg.value >= min_contribution);
		uint tokens = 0;
		if (totalEther < 200000000000000000000){
			tokens = msg.value / wei25;
		} else {
			tokens = msg.value / wei20;
		}
		require((totalSupply - tokens) >= 0);
		msg.sender.send(tokens);
		balances[msg.sender] = tokens;
        Transfer(owner, msg.sender, tokens);
		
		totalSupply -= tokens;
		totalEther += msg.value;
	}
	
	function sendToOwnerBalance(address _to, uint256 _valueWei) onlyOwner public {
		require(totalEther >= softcap);
        _to.send(_valueWei);
    }

	function() external payable {
		createTokens();
	}
    
}