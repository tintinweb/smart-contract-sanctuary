/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

pragma solidity ^0.5.16;

contract Collection {
    function hello() external pure returns (string memory) {
         return "hello";
     }
    
    function sum(uint256 a, uint256 b) external pure returns (uint256) {
         return a + b;
     }
}