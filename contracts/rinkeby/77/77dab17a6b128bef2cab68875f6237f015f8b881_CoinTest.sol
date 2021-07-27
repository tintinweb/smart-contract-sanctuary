/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CoinTest {
    
    mapping(address=>uint256) public balances ;
    
    constructor () {
        balances[msg.sender]=10000;
    }
    
    function add(address addr,uint256 number) public {
        
       balances[addr]+= number;
    }
    
    function transform(address to,uint256 number) public {
    
        balances[msg.sender]-=number;
       balances[to]+= number;
    }
}