/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

pragma solidity ^0.5.16;

contract Counter {
    uint public count;
    uint public constant INCREMENT = 2;

    // Function to get the current count
    function get() public view returns (uint) {
        return count;
    }

    // Function to increment count by 1
    function inc() public {
        count = count+INCREMENT;
    }

    // Function to decrement count by 1
    function dec() public {
        count = count-INCREMENT;
    }
}