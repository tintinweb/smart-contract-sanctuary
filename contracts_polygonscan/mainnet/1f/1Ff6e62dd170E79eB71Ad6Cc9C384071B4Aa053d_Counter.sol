/**
 *Submitted for verification at polygonscan.com on 2021-10-26
*/

pragma solidity ^0.5.17;

contract Counter {
    uint256 count;  // persistent contract storage

    constructor(uint256 _count) public {
        count = _count;
    }

    function increment() public {
        count += 1;
    }

    function getCount() public view returns (uint256) {
        return count;
    }
}