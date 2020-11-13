// SPDX-License-Identifier: MIT

pragma solidity ^0.6.7;

interface Proxy {
    function execute(
        address to,
        uint256 value,
        bytes calldata data
    ) external returns (bool, bytes memory);

    function increaseAmount(uint256) external;
}
