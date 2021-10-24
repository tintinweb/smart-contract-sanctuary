/**
 *Submitted for verification at polygonscan.com on 2021-10-23
*/

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

contract Encode {
    function encode(
            address[] memory _summoner,
            uint256[] memory _summonerShares,
            uint256[] memory _summonerLoot,
            address[] memory _approvedTokens,
            uint256 _periodDuration,
            uint256 _votingPeriodLength,
            uint256 _gracePeriodLength,
            uint256 _proposalDeposit,
            uint256 _dilutionBound,
            uint256 _processingReward,
            string memory _details
        ) public pure returns (bytes memory data) {
        data = abi.encode(
            _summoner,
            _summonerShares,
            _summonerLoot,
            _approvedTokens,
            _periodDuration,
            _votingPeriodLength,
            _gracePeriodLength,
            _proposalDeposit,
            _dilutionBound,
            _processingReward,
            _details
        );
    }
}