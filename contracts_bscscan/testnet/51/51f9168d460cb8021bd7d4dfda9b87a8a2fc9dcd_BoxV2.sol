// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BoxV2 {
    uint256 private count;

    function store(uint256 _newCount) public returns (uint256) {
        count = _newCount;
        return count;
    }
    
    function getCount() public view returns (uint256) {
        return count;
    }
    
    function increaseCount() public returns (uint256) {
        count = count + 1;
        return count;
    }
}