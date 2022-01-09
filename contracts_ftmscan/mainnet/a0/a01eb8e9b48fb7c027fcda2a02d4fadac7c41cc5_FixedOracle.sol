/**
 *Submitted for verification at FtmScan.com on 2022-01-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;


contract FixedOracle {
    function decimals() public pure returns (uint8) {
        return 8;
    }

    function latestRoundData() public view
        returns
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 timestamp,
            uint80 answeredInRound
        )
    {
        roundId = 5;
        answer = 1e8;
        startedAt = now;
        timestamp = now;
        answeredInRound = 5;
   }
}