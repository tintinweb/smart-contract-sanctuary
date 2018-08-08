pragma solidity ^0.4.12;

//below is math function
contract SafeMath {
    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }
 
    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }
 
    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }
}


contract Token {
    uint256 public totalSupply;
	address public ownerAddress;          // ETH存放地址
	address public allowSendAddress;      // 允许往交易所转账
	
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	modifier isOwner()  { require(  msg.sender == ownerAddress); _; }
	
	function totalSupply() constant returns (uint256 supply) {return totalSupply;}
}




/*  ERC 20 token */
contract StandardToken is Token,SafeMath {
 
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0 && balances[_to] + _value >= balances[_to]) {
			
			balances[msg.sender] = safeSubtract(balances[msg.sender],_value);			
			balances[_to] = safeAdd(balances[_to],_value);
			
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
	
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (  (balances[_from] >= _value) && (allowed[_from][msg.sender] >= _value) && (_value > 0) && (balances[_to] + _value >= balances[_to])) {
			allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender],_value);
			balances[_from] = safeSubtract(balances[_from],_value);
            balances[_to] = safeAdd(balances[_to],_value);
			
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }
 
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }
 
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
 
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
 
	function formatDecimals(uint256 _value) internal returns (uint256 ) {
        return _value * 10 ** decimals;

	}
	
	uint256 public constant decimals = 18;
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}



contract BOTCoin is StandardToken {
 
    // metadata
    string  public constant name = "BOTCoin";
    string  public constant symbol = "BOT";
    
    
	constructor(address _ownerAddress,uint256 _initialAmount) public {
        totalSupply = formatDecimals(_initialAmount);
		balances[msg.sender] = totalSupply;
		allowSendAddress = _ownerAddress;
		ownerAddress = msg.sender;
    }
}


contract Coin007 is StandardToken {
 
    // metadata
    string  public constant name = "BOTCoin";
    string  public constant symbol = "BOT";
    uint256 public constant decimals = 18;
    
	constructor(address _ownerAddress,uint256 _initialAmount) public {
        totalSupply = formatDecimals(_initialAmount);
		balances[msg.sender] = totalSupply;
		allowSendAddress = _ownerAddress;
		ownerAddress = msg.sender;
    }
	
	function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0 && balances[_to] + _value >= balances[_to]) {
			
			balances[msg.sender] = safeSubtract(balances[msg.sender],_value);			
			balances[_to] = safeAdd(balances[_to],_value);
			
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }
}