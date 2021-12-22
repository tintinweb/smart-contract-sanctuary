// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

contract TokenMinter {
    function allocateFrom(address token, uint256 value) external {
        ICompToken(token).allocateTo(msg.sender, value);
    }
}

interface ICompToken {
    function allocateTo(address ownerAddress, uint256 value) external;
}