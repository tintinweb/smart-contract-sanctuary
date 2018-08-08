pragma solidity ^0.4.18;

interface ERC20{
	function balanceOf(address _owner) public constant returns(uint);
	function transfer(address _to, uint _value) public returns(bool);
	function transferFrom(address _from, address _to, uint _value) public returns(bool);
	function approve(address _sender, uint _value) public returns (bool);
	function allowance(address _owner, address _spender) public constant returns(uint);
    event Transfer(address indexed _from, address indexed _to, uint _value);
	event Approval(address indexed _owner, address indexed _spender, uint _value);
	event Burn(address indexedFrom,uint256 value);
}

contract Token
{
	string internal _symbol;
	string internal _name;
	uint8 internal _decimals;	
    uint256 internal _totalSupply;
   	mapping(address =>uint) internal _balanceOf;
	mapping(address => mapping(address => uint)) internal _allowances;

    function Token(string symbol, string name, uint8 decimals, uint totalSupply) public{
	    _symbol = symbol;
		_name = name;
		_decimals = decimals;
		_totalSupply = totalSupply;
    }

	function name() public constant returns (string){
        	return _name;    
	}

	function symbol() public constant returns (string){
        	return _symbol;    
	}

	function decimals() public constant returns (uint8){
		return _decimals;
	}

	function totalSupply() public constant returns (uint){
        	return _totalSupply;
	}
}
contract Admined{
    
    address public owner;

    function Admined() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));      
        owner = newOwner;
    }
}

contract MyToken is Admined, ERC20,Token("TTL","Talent Token",18,50000000)
{
   	mapping(address =>uint) private _balanceOf;
    mapping(address => mapping(address => uint)) private _allowances;
	bool public transferAllowed = false;
    
    modifier whenTransferAllowed() 
	{
        if(msg.sender != owner){
        	require(transferAllowed);
        }
        _;
    }
    
     function MyToken() public{
        	_balanceOf[msg.sender]=_totalSupply;
    }
    	
    function balanceOf(address _addr)public constant returns (uint balance){
       	return _balanceOf[_addr];
	}

	function transfer(address _to, uint _value)whenTransferAllowed public returns (bool success){
        	require(_to!=address(0) && _value <= balanceOf(msg.sender));{
            _balanceOf[msg.sender]-= _value;
           	_balanceOf[_to]+=_value;
			Transfer(msg.sender, _to, _value);
           	return true;
		}
		return false;
    	}	
    
	function transferFrom(address _from, address _to, uint _value)whenTransferAllowed public returns(bool success){
        require(balanceOf(_from)>=_value && _value<= _allowances[_from][msg.sender]);
        {
			_balanceOf[_from]-=_value;
    		_balanceOf[_to]+=_value;
			_allowances[_from][msg.sender] -= _value;
			Transfer(_from, _to, _value);  
			return true;
    	}
        	return false;
   	}

	function approve(address _spender, uint _value) public returns (bool success){
        	_allowances[msg.sender][_spender] = _value;
        	return true;
    	}

    	function allowance(address _owner, address _spender) public constant returns(uint remaining){
        	return _allowances[_owner][_spender];
        }
        
    function allowTransfer() onlyOwner public {
        transferAllowed = true;
    }

 function burn(uint256 _value) public returns (bool) {
        require(_value <= _balanceOf[msg.sender]);
        _balanceOf[msg.sender] -= _value;
        _totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }
    
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(_value <= _balanceOf[_from]);
        require(_value <= _allowances[_from][msg.sender]);
        _balanceOf[_from] -= _value;
        _allowances[_from][msg.sender] -= _value;
        _totalSupply -= _value;
        Burn(_from, _value);
        return true;
    }
}