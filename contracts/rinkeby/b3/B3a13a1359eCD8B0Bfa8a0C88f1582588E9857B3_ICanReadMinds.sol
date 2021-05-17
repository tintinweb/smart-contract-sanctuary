/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ICanReadMinds{
    uint nonce;
    
    constructor() {
        nonce = uint16(type(uint).max) % uint80(0x0000FFF6);
    }
    
    function readMind(uint input) public view returns(uint){
        uint num = input;
        
        while(num > 9){
            uint sum = 0;
            while (num > 0){
                sum = sum + (num % 10);
                num = (num - (num % 10)) / 10;
            }
            num = sum;
        }

        
        return (nonce - num);
    }
    
}