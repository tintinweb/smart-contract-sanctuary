//SourceUnit: gsc.sol

pragma solidity >=0.5.0 <0.7.0;
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
        uint256 c = a / b;
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

contract Coin {
    using SafeMath for uint;
   
    string public constant name       = "GSC";
    string public constant symbol     = "GSC";
    uint32 public constant decimals   = 6;
    uint256 public  _totalSupply  =   100000000;
    
    mapping(address => uint256) balances;
	mapping(address => mapping (address => uint256)) internal allowed;
	mapping(address => bool) public frozenAccount;

	event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    // 事件，用来通知客户端代币被消费
    event Burn(address indexed from, uint256 value);
    
    // Constructor code is only run when the contract
    // is created
    constructor(
        uint256 initialSupply,
        address add_ad
    ) public {
        _totalSupply = initialSupply * 10 ** uint256(decimals);  
        balances[add_ad] = _totalSupply;                
        emit Transfer(msg.sender, add_ad, _totalSupply);
    }
    
    function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}
	
	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
		require(_value <= balances[msg.sender]);
		if(!frozenAccount[msg.sender]){
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
		if(!frozenAccount[_from]){
		    balances[_from] = balances[_from].sub(_value);
		    balances[_to] = balances[_to].add(_value);
		    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
		    emit Transfer(_from, _to, _value);
		    return true;
		}else{
		    return false;
		}
		
	}
	
	function multiTransfer(address[] memory destinations, uint256[] memory tokens) public returns (bool) {
	    require(destinations.length > 0);
        require(destinations.length < 128);
		
		uint8 i = 0;
		for (i = 0; i < destinations.length; i++){
            if(!frozenAccount[msg.sender]){
                require(destinations[i] != address(0));
                require(tokens[i] <= balances[msg.sender]);
    		    balances[msg.sender] = balances[msg.sender].sub(tokens[i]);
    		    balances[destinations[i]] = balances[destinations[i]].add(tokens[i]);
    		    emit Transfer(msg.sender, destinations[i], tokens[i]);
    		}
        }
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
 
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    } 
}