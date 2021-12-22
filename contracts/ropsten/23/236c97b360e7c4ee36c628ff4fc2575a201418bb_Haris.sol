/**
 *Submitted for verification at Etherscan.io on 2021-12-22
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.5.0;

contract ERC20Interface  {
    function balanceOf(address tokenOwner) public view returns (uint);
    function transfer(address to, uint tokens) public  returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
}




contract Haris is ERC20Interface{
    string public name;
    uint8 public decimals; 

    mapping(address => uint) balances;

    
    constructor() public {
        name = "Haris";
        decimals = 18;

    }

    function balanceOf(address tokenOwner)  public view returns (uint) {
    return balances[tokenOwner];
    }
    
    function transfer(address receiver, uint numTokens)  public  returns (bool) {
    require(numTokens <= balances[msg.sender]);
    balances[msg.sender] = (balances[msg.sender] - numTokens);
    balances[receiver] = balances[receiver] + numTokens;
    emit Transfer(msg.sender, receiver, numTokens);
    return true;
    }

}