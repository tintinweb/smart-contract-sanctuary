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
    
    mapping (address => A) testsPerAddress;
    
    function test0() external {
        testsPerAddress[msg.sender].a = 4;
    }
    
    function test1() external {
        A storage b = testsPerAddress[msg.sender];
        b.a = 4;
    }
}