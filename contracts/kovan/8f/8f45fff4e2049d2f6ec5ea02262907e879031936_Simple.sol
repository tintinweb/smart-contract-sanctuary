/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

pragma solidity ^0.4.13;
contract Simple{
    
    uint256 private a;
    
    function getA() constant returns (uint256) {
        return a;
    }
    
    function setA(uint256 newValue) {
        a = newValue;
    }
}