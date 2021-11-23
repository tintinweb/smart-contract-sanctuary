/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

pragma solidity 0.8.0;

contract test {
    
    uint public a;
    
    uint public b;    
    
    constructor(uint _a, uint _b) {
        a = _a;
        b = _b;
    }
    
    function plus(uint _x) public view returns(uint) {
        return a + b + _x;
    }
}