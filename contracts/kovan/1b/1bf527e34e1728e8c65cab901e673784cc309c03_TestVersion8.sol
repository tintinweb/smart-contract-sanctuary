/**
 *Submitted for verification at Etherscan.io on 2021-03-23
*/

pragma solidity 0.8.2;

contract TestVersion8 {
    uint256 public result;
    
    function checkSubOperation(uint256 a, uint256 b) public {
        result = a - b;
    }
    
    function checkDivOperation(uint256 a, uint256 b) public {
        result = a / b;
    }
    
    function checkMulOperation(uint256 a, uint256 b) public {
        result = a * b;
    }
    
    function checkAddOperation(uint256 a, uint256 b) public {
        result = a + b;
    }
}