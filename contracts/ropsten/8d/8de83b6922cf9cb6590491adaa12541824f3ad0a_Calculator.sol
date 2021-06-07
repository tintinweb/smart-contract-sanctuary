/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

pragma solidity >=0.7.0 <0.9.0;

contract Calculator {
    function plus(uint a, uint b) public pure returns (uint result) {
        result = a + b;
    }
    
    function minus(uint a, uint b) public pure returns (uint result) {
        result = a - b;
    }
    
    function multiply(uint a, uint b) public pure returns (uint result) {
        result = a * b;
    }
    
    function divide(uint a, uint b) public pure returns (uint result) {
        result = a / b;
    }
}