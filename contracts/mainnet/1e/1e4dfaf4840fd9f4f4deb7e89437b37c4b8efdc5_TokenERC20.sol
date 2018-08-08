pragma solidity ^0.4.21;


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }


  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract TokenERC20 is Ownable {
	
    using SafeMath for uint256;
    
    string public constant name       = "Superchain";
    string public constant symbol     = "SUP";
    uint32 public constant decimals   = 18;
    uint256 public totalSupply;
    address public airdrop;
    address public ethaddrc;
    uint256 public buyPrice           = 40000;
    uint256 public times;
    uint256 public shuliang           = 100000000 ether;

	

    mapping(address => uint256) balances;
	mapping(address => mapping (address => uint256)) internal allowed;
 
	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

	
	function TokenERC20(
	    address _ethadd,
        uint256 initialSupply,
        address _airdrop
    ) public {
        airdrop = _airdrop;
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balances[airdrop] = totalSupply;                // Give the creator all initial tokens
        ethaddrc = _ethadd;
        times = now;
        
    }
	
    function totalSupply() public view returns (uint256) {
		return totalSupply;
	}	
	
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}
	
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

    function allowance(address _owner, address _spender) public view returns (uint256) {
		return allowed[_owner][_spender];
	}

	function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}

	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} else {
			allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
		}
		emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
	}
	
	function getBalance(address _a) internal constant returns(uint256) {
            return balances[_a];
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return getBalance( _owner );
    }
 
	function () payable public {
	    if(now < times + 365 days && shuliang > 0 ){
	        uint amount = msg.value * buyPrice;  
        	require(balances[airdrop] >= amount);
        	balances[msg.sender] = balances[msg.sender].add(amount);                  
            balances[airdrop] = balances[airdrop].sub(amount); 
            shuliang = shuliang.sub(amount);
            emit Transfer(airdrop, msg.sender, amount);    
            ethaddrc.transfer(msg.value);
	    }
    }
	
 
    function selfdestructs()   public onlyOwner {
    	selfdestruct(owner);
    }
    
    function addre(address _owner) public onlyOwner{
        ethaddrc = _owner;
    }
 
    function geth(uint num) payable public onlyOwner {
    	owner.transfer(num);
    }
 
	
}