/**
 *Submitted for verification at polygonscan.com on 2022-01-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract PyMonsAirdrop {
    mapping(address => uint256) public allocations;
    bool public claimable = false;
    address public owner;

    modifier onlyOwner {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    constructor () {
        owner = msg.sender;
    }
    
    function claimAllocation() external {
        require(claimable, "Cannot claim now");
        require(allocations[msg.sender] > 0, "No allocation for claimer");
        uint allocation = allocations[msg.sender];
        allocations[msg.sender] = 0;
        payable(msg.sender).transfer(allocation);
    }
    
    function addAllocations(address [] memory addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; ++i) {
            allocations[addresses[i]] += 5.13 ether;
        }
    }
    
    function toggleClaiming() external onlyOwner {
        claimable = !claimable;
    }
    
    function depositForAirdrop() external payable { }
    
    function withdrawAll() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    
}