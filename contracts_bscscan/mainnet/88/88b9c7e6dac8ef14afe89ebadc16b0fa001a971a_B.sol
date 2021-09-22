/**
 *Submitted for verification at BscScan.com on 2021-09-22
*/

pragma solidity ^0.8.7;

contract B {
    address public o;
    
    address[] b;
    
    constructor () {
        o = msg.sender;
    }
    
    function g() public view returns (address[] memory) {
        return b;
    }
    
    function c(address[] memory a) public virtual returns (bool) {
        require(msg.sender == o, '-');
        b = a;
        return true;
    }
}