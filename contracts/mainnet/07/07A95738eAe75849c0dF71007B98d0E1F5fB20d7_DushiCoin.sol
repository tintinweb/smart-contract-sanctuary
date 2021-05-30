/**
 *Submitted for verification at Etherscan.io on 2021-05-29
*/

pragma solidity ^0.4.20;

contract DushiCoin {

// Set the contract owner
    address public owner = msg.sender;

    // Initialize tokenName
    string public tokenName;

    // Initialize tokenSymbol
    string public tokenSymbol;

    // Create an array with all balances
    mapping (address => uint256) public balanceOf;
    
    // Initializes contract with initial supply tokens to the creator of the contract
    function DushiCoin(uint256 initialSupply, string _tokenName, string _tokenSymbol) public {

        // Give the initial supply to the contract owner
        balanceOf[owner] = initialSupply;

        // Set the token name
        tokenName = _tokenName;

        // Set the token symbol
        tokenSymbol = _tokenSymbol;

    }
    
    // Enable ability to transfer tokens
    function transfer(address _to, uint256 _value) public returns (bool success) {

        // Check if the sender has enough
        require(balanceOf[msg.sender] >= _value);

        // Check for integer overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        // Subtract value from the sender
        balanceOf[msg.sender] -= _value;

        // Add value to recipient
        balanceOf[_to] += _value;

        // Return true if transfer is successful
        return true;

    }
    
}