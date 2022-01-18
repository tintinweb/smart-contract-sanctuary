/**
 *Submitted for verification at BscScan.com on 2022-01-18
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.8.10 and less than 0.9.0
pragma solidity ^0.8.10;

contract Counter {
    string public greet = "Hello World!";
    uint private count;
    uint private test;

    // Function to get the current count
    function get() public view returns (uint) {
        return count;
    }

    // Function to get the current count
    function gettest() public view returns (uint) {
        return test;
    }

    // Function to increment count by 1
    function inc() public {
        count += 1;
        test += 2;
    }

    // Function to decrement count by 1
    function dec() public {
        count -= 1;
        test -= 2;
    }

    function setcount(uint _num) public {
        count = _num;
    }

}