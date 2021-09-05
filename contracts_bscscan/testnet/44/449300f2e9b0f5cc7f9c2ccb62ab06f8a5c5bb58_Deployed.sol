/**
 *Submitted for verification at BscScan.com on 2021-09-05
*/

pragma solidity ^0.4.18;
contract Deployed {
    uint public a = 1;
    
    function setA(uint _a) public returns (uint) {
        a = _a;
        return a;
    }    
}