pragma solidity ^0.4.24;

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract CTC is SafeMath{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    address public owner;
    
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint) public lockedArray;
    
    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
    
    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);
    
    /* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);
    
    
    event test_value(uint256 indexed value1);
    
    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor( uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) 
    public {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        totalSupply = initialSupply;                        // Update total supply
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
        owner = msg.sender;
    }
    
    /* Send coins */
    function transfer(address _to, uint256 _value) public {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        require(lockedArray[msg.sender] != 1);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                     // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                            // Add the same to the recipient
        lockedArray[_to] = 1;       // 0 = unlock  1 = locked
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
    }
    
    function addSupply(uint _value) public {
        // require(msg.sender == owner);
        require(_value > 0);
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        totalSupply = SafeMath.safeAdd(balanceOf[msg.sender], _value);
    }
    
    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)public returns (bool success) {
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    
    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value)public returns (bool success) {
        require(_to != 0x0);
        require(_value > 0);
        require(balanceOf[_from] >= _value);
        require(_value < allowance[_from][msg.sender]);
        require(lockedArray[msg.sender] != 1);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                           // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function unlock(address _designated) public returns (bool success){
        lockedArray[_designated] = 0;
        return true;
    }
    
    function burn(uint256 _value)public returns (bool success) {
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }
    
    function freeze(uint256 _value)public returns (bool success) {
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }
    
    function unfreeze(uint256 _value)public returns (bool success) {
        require(_value > 0);
        require(freezeOf[msg.sender] >= _value);
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                      // Subtract from the sender
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
}