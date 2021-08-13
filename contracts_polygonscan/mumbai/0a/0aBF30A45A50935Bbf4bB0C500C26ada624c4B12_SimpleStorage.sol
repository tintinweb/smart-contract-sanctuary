/**
 *Submitted for verification at polygonscan.com on 2021-08-12
*/

pragma solidity ^0.8.0;

contract SimpleStorage {
    uint x;

    function set() public {
        x = 25;
    }
    
    function get() public returns (uint) {
        return x;
    }
}