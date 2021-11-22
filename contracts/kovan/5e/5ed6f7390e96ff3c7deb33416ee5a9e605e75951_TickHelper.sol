// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// Unicrypt by SDDTech reserves all rights on this code. You may NOT copy these contracts.

pragma solidity >=0.8.3;

import "./Ownable.sol";

contract TickHelper is Ownable {

    int24 maxTickValue = 887272;

    struct FeeAmount {
        uint24 LOW;
        uint24 MEDIUM;
        uint24 HIGH;
    }

    mapping(uint24 => uint24) public tick_spacings;

    FeeAmount public fees;

    event UpdatedTickSpace(uint24 fee, uint24 tickSpace);

    constructor() {
        fees = FeeAmount(500,3000,10000); 
        tick_spacings[fees.LOW] = 10;
        tick_spacings[fees.MEDIUM] = 60;
        tick_spacings[fees.HIGH] = 200;
        emit UpdatedTickSpace(fees.LOW, 10);
        emit UpdatedTickSpace(fees.MEDIUM, 60);
        emit UpdatedTickSpace(fees.HIGH, 200);
    }

    function ceil(int24 a, int24 m) internal pure returns (int24) {
        return (a + m - 1) / m;
    }

    /// @notice Returns the max tick for a given fee amount
    /// @param fee the fee used in the pool
    /// @return maxTick The tick spacing
    function getMaxTick(uint24 fee) external view returns(int24 maxTick) {
       int24 tickSpacing = int24(tick_spacings[fee]);  
       maxTick = tickSpacing * (maxTickValue / tickSpacing);    
    }

    /// @notice Returns the min tick for a given fee amount
    /// @param fee the fee used in the pool
    /// @return minTick The tick spacing
    function getMinTick(uint24 fee) external view returns(int24 minTick) {
       int24 tickSpacing = int24(tick_spacings[fee]);  
       int24 maxTick = tickSpacing * (maxTickValue / tickSpacing); 
       minTick = -maxTick;
    }

    /// @notice Sets a new fee and tickSpace for that fee. Only Owner can call
    /// Should only be used when uniswap v3 adds new fees
    /// @param fee the new fee to be added.
    /// @param tickSpace the new ticks space related to the fee
    function setTickSpace(uint24 fee, uint24 tickSpace) external onlyOwner {
        tick_spacings[fee] = tickSpace;
        emit UpdatedTickSpace(fee, tickSpace);
    }
}