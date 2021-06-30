/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.23;

interface IGauge {
    function claimable_tokens(address) external view returns (uint256);
}

contract CurveClaimableTokensHelper {
    function claimable_tokens(address gauge_address, address voter_address) public view returns (uint256) {
        IGauge gauge = IGauge(gauge_address);
        return gauge.claimable_tokens(voter_address);
    }
}