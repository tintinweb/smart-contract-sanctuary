/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT 

pragma  solidity >=0.7.0 <0.8.8;

contract carlucoin {
    
    address public minter;
    mapping (address => uint) public balances;
    
    event sent(address from, address to, uint amount);
    
    constructor() {
        minter= msg.sender;}
        
        function mint(address receiver, uint amount) public {
            require(msg.sender == minter);
            require(amount< 1e60);
            balances [receiver] += amount; 
        }
        
        function send (address receiver, uint amount) public {
            require(amount <= balances [msg.sender], "Insuficient balance");
            balances [msg.sender] -=amount;
            balances [receiver] +=amount;
            emit sent (msg.sender, receiver, amount);
            
        }
    }