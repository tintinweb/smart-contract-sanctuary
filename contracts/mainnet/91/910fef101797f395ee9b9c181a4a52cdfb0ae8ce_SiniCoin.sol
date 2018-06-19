pragma solidity ^0.4.8;

/**
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}
contract SiniCoin is SafeMath{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	address public owner;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
	
	/* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
	
	/* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function SiniCoin(
        string tokenName,uint256 tokenSupply,uint8 decimalUnits,string tokenSymbol) {
        owner = msg.sender;
        totalSupply = tokenSupply;  
        balanceOf[msg.sender] = totalSupply;              
        name = tokenName;                                  
        symbol = tokenSymbol;                               
        decimals = decimalUnits;                            
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) {
        require(balanceOf[_to] + _value > balanceOf[_to]); // overflow chk
        require(_to != 0x0); //deny 0x0 adr
        
        require(_value > 0);
        require(balanceOf[msg.sender] > _value);

        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                    
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            
        Transfer(msg.sender, _to, _value);                      
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require(balanceOf[_to] + _value > balanceOf[_to]); // overflow chk
        require(_to != 0x0); //deny 0x0 adr
        require(_value > 0);
        require(balanceOf[_from] > _value);
        require(_value < allowance[_from][msg.sender]); //alw chk

        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) returns (bool success) {
        require(balanceOf[msg.sender] > _value);
        require(_value > 0);
	
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                
        Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint256 _value) returns (bool success) {
        require(balanceOf[msg.sender] > _value);
        require(_value > 0);

        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                
        Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) returns (bool success) {
        require(freezeOf[msg.sender] > _value);
        require(_value > 0);
       
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                      
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        Unfreeze(msg.sender, _value);
        return true;
    }


	function()  {
        
    }
}