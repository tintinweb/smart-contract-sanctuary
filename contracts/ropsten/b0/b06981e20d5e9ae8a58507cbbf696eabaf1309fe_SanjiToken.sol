pragma solidity ^0.4.24;
contract SafeMath {
  function safeMathMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeMathDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeMathSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeMathAdd(uint256 a, uint256 b) internal returns (uint256) {
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

contract SanjiToken is SafeMath{
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
    constructor(uint256 initialSupply,string tokenName,uint8 decimalUnits,string tokenSymbol ) {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
        owner = msg.sender;
    }

    modifier validAddress {
        assert(0x0 != msg.sender);
        _;
    }

    // Send coins
    function transfer(address _to, uint256 _value) validAddress returns (bool success) {
        // if (_to == 0x0) throw;                               // Prevent transfer to 0x0 address. Use burn() instead
        require(_value > 0);
        // if (_value <= 0) throw; 
        // if (balanceOf[msg.sender] < _value) throw;           // Check if the sender has enough
        // if (balanceOf[_to] + _value < balanceOf[_to]) throw; // Check for overflows
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value >= balanceOf[_to]);        
        balanceOf[msg.sender] = SafeMath.safeMathSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeMathAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }

    // Allow another contract to spend some tokens in your behalf 
    function approve(address _spender, uint256 _value)
        returns (bool success) {
        require(_value > 0);
        // if (_value <= 0) throw; 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

    // A contract attempts to get the coins
    function transferFrom(address _from, address _to, uint256 _value) validAddress returns (bool success) {
        require(_value > 0);
        // if (_value <= 0) throw; 
        require(balanceOf[_from] >= _value);
        // if (balanceOf[_from] < _value) throw;                 // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // if (balanceOf[_to] + _value < balanceOf[_to]) throw;  // Check for overflows
        require(allowance[_from][msg.sender] >= _value);
        // if (_value > allowance[_from][msg.sender]) throw;     // Check allowance
        balanceOf[_from] = SafeMath.safeMathSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeMathAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeMathSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        // if (balanceOf[msg.sender] < _value) throw;            // Check if the sender has enough
        require(_value > 0);
        // if (_value <= 0) throw; 
        balanceOf[msg.sender] = SafeMath.safeMathSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.safeMathSub(totalSupply,_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function freeze(uint256 _value) returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        // if (balanceOf[msg.sender] < _value) throw;            // Check if the sender has enough
        require(_value > 0);
        // if (_value <= 0) throw; 
        balanceOf[msg.sender] = SafeMath.safeMathSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeMathAdd(freezeOf[msg.sender], _value);                                // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
    
    function unfreeze(uint256 _value) returns (bool success) {
        require(freezeOf[msg.sender] >= _value);
        // if (freezeOf[msg.sender] < _value) throw;            // Check if the sender has enough
        require(_value > 0);
        // if (_value <= 0) throw; 
        freezeOf[msg.sender] = SafeMath.safeMathSub(freezeOf[msg.sender], _value);                      // Subtract from the sender
        balanceOf[msg.sender] = SafeMath.safeMathAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }    
}