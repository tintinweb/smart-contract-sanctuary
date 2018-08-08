pragma solidity ^0.4.14;


//PoW Farm SEED token buying contract
//http://www.PoWFarm.io


contract SafeMath {
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
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}




contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}




contract StandardToken is ERC20, SafeMath {

  /* Token supply got increased and a new owner received these tokens */
  event Minted(address receiver, uint amount);

  /* Actual balances of token holders */
  mapping(address => uint) balances;

  /* approve() allowances */
  mapping (address => mapping (address => uint)) allowed;

  /* Interface declaration */
  function isToken() public constant returns (bool weAre) {
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
      
      if (_value < 1) {
          revert();
      }
      
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
      
      if (_value < 1) {
          revert();
      }
      
    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}





//PoW Farm SEED token buying contract
//http://www.PoWFarm.io

contract MintableToken is StandardToken {
  
    
    uint256 public rate = 5000;				//Each ETH will get you 5000 SEED - Minimum: 0.0002 ETH for 1 SEED
    address public owner = msg.sender;		//Record the owner of the contract
	uint256 public tokenAmount;
  
    function name() constant returns (string) { return "SEED"; }
    function symbol() constant returns (string) { return "SEED"; }
    function decimals() constant returns (uint8) { return 0; }
	


  function mint(address receiver, uint amount) public {

      if (amount != ((msg.value*rate)/1 ether)) {       //prevent minting tokens by calling this function directly.
          revert();
      }
      
      if (msg.value <= 0) {                 //Extra precaution to contract attack
          revert();
      }
      
      if (amount < 1) {                     //Extra precaution to contract attack
          revert();
      }

    totalSupply = safeAdd(totalSupply, amount);
    balances[receiver] = safeAdd(balances[receiver], amount);

    // This will make the mint transaction apper in EtherScan.io
    // We can remove this after there is a standardized minting event
    Transfer(0, receiver, amount);
  }

  
  
	//This function is called when Ether is sent to the contract address
	//Even if 0 ether is sent.
function () payable {
	    
	if (msg.value <= 0) {		//If zero or less ether is sent, refund user. 
		revert();
	}
	
		
	tokenAmount = 0;								//set the &#39;amount&#39; var back to zero
	tokenAmount = ((msg.value*rate)/(1 ether));		//calculate the amount of tokens to give
	
	if (tokenAmount < 1) {
        revert();
    }
      
	mint(msg.sender, tokenAmount);
	tokenAmount = 0;							//set the &#39;amount&#39; var back to zero
		
		
	owner.transfer(msg.value);					//Send the ETH to PoW Farm.

}  
  
  
  
}