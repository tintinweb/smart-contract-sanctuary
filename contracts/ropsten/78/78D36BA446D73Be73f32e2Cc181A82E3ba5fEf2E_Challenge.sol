// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.3;

contract Challenge {

    mapping (bytes32 => uint256) internal _applications;

    function applyUsingEmail(bytes32 emailHash) external {
        if (_applications[emailHash] != 0) {
            revert("already applied");
        }
        _applications[emailHash] = block.timestamp;
    }

    function getApplicationID(string memory email) external view returns (uint256) {
        bytes32 emailHash = keccak256(abi.encodePacked(email));
        return _applications[emailHash];
    }
}