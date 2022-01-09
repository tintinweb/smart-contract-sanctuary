/**
 *Submitted for verification at Etherscan.io on 2022-01-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/// @title A minimalist service for posting messages.
/// @author Cyril Kato
/// @notice This contract could be used for microblogging.
contract Log {
    address private immutable OWNER_ADDR;

    event Post(string message);

    modifier onlyOwner() {
        require(isOwner(), "Not owner");

        _;
    }

    constructor() {
        OWNER_ADDR = msg.sender;
    }

    /// @notice Post a message.
    /// @dev IPFS CIDs may be posted.
    /// @param _message The message to post.
    function post(string memory _message) external onlyOwner() {
        emit Post(_message);
    }

    function isOwner() private view returns (bool) {
        return msg.sender == OWNER_ADDR;
    }
}