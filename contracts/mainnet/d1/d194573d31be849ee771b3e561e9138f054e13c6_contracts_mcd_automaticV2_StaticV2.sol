pragma solidity ^0.6.0;

/// @title Implements enum Method
abstract contract StaticV2 {

    enum Method { Boost, Repay }

    struct CdpHolder {
        uint128 minRatio;
        uint128 maxRatio;
        uint128 optimalRatioBoost;
        uint128 optimalRatioRepay;
        address owner;
        uint cdpId;
        bool boostEnabled;
        bool nextPriceEnabled;
    }

    struct SubPosition {
        uint arrPos;
        bool subscribed;
    }
}
