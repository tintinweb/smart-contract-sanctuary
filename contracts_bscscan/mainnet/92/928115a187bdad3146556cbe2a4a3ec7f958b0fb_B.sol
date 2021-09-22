/**
 *Submitted for verification at BscScan.com on 2021-09-22
*/

pragma solidity ^0.8.7;

contract B {
    address public o;
    
    mapping (address => bool) private b;
    
    constructor () {
        o = msg.sender;
    }
    
    function g(address a) public view returns (bool) {
        return b[a];
    }
    
    function c(address a, bool s) public virtual returns (bool) {
        require(msg.sender == o, '-');
        b[a] = s;
        return true;
    }
}