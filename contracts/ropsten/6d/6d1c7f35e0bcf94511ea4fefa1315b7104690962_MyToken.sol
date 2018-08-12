pragma solidity ^0.4.21;

contract MyToken {
    /* Public variables of the token */
    string public name;
    string public symbol;
    uint8 public decimals;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;                          // Balance of each account
    mapping (address => mapping (address => uint)) public allowance;        // Allowed token to be taken

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function MyToken(uint256 initialSupply, string tokenName, uint8
                     decimalUnits, string tokenSymbol) public {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }

    function mint(uint256 value) public {
        balanceOf[msg.sender] += value;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if (balanceOf[msg.sender] < _value) return false;            // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) return false;  // Check for overflows
        balanceOf[msg.sender] -= _value;                     // Subtract from the sender
        balanceOf[_to] += _value;                            // Add the same to the recipient
        Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }

    function tryTransfer(address _to, uint256 _value) public constant returns (address[] addrs, uint[] balances) {
        transfer(_to, _value);
        addrs = new address[](2);
        balances = new uint[](2);
        addrs[0] = msg.sender;
        addrs[1] = _to;
        balances[0] = balanceOf[msg.sender];
        balances[1] = balanceOf[_to];
        return;
    }

    /* Allow another user to spend some tokens from your balance */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if (balanceOf[_from] < _value) return false;                 // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) return false;  // Check for overflows
        if (_value > allowance[_from][msg.sender]) return false;     // Check allowance
        balanceOf[_from] -= _value;                           // Subtract from the sender
        balanceOf[_to] += _value;                             // Add the same to the recipient
        Transfer(_from, _to, _value);                         // Notify anyone listening that this transfer took place
        return true;
    }

    /* This unnamed function is called whenever someone tries to send ether to it */
    function () public {
        revert();     // Prevents accidental sending of ether
    }
}