/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity ^0.4.11;

contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Airdrop {
    
    address public owner;
    address public _tokenAddress = 0x4197057af60F8ad619d11d59F15dF1fe967F0101;
    
    // number of tokens to send to each recipient
    uint256 tokens = 10;
    // decimals of the token
    uint256 decimals = 9;
    
    constructor() public {
        owner = msg.sender;
    }
    
    function setTokensPerRecipient(uint256 _tokens) public {
        require(msg.sender == owner, "Only owner can change the nubmer of tokens");
        tokens = _tokens;
    }

    function multisend(address[] _to) public  returns (bool _success) {
        require(_to.length > 0);
        require(msg.sender == owner, "Only owner can send airdrop");
        
        
        // Send the values to all the recipients
        for (uint8 i = 0; i < _to.length; i++) {
            require((ERC20Interface(_tokenAddress).transfer(_to[i], tokens * 10 ** decimals)) == true);
        }

        return true;
    }
    
    //ex. to send the airdrop to 3 addresses the owner will have to enter the addresses
    //in the form shown below when calling the "multisend" function:

    //["0x11ac009fb6b3d1a857d07fb73893980d1e70d8b5", "0x2b9fc7f2fe038252a16a34334ede31dee7d10792", "0x798d0a37581dcbc3482c9ad4be4d63603a55d9f9"]    
}