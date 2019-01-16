pragma solidity >0.4.24 <0.6.0;

/**
 * Math operations with safety checks
 */
contract SafeMath{
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0); 
        uint256 c = a / b;
        assert(a == b * c + a % b); 
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract LEASToken is SafeMath{
    string public name = "Linked Ecological Available System";
    string public symbol = "LEAS";
    uint8 public decimals = 18;
    uint256 public totalSupply = 200 * 10 ** 8 * 10 ** uint256(decimals);

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    constructor() public{
        balanceOf[msg.sender] = totalSupply;    // Give the creator all initial tokens
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public returns (bool success){
        if (_to == 0x0000000000000000000000000000000000000000) revert();                                               // Prevent transfer to 0x0 address
        if (_value <= 0) revert(); 
        if (balanceOf[msg.sender] < _value) revert();                           // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();                 // Check for overflows
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);    // Subtract from the sender
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);                  // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);     // Notify anyone listening that this transfer took place
        return true;
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        if (_value <= 0) revert();
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       
    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (_to == 0x0000000000000000000000000000000000000000) revert();                                   // Prevent transfer to 0x0 address
        if (_value <= 0) revert();
        if (balanceOf[_from] < _value) revert();                    // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) revert();     // Check for overflows
        if (_value > allowance[_from][msg.sender]) revert();        // Check allowance
        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);  // Subtract from the sender
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);      // Add the same to the recipient
        allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);      // Notify anyone listening that this transfer took place
        return true;
    }
}