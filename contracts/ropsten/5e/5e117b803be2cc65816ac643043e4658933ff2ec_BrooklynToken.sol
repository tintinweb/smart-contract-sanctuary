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
pragma solidity ^0.4.20;

// // Create smart contract
// contract CodeToken {

//     // Contract owner
//     address owner;
    
//     // Token name
//     string public tokenName;

//     // Token symbol
//     string public tokenSymbol;

//     // Decimal places token is divisible by => 18 is highly recommended by the Ethereum spec
//     uint8 public decimals = 18;

//     // Total supply of coins
//     uint256 public totalSupply;

//     // Array of all balances
//     mapping (address => uint256) public balanceOf;

//     // Function to create coins, passing in supply, name, and symbol
//     function TokenERC20(uint256 _totalSupply, string _tokenName, string _tokenSymbol) public {
        
//         // Update total supply with the decimal amount, converting to Wei
//         totalSupply *=  _totalSupply * 10 ** uint256(decimals);

//         // Give the creator all initial coins
//         balanceOf[msg.sender] = totalSupply;

//         // Set the name of the coin for display purposes
//         tokenName = _tokenName;

//         // Set the symbol of the coin
//         tokenSymbol = _tokenSymbol;
//     }
    
//     // Create our token
//     // TokenERC20 public (1000, "CodeToken", "CODE");=
//     constructor() public {
//         owner = msg.sender;
//         _tokenName = "CodeToken";
//         _tokenSymbol = "CODE";
//         _totalSupplySupply = 1000;
//     }


//     // Function to send coins
//     function transfer(address _to, uint256 _value) public returns (bool success) {

//         // Check if the sender has enough coins
//         require(balanceOf[msg.sender] >= _value);

//         // Check for integer overflows
//         require(balanceOf[_to] + _value >= balanceOf[_to]);

//         // Subtract coins from the senders address
//         balanceOf[msg.sender] -= _value;

//         // Add coins to the recipients address
//         balanceOf[_to] += _value;

//         // If all went smooth, return true
//         return true;
//     }


// }

contract BrooklynToken {
    
    string public tokenSymbol;
    
    string public  tokenName;
    
    uint8 public decimals;
    
    uint public _totalSupply;
    
    address owner = msg.sender;

    mapping (address => uint256) public balanceOf;

    // Instantiate our coin
    constructor() public {
        tokenSymbol = "BKLYN";
        tokenName = "BrooklynToken";
        decimals = 18;
        _totalSupply = 1000;
        balanceOf[owner] = _totalSupply;
    }
    
    function transfer(address _to, uint256 _value) public returns (bool success) {

        // Check if the sender has enough coins
        require(balanceOf[msg.sender] >= _value);

        // Check for integer overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);

        // Subtract coins from the senders address
        balanceOf[msg.sender] -= _value;

        // Add coins to the recipients address
        balanceOf[_to] += _value;

        // If all went smooth, return true
        return true;
    }
}