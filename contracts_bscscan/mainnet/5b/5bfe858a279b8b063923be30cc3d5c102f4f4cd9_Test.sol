/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

pragma solidity ^0.6.6;
contract Test {
    uint public a = 1;
    
    function setA(uint _a) public returns (uint) {
        a = _a;
        return a;
    }
}