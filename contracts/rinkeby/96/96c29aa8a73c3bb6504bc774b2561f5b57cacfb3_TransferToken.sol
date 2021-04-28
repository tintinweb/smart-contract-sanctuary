/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity ^0.5.11;


contract Momo {
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract TransferToken {
    Momo obj;
     function setAddress(address Address) external {
         obj = Momo(Address);
     }
    function transfer(address receiver, uint tokens) external {
        obj.transfer(receiver, tokens);
    }
    
    
}