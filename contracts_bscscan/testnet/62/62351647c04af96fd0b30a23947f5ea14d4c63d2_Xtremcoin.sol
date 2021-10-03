/**
 *Submitted for verification at BscScan.com on 2021-10-02
*/

/**
 *Submitted for verification at Etherscan.io on 2018-02-09
*/

pragma solidity ^0.4.19;

contract SafeMath{
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
	
	function safeSub(uint a, uint b) internal returns (uint) {
    	assert(b <= a);
    	return a - b;
  }

	function safeAdd(uint a, uint b) internal returns (uint) {
    	uint c = a + b;
    	assert(c >= a);
    	return c;
  }
	function assert(bool assertion) internal {
	    if (!assertion) {
	      throw;
	    }
	}
}


contract ERC20{

 	function totalSupply() constant returns (uint256 totalSupply) {}
	function balanceOf(address _owner) constant returns (uint256 balance) {}
	function transfer(address _recipient, uint256 _value) returns (bool success) {}
	function transferFrom(address _from, address _recipient, uint256 _value) returns (bool success) {}
	function approve(address _spender, uint256 _value) returns (bool success) {}
	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

	event Transfer(address indexed _from, address indexed _recipient, uint256 _value);
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);


}

contract Xtremcoin is ERC20, SafeMath{

	
	mapping(address => uint256) balances;

	string 	public name = "Xtremcoin";
	string 	public symbol = "XTR";
	uint 	public decimals = 8;
	uint256 public CIR_SUPPLY;
	uint256 public totalSupply;
	uint256 public price;
	address public owner;
	uint256 public endTime;
	uint256 public startTime;

	function Xtremcoin(uint256 _initial_supply, uint256 _price, uint256 _cir_supply) {
		totalSupply = _initial_supply;
		balances[msg.sender] = _initial_supply;  // Give all of the initial tokens to the contract deployer.
		CIR_SUPPLY = _cir_supply;
		endTime = now + 17 weeks;
		startTime = now + 15 days;
		owner 	= msg.sender;
		price 	= _price;
	}

	function balanceOf(address _owner) constant returns (uint256 balance) {
	    return balances[_owner];
	}
    
	function transfer(address _to, uint256 _value) returns (bool success){
	    require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balances[msg.sender] > _value);                // Check if the sender has enough
        require (safeAdd(balances[_to], _value) > balances[_to]); // Check for overflows
	    balances[msg.sender] = safeSub(balances[msg.sender], _value);
	    balances[_to] = safeAdd(balances[_to], _value);
	    Transfer(msg.sender, _to, _value);
	    return true;
	}

	mapping (address => mapping (address => uint256)) allowed;

	function transferFrom(address _from, address _to, uint256 _value) returns (bool success){
	    var _allowance = allowed[_from][msg.sender];
	    require (_value < _allowance);
	    
	    require (_to != 0x0);                               // Prevent transfer to 0x0 address. Use burn() instead
        require (balances[msg.sender] > _value);                // Check if the sender has enough
        require (safeAdd(balances[_to], _value) > balances[_to]); // Check for overflows
	    balances[_to] = safeAdd(balances[_to], _value);
	    balances[_from] = safeSub(balances[_from], _value);
	    allowed[_from][msg.sender] = safeSub(_allowance, _value);
	    Transfer(_from, _to, _value);
	    return true;
	}

	function approve(address _spender, uint256 _value) returns (bool success) {
	    allowed[msg.sender][_spender] = _value;
	    Approval(msg.sender, _spender, _value);
	    return true;
	}

	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
	    return allowed[_owner][_spender];
	}


	modifier during_offering_time(){
		if (now < startTime || now >= endTime){
			throw;
		}else{
			_;
		}
	}

	function () payable during_offering_time {
		createTokens(msg.sender);
	}

	function createTokens(address recipient) payable {
		if (msg.value == 0) {
		  throw;
		}
		uint tokens = safeDiv(safeMul(msg.value, price), 1 ether);
        if(safeSub(balances[owner],tokens)>safeSub(totalSupply, CIR_SUPPLY)){
            balances[owner] = safeSub(balances[owner], tokens);
		    balances[recipient] = safeAdd(balances[recipient], tokens);   
        }else{
            throw;
        }

		if (!owner.send(msg.value)) {
		  throw;
		}
	}

}