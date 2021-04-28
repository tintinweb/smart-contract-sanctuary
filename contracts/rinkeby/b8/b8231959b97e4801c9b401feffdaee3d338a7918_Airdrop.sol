/**
 *Submitted for verification at Etherscan.io on 2021-04-28
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

    function multisend(address _tokenAddr, address[] _to, uint256[] _value) public
    returns (bool _success) 
    {
        require(_to.length == _value.length);
        require(_to.length > 0);
        require(_value.length > 0);
        
        
        // Send the values to all the recipients
        for (uint8 i = 0; i < _to.length; i++) {
            require((ERC20Interface(_tokenAddr).transfer(_to[i], _value[i])) == true);
        }
        return true;
    }
    
    
    
    
}