/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

pragma solidity ^0.8.3;

contract Test {
    struct A {
        uint a;
        uint b;
        uint c;
    }
    
    A public a;
    uint public test;
    
    constructor() {
        a.a = 1;
        a.b = 2;
        a.c = 3;
    }
    
    function test0() external {
        if(base()) {
            test = 10;
        }
    }
    
    function base() public view returns (bool isSub) {
        A storage b = a;
        if (b.a == 1) {
            isSub == true;
        }
    }
}