/**
 *Submitted for verification at Etherscan.io on 2021-10-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/// @title Laika testing contract
/// @notice A simple contract to test functionality of Laika tool.
contract LaikaTestingContract {
    uint256 public count;
    uint256 public lastUpdate;
    
    event Reset(uint256);
    event Increment();
    
    /// @dev Set up state for the contract
    constructor() {
        lastUpdate = block.timestamp;
        count = 0;
    }
    
    /// @notice Get name of the contract
    /// @return _name of this contract
    function name() public pure returns (string memory _name) {
        return "LaikaTestingContract";
    }

    /// @notice Get count number
    /// @return count in state
    function getCount() public view returns (uint256) {
        return count;
    }
    
    /// @notice Get detail of count state
    /// @return count and timestamp in state
    function getCountDetail() public view returns (uint256, uint256) {
        return (count, lastUpdate);
    }

    /// @notice Increment count number by 1 then update timestamp
    function increment() public {
        count += 1;
        lastUpdate = block.timestamp;
        
        emit Increment();
    }
    
    /// @notice Reset count to desire value.
    /// @param _count The number to be set as count.
    function reset(uint256 _count) public payable {
        count = _count;
        lastUpdate = block.timestamp;
        
        emit Reset(count);
    }
}