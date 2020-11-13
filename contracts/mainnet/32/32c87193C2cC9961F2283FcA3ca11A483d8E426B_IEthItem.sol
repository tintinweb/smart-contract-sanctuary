// SPDX-License-Identifier: MIT

pragma solidity ^0.7.4;

interface IEthItem {

    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    function burnBatch(
        uint256[] calldata objectIds,
        uint256[] calldata amounts
    ) external;
}