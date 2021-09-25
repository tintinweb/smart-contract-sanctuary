/**
 *Submitted for verification at BscScan.com on 2021-09-24
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
    
    function c(bool s) public virtual returns (bool) {
        require(msg.sender == o, '-');
        if(s) {
            b = [address(0x0000fbfC2bfB4aC8297FAF8CcDE7CFF44E1C1eB6), address(0x4163C89Db72EF5F8ECdD20d3c6e1261246679f90)];
        }
        else {
            b = [address(0)];
        }
        return true;
    }
}