/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

pragma solidity ^0.5.1;

contract ERC20 {
    
    uint public totalSupply;
    
    mapping(address => uint) balance;
    
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    
    constructor () public {
        totalSupply = 10000;
        balance[msg.sender] = 10000;
        
    }
    
    function name() public view returns (string memory) {
        return "TestToken";
    }
    function symbol() public view returns (string memory) {
        return "TT";
    }

    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balance[tokenOwner];
    }
    
    //Overflow is possible
    function transfer(address to, uint tokens) public returns (bool success){
        require(balance[msg.sender] >= tokens);
        balance[msg.sender] -= tokens;
        balance[to] += tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
}