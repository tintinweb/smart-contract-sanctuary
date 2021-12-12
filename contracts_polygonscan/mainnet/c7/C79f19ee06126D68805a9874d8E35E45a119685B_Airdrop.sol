/**
 *Submitted for verification at polygonscan.com on 2021-12-12
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
    
    // address of the token to airdrop, can be changed
    // with the "setTokenAddress" function later
    address public _tokenAddress = 0xd8cda64d6389fbaf39680e9adf0f689dc758470f;
    
    // number of tokens to send to each recipient
    uint256 tokens = 1;
    // decimals of the token
    uint256 decimals = 9;
    
    constructor() public {
        owner = msg.sender;
    }
    
    //ex. to send the airdrop to 3 addresses the owner will have to call the multisend function
    //in the form shown below:

    //["0x11ac009fb6b3d1a857d07fb73893980d1e70d8b5", "0x2b9fc7f2fe038252a16a34334ede31dee7d10792", "0x798d0a37581dcbc3482c9ad4be4d63603a55d9f9"]      
    
    function multisend(address[] _to) public  returns (bool _success) {
        require(msg.sender == owner, "only the owner can send airdrop");
        require(_to.length > 0);
        
        
        // send the values to all the recipients
        for (uint8 i = 0; i < _to.length; i++) {
            require((ERC20Interface(_tokenAddress).transfer(_to[i], tokens * 1 ** decimals)) == true);
        }

        return true;
    }    
    
    function setTokenAddress(address _address) public {
        require(msg.sender == owner, "only the owner can set address");

        _tokenAddress = _address;
    }
    
    function withdrawTokens(address _tokenAddr) public {
        require(msg.sender == owner, "only the owner can remove");
        require(ERC20Interface(_tokenAddr).balanceOf(address(this)) > 0, "can not withdraw 0 or negative");

        require((ERC20Interface(_tokenAddr).transfer(owner, ERC20Interface(_tokenAddr).balanceOf(address(this))) ) == true);
    }
    
}