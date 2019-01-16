pragma solidity ^0.4.25; 

//0.4.25+commit.59dbf8f1

contract FirstToken {
    
    /* This creates an array with addresses connected with balances */
    mapping (address => uint256) public balanceOf;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    
    // EVENTS
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // Initializes contract with initial supply tokens to the creator of the contract
    // W nowej wersji nie używa się function o nazwie contract ale constructor
    /* Initializes contract with initial supply tokens to the creator of the contract */
    
    constructor (uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits) public {
        balanceOf[msg.sender] = initialSupply;              // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
        decimals = decimalUnits;                            // Amount of decimals for display purposes
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value;                    // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);             // Powiadomienie o tym ze transfer sie odbyl
        return true;
    }
    
}