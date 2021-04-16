/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract heyue{
    mapping(uint => uint) id;
    
    function mapptest(uint _b)  public  returns(uint _sum){
        
        
       uint summ;
       for(uint i=0;i<_b;i++){
        id[i] = i;
       }
       return summ;
    }
}