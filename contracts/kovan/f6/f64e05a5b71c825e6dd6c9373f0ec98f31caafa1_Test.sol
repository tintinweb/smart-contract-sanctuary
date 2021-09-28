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
    
    constructor() {
        a.a = 1;
        a.b = 2;
        a.c = 3;
    }
    
    function test1() external {
        A memory b = a;
        b.a = 6;
        b.c = 7;
        a = b;
    }
}