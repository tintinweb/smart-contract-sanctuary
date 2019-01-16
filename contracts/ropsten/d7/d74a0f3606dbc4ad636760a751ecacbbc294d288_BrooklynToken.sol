// source: ED remix Tim Wheelers Brooklyn Hackathon demo
// https://codesnippet.io/creating-your-own-cryptocurrency/
// deploy: 1000, "BrooklynToken","BKNTKN"

// Creating a your own Ethereum Cryptocurrency
// By Tim Wheeler
// Software Engineer
// CareerDevs.com / TimWheeler.com


// Step 1. Download Metamask Chrome Extension & Create an Account
// Step 2. Select the &#39;Ropsten Test Network&#39; from the networks dropdown
// Step 3. Goto https://faucet.metamask.io/ and request 1 ether from the faucet
// Step 4. Goto remix.ethereum.org
// Step 5. Under &#39;compiler&#39; tab set compiler version to 0.4.20+commit.3155dd80
// Step 6. Under run tab, set environment to &#39;Injected Web3&#39;


//https://www.ethereum.org/token

// Set the solidity compiler version
pragma solidity ^0.4.25;


contract BrooklynToken {
    
    // Set the contract owner
    address public owner = msg.sender;

    // Initialize tokenName
    string public tokenName;

    // Initialize tokenSymbol
    string public tokenSymbol;
    
    // Initialize _totalSupply    
    uint public initialSupply;

    // Create an array with all balances
    mapping (address => uint256) public balanceOf;

    
    // Initializes contract with initial supply tokens to the creator of the contract
    constructor(uint256 _initialSupply, string _tokenName, string _tokenSymbol) public {
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        initialSupply = _initialSupply;
        
        // Give the initial supply to the contract owner
        balanceOf[owner] = initialSupply;
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