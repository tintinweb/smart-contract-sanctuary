/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

pragma solidity ^0.4.17;

contract sample{
    uint256 public testVar;
    
    function setVar(uint256 _var) external{
        testVar = _var;
    }
}