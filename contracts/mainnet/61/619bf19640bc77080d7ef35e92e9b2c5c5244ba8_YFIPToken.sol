pragma solidity ^0.4.26;


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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

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

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract YFIPToken is Ownable {
	
    using SafeMath for uint256;
    
    string public constant name       = "YFIP";
    string public constant symbol     = "YFIP";
    uint32 public constant decimals   = 18;
    uint256 public totalSupply = 2100 * 10 ** uint256(decimals);
    uint256 public initTotalSupply = 2100 * 10 ** uint256(decimals);
  	uint256 public buyPrice = 30;
  	
  	uint256 public burnPercent = 5;
  	
  	
	
    mapping(address => bool) touched; 
    mapping(address => uint256) balances;
	mapping(address => mapping (address => uint256)) internal allowed;
	mapping(address => bool) public frozenAccount;   
	
	event FrozenFunds(address target, bool frozen);
	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
	event Burn(address indexed burner, uint256 value);   
	
	constructor() public {
          
        balances[msg.sender] = totalSupply; 
        emit Transfer(address(0), msg.sender, totalSupply);
        
    }
	
    function totalSupply() public view returns (uint256) {
		return totalSupply;
	}	
	
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(!frozenAccount[msg.sender]); 
		require(_value <= balances[msg.sender]);

        uint256 tokensToBurn = 0;
        if(balances[msg.sender] != initTotalSupply) {
           tokensToBurn = _value.mul(burnPercent).div(100);
        }
        uint256 tokensToTransfer = _value.sub(tokensToBurn);
    

		balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(tokensToTransfer);
        
        totalSupply = totalSupply.sub(tokensToBurn);
        
        
        emit Transfer(msg.sender, _to, tokensToTransfer);
        
        if(tokensToBurn != 0)
            emit Transfer(msg.sender, address(0), tokensToBurn);
            
        return true;
	}
	
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[_from]);
		require(_value <= allowed[_from][msg.sender]);	
		require(!frozenAccount[_from]); 
		

		balances[_from] = balances[_from].sub(_value);
		
		uint256 tokensToBurn = 0;
        if(balances[_from] != initTotalSupply) {
           tokensToBurn = _value.mul(burnPercent).div(100);
        }

        uint256 tokensToTransfer = _value.sub(tokensToBurn);

        balances[_to] = balances[_to].add(tokensToTransfer);
        totalSupply = totalSupply.sub(tokensToBurn);
    
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    
        emit Transfer(_from, _to, tokensToTransfer);
        
        if(tokensToBurn != 0)
            emit Transfer(_from, address(0), tokensToBurn);
    
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
	
	function getBalance(address _a) internal view returns(uint256) {
        return balances[_a];
        
    }
    
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return getBalance( _owner );
    }
	
	
 
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
	
 
	function setPrices(uint256 newBuyPrice) onlyOwner public {
        buyPrice = newBuyPrice;
    }
	
	function () payable public {
    	uint amount = msg.value * buyPrice; 
    	
    	require(balances[owner] >= amount );

    	uint256 tokensToBurn  = amount.mul(burnPercent).div(100);
        
        uint256 tokensToTransfer = amount.sub(tokensToBurn);
    

		balances[owner] = balances[owner].sub(amount);
        balances[msg.sender] = balances[msg.sender].add(tokensToTransfer);
        
        totalSupply = totalSupply.sub(tokensToBurn);
        
        emit Transfer(owner, msg.sender, tokensToTransfer);
        emit Transfer(owner, address(0), tokensToBurn);
        
        
        //Transfer ether to fundsWallet
        owner.transfer(msg.value);
    }
	
    
 
	
}