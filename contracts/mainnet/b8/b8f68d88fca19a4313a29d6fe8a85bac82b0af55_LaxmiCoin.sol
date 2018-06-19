pragma solidity ^0.4.6;


contract tokenRecipient {function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData);}


contract LaxmiCoin {
    /* Public variables of the token */
    string public standard = &#39;LaxmiCoin 1.0&#39;;

    string public name;

    string public symbol;

    uint8 public decimals;

    uint256 public totalSupply;

    address public owner;

    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

    mapping (address => mapping (address => uint256)) public allowance;

    /* This generates a public event on the blockchain that will notify clients */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    function LaxmiCoin(
    uint256 initialSupply,
    string tokenName,
    uint8 decimalUnits,
    string tokenSymbol
    ) {
        balanceOf[msg.sender] = initialSupply;
        // Give the creator all initial tokens
        totalSupply = initialSupply;
        // Update total supply
        name = tokenName;
        // Set the name for display purposes
        symbol = tokenSymbol;
        // Set the symbol for display purposes
        decimals = decimalUnits;
        // Amount of decimals for display purposes
        
        owner=msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }
    /* Send coins */
    function transfer(address _to, uint256 _value) {
        if (_to == 0x0) throw;
        // Prevent transfer to 0x0 address
        if (balanceOf[msg.sender] < _value) throw;
        // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        // Check for overflows
        balanceOf[msg.sender] -= _value;
        // Subtract from the sender
        balanceOf[_to] += _value;
        // Add the same to the recipient
        Transfer(msg.sender, _to, _value);
        // Notify anyone listening that this transfer took place
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value)
    returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /* Approve and then comunicate the approved contract in a single tx */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
    returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        if (_to == 0x0) throw;
        // Prevent transfer to 0x0 address
        if (balanceOf[_from] < _value) throw;
        // Check if the sender has enough
        if (balanceOf[_to] + _value < balanceOf[_to]) throw;
        // Check for overflows
        if (_value > allowance[_from][msg.sender]) throw;
        // Check allowance
        balanceOf[_from] -= _value;
        // Subtract from the sender
        balanceOf[_to] += _value;
        // Add the same to the recipient
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }
    

}