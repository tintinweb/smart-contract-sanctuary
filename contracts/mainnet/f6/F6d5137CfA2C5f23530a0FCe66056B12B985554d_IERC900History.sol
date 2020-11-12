// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.0;


// Minimum interface to interact with Aragon's Aggregator
interface IERC900History {
    function totalStakedForAt(address addr, uint256 blockNumber) external view returns (uint256);
    function totalStakedAt(uint256 blockNumber) external view returns (uint256);
    function supportsHistory() external pure returns (bool);
}
