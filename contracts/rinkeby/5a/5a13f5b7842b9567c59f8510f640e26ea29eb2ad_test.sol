/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract test{
    
    
    uint[]public price;
    uint public nowPrice;
    
    struct token{
        string name;
        address _add;
    }
    
    function set(uint a)public {
        for(nowPrice;nowPrice<a;nowPrice++){
            price.push(nowPrice);
        }
    }
    
    
    function get()public view returns(uint){
        return price.length;
    }
    
   
}