/**
 *Submitted for verification at Etherscan.io on 2021-09-24
*/

//"SPDX-License-Identifier: UNLICENSED"
pragma solidity ^0.7.0;

contract wtf {
    
    event AssertTest(bool ret);
    
    constructor() {
        
    }
    
    function revertMe() public {
        emit AssertTest(true);
        
        require(false, "oh ok !");
    }
    
    function assertTrue() public {
        
        emit AssertTest(true);
        
        assert(true);

    }
    
    function assertFalse() public {
        emit AssertTest(false);
        
        assert(false);
    }
    
}