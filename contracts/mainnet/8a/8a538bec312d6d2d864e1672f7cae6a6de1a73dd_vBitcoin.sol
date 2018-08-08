pragma solidity ^0.4.24;

contract ERC20Basic {
	uint256 public totalSupply;
	function balanceOf(address who) public constant returns (uint256);
	function transfer(address to, uint256 value) public returns (bool);
	event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
	function allowance(address owner, address spender) public constant returns (uint256);
	function transferFrom(address from, address to, uint256 value) public returns (bool);
	function approve(address spender, uint256 value) public returns (bool);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a / b;
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a); 
		return a - b; 
	} 
	
	function add(uint256 a, uint256 b) internal pure returns (uint256) { 
		uint256 c = a + b; assert(c >= a);
		return c;
	}

}

contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]); 
		balances[msg.sender] = balances[msg.sender].sub(_value); 
		balances[_to] = balances[_to].add(_value); 
		emit Transfer(msg.sender, _to, _value); 
		return true; 
	} 

	function balanceOf(address _owner) public constant returns (uint256 balance) { 
		return balances[_owner]; 
	} 
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
		emit Transfer(_from, _to, _value); 
		return true; 
	} 

	function approve(address _spender, uint256 _value) public returns (bool) { 
		allowed[msg.sender][_spender] = _value; 
		emit Approval(msg.sender, _spender, _value); 
		return true; 
	}

	function allowance(address _owner, address _spender) public constant returns (uint256 remaining) { 
		return allowed[_owner][_spender]; 
	} 

	function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]); 
		return true; 
	}

	function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
		uint oldValue = allowed[msg.sender][_spender]; 
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function () public payable {
		revert();
	}

}

contract Ownable {
	address public owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

	constructor() public {
		owner = msg.sender;
	}

	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newOwner) onlyOwner public {
		require(newOwner != address(0));
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
	}
}

contract MintableToken is StandardToken, Ownable {
		
	event Mint(address indexed to, uint256 amount);
    
    uint public totalMined;

	function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
		require(totalMined.sub(totalSupply) >= _amount);
		totalSupply = totalSupply.add(_amount);
		balances[_to] = balances[_to].add(_amount);
		emit Mint(_to, _amount);
		return true;
	}
}

contract vBitcoin is MintableToken {
	string public constant name = "Virtual Bitcoin";
	string public constant symbol = "vBTC";
	uint32 public constant decimals = 18;
	
    uint public start = 1529934560;
    uint public startBlockProfit = 50;
    uint public blockBeforeChange = 210000;
    uint public blockTime = 15 minutes;
    
    function defrosting() onlyOwner public {
        
        uint _totalMined = 0;
        uint timePassed = now.sub(start);
        uint blockPassed = timePassed.div(blockTime);
        uint blockProfit = startBlockProfit;
        
        while(blockPassed > 0) {
            if(blockPassed > blockBeforeChange) {
                _totalMined = _totalMined.add(blockBeforeChange.mul(blockProfit));
                blockProfit = blockProfit.div(2);
                blockPassed = blockPassed.sub(blockBeforeChange);
            } else {
                _totalMined = _totalMined.add(blockPassed.mul(blockProfit));
                blockPassed = 0;
            }
        }
        
        totalMined = _totalMined;
        totalMined.mul(1000000000000000000);
    }
}