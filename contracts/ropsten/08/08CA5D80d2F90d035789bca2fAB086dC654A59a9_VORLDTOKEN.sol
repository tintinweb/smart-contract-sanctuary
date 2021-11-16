/**
 *Submitted for verification at Etherscan.io on 2021-11-15
*/

pragma solidity ^0.8.7;
//SPDX-License-Identifier: MIT

contract VORLDTOKEN{
    
    address public minter;
    mapping (address => uint) public balances;
    
    event Sent(address from, address to, uint amountoftokens);
    
    constructor()
    {
        minter = msg.sender;
    }
    
  
    function mint(address reciever, uint amountoftokens) public {
        
        require(msg.sender == minter);
        balances[reciever] += amountoftokens;
        
    }
    
    function send(address reciever, uint amountoftokens) public {
       require(amountoftokens<= balances[msg.sender], "Insufficient finds");
       balances[msg.sender] -= amountoftokens;
       balances[reciever] += amountoftokens;
       emit Sent(msg.sender, reciever, amountoftokens);
    }
    
}