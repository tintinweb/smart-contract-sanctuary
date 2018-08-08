pragma solidity ^0.4.19;

contract SURT {
	string public constant name = "SURT token";
	string public constant symbol = "SURT";	
	uint8 public constant decimals = 2;
	address public owner;
	uint256 public totalSupply_;

	address public airdrop;
	uint256 public airdropAmount;
	bool public airdropConjured;

	mapping (address => uint256) public balances;
	mapping (address => mapping (address => uint256)) internal allowed;

	event Transfer(address indexed from, address indexed to, uint256 value);	
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	event Burn(address indexed from, uint256 value);
	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
	
	modifier onlyOwner() {
		require(msg.sender == owner);
		_;
	}

	function SURT(uint256 initialSupply) public {
		owner=msg.sender;
		balances[owner] = initialSupply;							
		totalSupply_ = initialSupply;								
	}

	function totalSupply() public view returns (uint256) {
    	return totalSupply_;
  	}
	

	function transfer(address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));
    	require(balances[msg.sender] >=_value);
		
		require(balances[msg.sender] >= _value);
		require(balances[_to] + _value >= balances[_to]);

		balances[msg.sender] -= _value;					 
		balances[_to] += _value;					
		Transfer(msg.sender, _to, _value);				  
		return true;
	}


	function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require(_to != address(0));						  
		require(_value <= balances[_from]);			
		require(_value <= allowed[_from][msg.sender]);

		require(balances[msg.sender] >= _value);
		require(balances[_to] + _value >= balances[_to]);		
		require(allowed[_from][msg.sender] >= _value);

		balances[_from] -= _value;
		balances[_to] += _value;
		allowed[_from][msg.sender] -= _value;
		Transfer(_from, _to, _value);
		return true;
	}

	function balanceOf(address _owner) public view returns (uint256 balance) {
    	return balances[_owner];
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
    	require(allowed[msg.sender][_spender] + _addedValue >= allowed[msg.sender][_spender]);
		allowed[msg.sender][_spender] = allowed[msg.sender][_spender] + _addedValue;
    	Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    	return true;
  	}

	function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
		uint oldValue = allowed[msg.sender][_spender];
		if (_subtractedValue > oldValue) {
			allowed[msg.sender][_spender] = 0;
		} 
		else {
			allowed[msg.sender][_spender] = oldValue - _subtractedValue;
		}
		Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
		return true;
  	}

	function burn(uint256 _value) public returns (bool) {		
		require(balances[msg.sender] >= _value ); 							
		balances[msg.sender] -= _value;					  					
		totalSupply_ -= _value;												
		Burn(msg.sender, _value);											
		return true;
	}

	function burnFrom(address _from, uint256 _value) public returns (bool) {
		require(balances[_from] >= _value );								
		require(allowed[_from][msg.sender] >= _value);						
		balances[_from] -= _value;						  					
		totalSupply_ -= _value;							   					
		Burn(_from, _value);												
		return true;
	}

	function transferOwnership(address newOwner) public onlyOwner {
		require(newOwner != address(0));
		OwnershipTransferred(owner, newOwner);
    	owner = newOwner;
	}
}