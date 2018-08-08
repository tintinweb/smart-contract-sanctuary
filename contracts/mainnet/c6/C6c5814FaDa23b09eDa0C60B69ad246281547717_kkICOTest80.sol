pragma solidity ^0.4.11;




contract kkICOTest80 {
    
    string public name;
    string public symbol;
    
    uint256 public decimals;
    uint256 public INITIAL_SUPPLY;
    
    uint256 public rate;
  
    address public owner;						    //init owner address
	
	uint256 public amount;
	
	
	function kkICOTest80() {
        name = "kkTEST80";
        symbol = "kkTST80";
        
        decimals = 0;
        INITIAL_SUPPLY = 30000000;                  //Starting coin supply
        
        rate = 5000;                                //How many tokens per ETH given
		
		owner = msg.sender;			                //Make owner of contract the creator
		
		balances[msg.sender] = INITIAL_SUPPLY;		//Send owner of contract all starting tokens
	}
	
	
	//This function is called when Ether is sent to the contract address
	//Even if 0 ether is sent.
	function () payable {
	    
	    uint256 tryAmount = div((mul(msg.value, rate)), 1 ether);                   //Don&#39;t let people buy more tokens than there are.
	    
		if (msg.value == 0 || msg.value < 0 || balanceOf(owner) < tryAmount) {		//If zero ether is sent, kill. Do nothing. 
			throw;
		}
		
	    amount = 0;									                //set the &#39;amount&#39; var back to zero
		amount = div((mul(msg.value, rate)), 1 ether);				//take sent ether, multiply it by the rate then divide by 1 ether.
		transferFrom(owner, msg.sender, amount);                    //Send tokens to buyer
		amount = 0;									                //set the &#39;amount&#39; var back to zero
		
		
		owner.transfer(msg.value);					                //Send the ETH to contract owner.

	}	
	
	
	
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  
  
  mapping(address => uint256) balances;


  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = sub(balances[msg.sender], _value);
    balances[_to] = add(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }



  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }



  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    balances[_to] = add(balances[_to], _value);
    balances[_from] = sub(balances[_from], _value);
    Transfer(_from, _to, _value);
    return true;
  }

	
	

	
	
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
	
	
	
}