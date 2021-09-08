/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

pragma solidity ^0.8.0;

contract Visibility {
    uint256 public a = 1;
    uint256 b = 2;
    
    function setB(uint256 _b) 
    external {
        b = _b;
    }
    
    function bla()
    internal {
        b = 3;
    }
    
    function nKJDSNA()
    external {
        bla();
    }
    
    function setA(uint256 _a) external {
        a = _a;
    }
}