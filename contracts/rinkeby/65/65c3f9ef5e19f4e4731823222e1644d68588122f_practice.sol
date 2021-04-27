/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
contract practice{
    
    uint public gas_price;
    
    
    function sum() public payable returns(uint s){
        uint a = 0;
        for (uint i =1; i < 10; i++){
            a = a+i;
        }
        s = a;
        gas_price = tx.gasprice;
    }
    
    function product() public payable returns(uint p){
        uint j = 1;
        for (uint i =1; i < 10; i++){
            j = j*i;
        }
        p = j;
        gas_price = tx.gasprice;
    }
}