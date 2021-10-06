/**
 *Submitted for verification at Etherscan.io on 2021-10-05
*/

pragma solidity ^0.8.3;

contract Test {
    uint public temp;
    
    function test0(uint96 a, uint256 b) external {
        temp = a / b;
    }
}