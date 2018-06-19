pragma solidity ^0.4.18;
/*
 * Math operations with safety checks
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
    return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract ekkoBlock is SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	  address public owner;

    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);
    
    function ekkoBlock(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) public  {
        balanceOf[msg.sender] = initialSupply;              
        totalSupply = initialSupply;                        
        name = tokenName;                                   
        symbol = tokenSymbol;                               
        decimals = decimalUnits;                    
		owner = msg.sender;
    }


    function transfer(address _to, uint256 _value) public {
        if (_to == 0x0)  revert();                               
		if (_value <= 0)  revert(); 
        if (balanceOf[msg.sender] < _value)  revert();           
        if (balanceOf[_to] + _value < balanceOf[_to])  revert(); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                    
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                           
        Transfer(msg.sender, _to, _value);                  
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (_to == 0x0)  revert();                                
		if (_value <= 0)  revert(); 
        if (balanceOf[_from] < _value)  revert();                 
        if (balanceOf[_to] + _value < balanceOf[_to])  revert();  
        if (_value > allowance[_from][msg.sender])  revert();     
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }
    
    function freeze(address _target, uint256 _value) public returns (bool success) {
        if(msg.sender != owner) revert();
        if (balanceOf[_target] < _value)  revert();            // Check if the _target has enough
		    if (_value <= 0)  revert(); 
        balanceOf[_target] = SafeMath.safeSub(balanceOf[_target], _value);                      // Subtract from the sender
        freezeOf[_target] = SafeMath.safeAdd(freezeOf[_target], _value);                                // Updates totalSupply
        Freeze(_target, _value);
        return true;
    }
	
	  function unfreeze(address _target, uint256 _value) public returns (bool success) {
        if(msg.sender != owner) revert();
        if (freezeOf[_target] < _value)  revert();            // Check if the _target has enough
        if (_value <= 0)  revert(); 
        freezeOf[_target] = SafeMath.safeSub(freezeOf[_target], _value);                      // Subtract from the sender
        balanceOf[_target] = SafeMath.safeAdd(balanceOf[_target], _value);
        Unfreeze(_target, _value);
        return true;
    }

}