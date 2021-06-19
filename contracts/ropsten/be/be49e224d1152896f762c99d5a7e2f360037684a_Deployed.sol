/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

pragma solidity ^0.8.5;
contract Deployed {
    uint public a = 1;
    
    function setA(uint _a) public returns (uint) {
        a = _a;
        return a;
    }
    
}