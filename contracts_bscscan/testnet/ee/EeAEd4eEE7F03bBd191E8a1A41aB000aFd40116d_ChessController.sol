/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

// Sources flattened with hardhat v2.1.1 https://hardhat.org

// File contracts/governance/ChessController.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.10 <0.8.0;

contract ChessController {
    /// @notice Get Fund relative weight (not more than 1.0) normalized to 1e18
    ///         (e.g. 1.0 == 1e18).
    /// @return relativeWeight Value of relative weight normalized to 1e18
    function getFundRelativeWeight(
        address, /*account*/
        uint256 /*timestamp*/
    ) external pure returns (uint256 relativeWeight) {
        relativeWeight = 1e18;
    }
}