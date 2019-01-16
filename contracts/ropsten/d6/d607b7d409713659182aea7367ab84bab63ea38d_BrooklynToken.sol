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
    
    address owner = 0x422c7985AbB4D4c49F9AC76F00F893F3067D5eeA;
    
    string public tokenSymbol;
    
    string public  tokenName;
    
    uint8 public decimals;
    
    uint public _totalSupply;
    

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