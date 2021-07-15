/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

pragma solidity ^0.6.6;

contract Increment {
    uint public count;

    // Function to get the current count
    function get() public view returns (uint) {
        return count;
    }

    // Function to increment count by 1
    function inc() public {
        count += 1;
    }

    // Function to decrement count by 1
    function dec() public {
        count -= 1;
    }
}