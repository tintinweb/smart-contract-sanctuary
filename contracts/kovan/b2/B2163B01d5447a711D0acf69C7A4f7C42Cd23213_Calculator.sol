/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.7.3;

contract Calculator {
    uint256 public calculateResult;
    address public user;
    
    function add(uint256 a, uint256 b) public returns (uint256) {
        calculateResult = a + b;
        assert(calculateResult >= a);
        
        user = msg.sender;
        
        return calculateResult;
    }
}