/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

pragma solidity 0.7.6;

contract Test {
    uint public num;
    function test(uint a, uint b) external{
        num = a / b;
    }
}