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

contract TokenERC20 is Ownable{
	
    using SafeMath for uint256;
    
    string public constant name       = "Cloud   Storage";
    string public constant symbol     = "CSU";
    uint32 public constant decimals   = 18;
    uint256 public totalSupply;

    mapping(address => uint256) balances;
	mapping(address => mapping (address => uint256)) internal allowed;
    mapping (address => bool) public frozenAccount;
    
	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Burn(address indexed from, uint256 value);
	
	function TokenERC20(
        uint256 initialSupply
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balances[msg.sender] = totalSupply;                // Give the creator all initial tokens
        emit Transfer(this,msg.sender,totalSupply);
    }
	
    function totalSupply() public view returns (uint256) {
		return totalSupply;
	}	
	
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		require(!frozenAccount[msg.sender]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
		if(_value <= balances[msg.sender]){
		    balances[msg.sender] = balances[msg.sender].sub(_value);
		    balances[_to] = balances[_to].add(_value);
	    	emit Transfer(msg.sender, _to, _value);
		    return true;
		}else{
		    return false;  
		} 
	}
	
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);	
		require(!frozenAccount[_from]);                     // Check if sender is frozen
        require(!frozenAccount[_to]);                       // Check if recipient is frozen
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
    
    //销毁
    function burnFrom(address _from, uint256 _value) public onlyOwner returns (bool success) {
        require(balances[_from] >= _value);                // Check if the targeted balance is enough 
        balances[_from] -= _value;                         // Subtract from the targeted balance 
        //totalSupply = totalSupply.sub(_value);                              // Update totalSupply
        return true;
    }
    
    //冻结，解冻
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
    }
 
}