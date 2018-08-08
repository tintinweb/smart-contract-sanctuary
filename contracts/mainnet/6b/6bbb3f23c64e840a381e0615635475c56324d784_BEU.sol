pragma solidity ^0.4.24;

/**
 * Math operations with safety checks
 */
library SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        require(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c>=a && c>=b);
        return c;
    }
}

contract BEU {
    using SafeMath for uint256;
    string public name = "BitEDU";
    string public symbol = "BEU";
    uint8 public decimals = 18;
    uint256 public totalSupply = 2000000000000000000000000000;
    address public owner;
    bool public lockAll = false;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => uint256) public lockOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* This generates a public event on the blockchain that will notify clients */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value);

    /* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor() public {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;                                        // Give the creator all initial tokens
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(!lockAll);                                                          // lock all transfor in critical situation
        require(_to != 0x0);                                                        // Prevent transfer to 0x0 address. Use burn() instead
        require(_value > 0);                                                        // Check value
        require(balanceOf[msg.sender] >= _value);                                   // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]);                         // Check for overflows
        require(balanceOf[_to] + _value >= _value);                                 // Check for overflows
        require(balanceOf[msg.sender] >= lockOf[msg.sender]);                                 // Check for lock
        require(balanceOf[msg.sender] >= lockOf[msg.sender] + _value);              // Check for lock
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);    // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                  // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                                     // Notify anyone listening that this transfer took place
        return true;
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require((_value == 0) || (allowance[msg.sender][_spender] == 0));           // Only Reset, not allowed to modify
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(!lockAll);                                                          // lock all transfor in critical situation cases
        require(_to != 0x0);                                                        // Prevent transfer to 0x0 address. Use burn() instead
        require(_value > 0);                                                        // Check Value
        require(balanceOf[_from] >= _value);                                        // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]);                          // Check for overflows
        require(balanceOf[_to] + _value > _value);                                  // Check for overflows
        require(allowance[_from][msg.sender] >= _value);                            // Check allowance
        require(balanceOf[_from] >= lockOf[_from]);                                 // Check for lock
        require(balanceOf[_from] >= lockOf[_from] + _value);                        // Check for lock
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);              // Subtract from the sender
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                  // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function freeze(uint256 _value) public returns (bool success) {
        require(_value > 0);
        require(balanceOf[msg.sender] >= _value);                                   // Check if the sender has enough
        require(freezeOf[msg.sender] + _value >= freezeOf[msg.sender]);             // Check for Overflows
        require(freezeOf[msg.sender] + _value >= _value);                           // Check for Overflows
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);    // Subtract from the sender
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);      // Updates totalSupply
        emit Freeze(msg.sender, _value);
        return true;
    }

    function unfreeze(uint256 _value) public returns (bool success) {
        require(_value > 0);                                                        // Check Value
        require(freezeOf[msg.sender] >= _value);                                    // Check if the sender has enough
        require(balanceOf[msg.sender] + _value > balanceOf[msg.sender]);            // Check for Overflows
        require(balanceOf[msg.sender] + _value > _value);                           // Check for overflows
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);      // Subtract from the freeze
        balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);    // Add to balance
        emit Unfreeze(msg.sender, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require(msg.sender == owner);                                               // Only Owner
        require(_value > 0);                                                        // Check Value
        require(balanceOf[msg.sender] >= _value);                                   // Check if the sender has enough
        require(totalSupply >= _value);                                             // Check for overflows
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);    // Subtract from the sender
        totalSupply = SafeMath.safeSub(totalSupply, _value);                        // Updates totalSupply
        return true;
    }

    function lock(address _to, uint256 _value) public returns (bool success) {
        require(msg.sender == owner);                                                // Only Owner
        require(_to != 0x0);                                                         // Prevent lock to 0x0 address
        require((_value == 0) || (lockOf[_to] == 0));                                // Only Reset, not allowed to modify
        require(balanceOf[_to] >= _value);                                           // Check for lock overflows
        lockOf[_to] = _value;
        return true;
    }

    function lockForAll(bool b) public returns (bool success) {
        require(msg.sender == owner);                                                // Only Owner
        lockAll = b;
        return true;
    }

    function () public payable {
        revert();
    }
}