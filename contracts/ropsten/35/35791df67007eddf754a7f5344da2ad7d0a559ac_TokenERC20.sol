pragma solidity ^0.4.21;


/**
 * NemoLab ERC20 Token
 * Written by Shin HyunJae
 * version 12
 */
contract TokenERC20 {
    
    
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals = 18;    // 18 decimals is the strongly suggested default, avoid changing it
    uint256 public totalSupply;

    /* This creates an array with all bal&#229;ances */
    mapping (address => uint256) public balances;

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(string tokenName, string tokenSymbol, uint256 initialSupply) public {
        name = tokenName;                                       // Set the name for display purposes
        symbol = tokenSymbol;                                   // Set the symbol for display purposes
        totalSupply = initialSupply;     // Update total supply with the decimal amount
        balances[msg.sender] = totalSupply;                     // Give the creator all initial tokens
    }


}