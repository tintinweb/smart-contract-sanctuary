/**
 *Submitted for verification at Etherscan.io on 2021-08-31
*/

pragma solidity ^0.5.17;


contract TestContract{
    
    uint256 private val1;
  
    function method1() public returns (uint256) {
        val1 += 1;
        return val1;
    }
    
    function method2() public returns (uint256) {
        val1 -= 1;
        return val1;
    }
    
     function method3(uint256 _val) public returns (uint256) {
        val1 = _val;
        return val1;
    }
    
}