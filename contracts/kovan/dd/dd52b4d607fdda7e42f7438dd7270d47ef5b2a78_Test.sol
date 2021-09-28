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
    
    function test0() external {
        a.a = 4;
        a.b = 5;
    }
    
    function test1() external {
        A storage b = a;
        b.a = 4;
        b.b = 5;
    }
}