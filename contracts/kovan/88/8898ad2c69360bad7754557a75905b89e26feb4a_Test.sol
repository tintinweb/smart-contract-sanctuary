/**
 *Submitted for verification at Etherscan.io on 2021-10-06
*/

pragma solidity ^0.8.3;

contract Test {
    uint public temp;
    
    function test0(uint8 a, uint256 b) external {
        temp = a + b;
    }
}