/**
 *Submitted for verification at BscScan.com on 2021-07-08
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;


interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Lock {
    address owner;
    uint256 startTime;

    constructor () {
        owner = msg.sender;
        startTime = block.timestamp;
    }

    function withdraw(address _token, address _to) external {
        require(owner == msg.sender, "not the owner");
        require(startTime + 1 hours > block.timestamp, "not yet time");

        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, balance);
    }
}