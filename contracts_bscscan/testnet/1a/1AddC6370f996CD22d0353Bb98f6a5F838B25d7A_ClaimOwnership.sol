// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ClaimOwnership {
    address public owner;

    bool private isInitialized;

    constructor() {}

    function init() external {
        require(!isInitialized, "ClaimOwnership: Initialized");

        owner = msg.sender;
    }

    function changeOwnership(address newOwner) external {
        address _ownerOld = owner;

        require(msg.sender == _ownerOld, "ClaimOwnership: Not allowed");
        require(newOwner != _ownerOld, "ClaimOwnership: Diff");

        owner = newOwner;
    }
}

