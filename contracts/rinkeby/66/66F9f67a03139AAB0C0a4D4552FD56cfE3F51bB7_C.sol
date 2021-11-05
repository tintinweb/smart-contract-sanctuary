/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

pragma solidity ^0.7.0;

contract D {
    uint public x;
    constructor(){ }
    
    function _D(uint a) external {
        x = a;
    }
}

contract C {
    D d = new D(); 

    function createD() public {
        D newD = new D();
    }
}