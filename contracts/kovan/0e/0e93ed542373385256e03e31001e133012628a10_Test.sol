/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

pragma solidity ^0.8.3;

contract Test {
    struct A {
        uint a;
        uint b;
    }
    
    mapping (address => A) testsPerAddress;
    
    function test1() public {
        A storage b = testsPerAddress[msg.sender];
        b.a = 4;
    }
}