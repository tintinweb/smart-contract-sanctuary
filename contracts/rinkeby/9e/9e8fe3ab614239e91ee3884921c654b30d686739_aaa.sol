/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

pragma solidity ^0.6.12;

contract  aaa {
    event test (uint x, uint y, uint result);
    function add(uint x , uint y) external returns (uint) {
        uint result = x+y;
        emit test(x, y, result);
        return result;
    }
}