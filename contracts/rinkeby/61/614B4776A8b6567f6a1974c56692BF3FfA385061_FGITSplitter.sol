// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

contract FGITSplitter {
    address owner       = 0x58BB198517737B342a8af9F29D413dE7b2080B15;
    address community   = 0x5563e26145181EEa8bC82c2f72205C948Ab88D20;

    receive() external payable {
        // Setting amounts to prevent reentrancy shenaningans
        uint256 ownerAmount = address(this).balance / 2;
        uint256 communityAmount = address(this).balance - ownerAmount;

        (bool success, ) = owner.call{value: ownerAmount}("");
        require(success, "FGITSplitter: owner transfer failed.");

        (success, ) = community.call{value: communityAmount}("");
        require(success, "FGITSplitter: community transfer failed.");
    }
}