/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

pragma solidity ^0.8.3;

contract TimeShitV2 {
    uint public count;
    uint256 public time;
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
    
    function getTime() public returns (uint256) {
        time = block.timestamp;
    }
}