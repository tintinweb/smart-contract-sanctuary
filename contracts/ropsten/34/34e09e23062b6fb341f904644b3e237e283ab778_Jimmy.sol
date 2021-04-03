/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

pragma solidity ^0.5.17;

contract Jimmy {
    
    mapping(address => uint256) balance;
    
    function transfer(address to, uint256 amount) public {
        require(balance[msg.sender] >= amount);
            balance[msg.sender] == amount;
            balance[to] += amount;
        
    }
    
}