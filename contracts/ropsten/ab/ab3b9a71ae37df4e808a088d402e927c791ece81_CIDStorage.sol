/**
 *Submitted for verification at Etherscan.io on 2021-06-19
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract CIDStorage {
    address public immutable owner = msg.sender;
    uint256 public updatedAt = block.timestamp;
    string public currentCID;
    
    function setNewCID(string memory _newCID) external {
        require(msg.sender == owner, "Access denied!");
        currentCID = _newCID;
        updatedAt = block.timestamp;
    }
}