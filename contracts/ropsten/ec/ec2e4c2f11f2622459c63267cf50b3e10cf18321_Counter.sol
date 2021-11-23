/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

pragma solidity ^0.4.11;

contract Counter {
    int private count = 0;
    function incrementCounter() public {
        count += 1;
    }
    function decrementCounter() public {
        count -= 1;
    }
    function getCount() public constant returns (int) {
        return count;
    }
}