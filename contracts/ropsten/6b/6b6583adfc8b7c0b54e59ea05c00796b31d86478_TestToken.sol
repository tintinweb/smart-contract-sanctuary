pragma solidity ^0.4.20;

contract TestToken {
    
    
    // Public variables of the token
    string public name = "TestToken"; // Set the name for display purposes
    string public symbol = "TT"; // Set the symbol for display purposes
    uint8 public decimals = 18;
    uint256 public totalSupply;
    
    
    /* This creates an array with all balances */
    mapping (address => uint256) public balanceOf;

     /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract, set other details related to the token
     */
    function TestToken(
        uint256 initialSupply
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value >= balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] -= _value;                    // Subtract from the sender
        balanceOf[_to] += _value;                           // Add the same to the recipient
        return true;
    }
}