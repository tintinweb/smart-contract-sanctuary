// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Structs {
    struct Vote {
        uint32 epoch;
        uint48[] values;
    }

    struct Commitment {
        uint32 epoch;
        bytes32 commitmentHash;
    }
    struct Staker {
        bool acceptDelegation;
        uint8 commission;
        address _address;
        address tokenAddress;
        uint32 id;
        uint32 age;
        uint32 epochFirstStakedOrLastPenalized;
        uint256 stake;
    }

    struct Lock {
        uint256 amount; //amount in RZR
        uint256 commission;
        uint256 withdrawAfter;
    }

    struct BountyLock {
        address bountyHunter;
        uint256 amount; //amount in RZR
        uint256 redeemAfter;
    }

    struct Block {
        uint32 proposerId;
        uint32[] medians;
        uint256 iteration;
        uint256 biggestInfluence;
        bool valid;
    }

    struct Dispute {
        uint8 assetId;
        uint32 lastVisitedStaker;
        uint256 accWeight;
        uint256 accProd;
        // uint32 median;
    }

    struct Job {
        uint8 id;
        uint8 selectorType; // 0-1
        uint8 weight; // 1-100
        int8 power;
        string name;
        string selector;
        string url;
    }

    struct Collection {
        bool active;
        uint8 id;
        uint8 assetIndex;
        int8 power;
        uint32 aggregationMethod;
        uint8[] jobIDs;
        string name;
    }
}