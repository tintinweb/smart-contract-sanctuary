/**
 *Submitted for verification at BscScan.com on 2021-10-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface PancakePredictionV2 {
    enum Position {
        Bull,
        Bear
    }

    struct Round {
        uint256 epoch;
        uint256 startTimestamp;
        uint256 lockTimestamp;
        uint256 closeTimestamp;
        int256 lockPrice;
        int256 closePrice;
        uint256 lockOracleId;
        uint256 closeOracleId;
        uint256 totalAmount;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        bool oracleCalled;
    }

    struct BetInfo {
        Position position;
        uint256 amount;
        bool claimed; // default false
    }

    function getUserRoundsLength(address) external view returns (uint256);
    function getUserRounds(address, uint256, uint256) external view returns (uint256[] memory, BetInfo[] memory, uint256);
    function ledger(uint256, address) external view returns (BetInfo memory);
    function rounds(uint256) external view returns (Round memory);
    function userRounds(address) external view returns (uint256[] memory);

}

contract botHelper {
    PancakePredictionV2 predictionContract;
    struct Round {
        uint256 epoch;
        uint256 startTimestamp;
        uint256 lockTimestamp;
        uint256 closeTimestamp;
        int256 lockPrice;
        int256 closePrice;
        uint256 lockOracleId;
        uint256 closeOracleId;
        uint256 totalAmount;
        uint256 bullAmount;
        uint256 bearAmount;
        uint256 rewardBaseCalAmount;
        uint256 rewardAmount;
        bool oracleCalled;
    }

    constructor() {
        predictionContract = PancakePredictionV2(0x18B2A687610328590Bc8F2e5fEdDe3b582A49cdA);
    }
    
    struct Result {
        uint256 rewardCnt;
        uint256 userLength;
        uint256 totalEarn;
        uint256 totalLoss;
        uint256 maxFailCnt;
    }
    
    Result public latestResult;

    function userAnalyse(address _user) public returns (uint256 rewardCnt, uint256 userLength, uint256 totalEarn, uint256 totalLoss, uint256 maxFailCnt) {

        userLength = predictionContract.getUserRoundsLength(_user);
        (uint256[] memory epochs, , ) = predictionContract.getUserRounds(_user, 0, userLength);
        uint256 failCnt = 0;
        for (uint256 index = 0; index < epochs.length; index++) {
            PancakePredictionV2.BetInfo memory prevLedger = predictionContract.ledger(epochs[index], _user);
            PancakePredictionV2.Round memory prevRound = predictionContract.rounds(epochs[index]);
            uint256 reward = 0;
            if(prevRound.rewardBaseCalAmount > 0) {
                reward = (prevLedger.amount * prevRound.rewardAmount) / prevRound.rewardBaseCalAmount;
            }
            totalLoss += prevLedger.amount;
            if(prevLedger.claimed) {
                rewardCnt++;
                failCnt = 0;
                totalEarn += reward;
            }
            else {
                failCnt++;
            }
            maxFailCnt = maxFailCnt > failCnt ? maxFailCnt : failCnt;
        }
        latestResult.rewardCnt = rewardCnt;
        latestResult.userLength = userLength;
        latestResult.totalEarn = totalEarn;
        latestResult.totalLoss = totalLoss;
        latestResult.maxFailCnt = maxFailCnt;
    }

    function getUserRounds(address user) external view returns (uint256)
    {
        uint256 length = predictionContract.getUserRoundsLength(user);

        uint256[] memory values = new uint256[](length);
        uint256 failCnt;
        uint256 maxFailCnt;
        for (uint256 i = 0; i < length; i++) {
            values[i] = predictionContract.userRounds(user)[i];
            PancakePredictionV2.BetInfo memory prevLedger = predictionContract.ledger(values[i], user);
            if(prevLedger.claimed) {
                failCnt = 0;
            }
            else {
                failCnt++;
            }
            maxFailCnt = maxFailCnt > failCnt ? maxFailCnt : failCnt;
        }
        return maxFailCnt;
    }
}