pragma solidity ^0.4.18;

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
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

contract WIN {
    
    using SafeMath for uint256;
    
    uint256 constant private MAX_UINT256 = 2**256 - 1;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	address public owner;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _from, uint256 value);

    constructor(uint256 _initialSupply, string _tokenName, uint8 _decimalUnits, string _tokenSymbol) public {
        name = _tokenName;                                   
        symbol = _tokenSymbol;
        decimals = _decimalUnits;                            
        totalSupply = _initialSupply;                        
        balanceOf[msg.sender] = _initialSupply;
        owner = msg.sender;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
            // Test validity of the address &#39;_to&#39;:
        require(_to != 0x0);
            // Test positiveness of &#39;_value&#39;:
		require(_value > 0);
		    // Check the balance of the sender:
        require(balanceOf[msg.sender] >= _value);
            // Check for overflows:
        require(balanceOf[_to] + _value >= balanceOf[_to]); 
            // Update balances of msg.sender and _to:
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);                     
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);                            
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
            // Test validity of the address &#39;_to&#39;:
        require(_to != 0x0);
            // Test positiveness of &#39;_value&#39;:
		require(_value > 0);
		    // Check the balance of the sender:
        require(balanceOf[msg.sender] >= _value);
            // Check for overflows:
        require(balanceOf[_to] + _value >= balanceOf[_to]); 
            // Update balances of msg.sender and _to:
            // Check allowance&#39;s sufficiency:
        require(_value <= allowance[_from][msg.sender]);
            // Update balances of _from and _to:
        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);                           
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);
            // Update allowance:
        require(allowance[_from][msg.sender]  < MAX_UINT256);
        allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
            // Test positiveness of &#39;_value&#39;:
		require(_value > 0); 
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
            // Check msg.sender&#39;s balance sufficiency:
        require(balanceOf[msg.sender] >= _value);           
            // Test positiveness of &#39;_value&#39;:
		require(_value > 0); 
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);                    
        totalSupply = SafeMath.sub(totalSupply,_value);                              
        emit Burn(msg.sender, _value);
        return true;
    }
            
}