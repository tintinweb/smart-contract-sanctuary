// SPDX-License-Identifier: MIT
// Degen'$ Farm: Collectible NFT game (https://degens.farm)
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./DegensFarmBase.sol";

contract DegenFarmLite is DegenFarmBase {

    uint8   constant public CREATURE_TYPE_COUNT= 2;  //how much creatures types may be used
    uint256 constant public FARMING_DURATION   = 168 seconds; //in seconds
    //uint256 constant public NEXT_FARMING_DELAY = 1   minutes;
    uint256 constant public TOOL_UNSTAKE_DELAY = 1   minutes;
    uint256 constant public REVEAL_THRESHOLD   = 0;    //90% from MAX_BAGS
    uint16   constant public NORMIE_COUNT_IN_TYPE = 20;
    uint16   constant public CHAD_COUNT_IN_TYPE = 5;
    uint16   constant public MAX_LANDS = 100;

    constructor (
        address _land,
        address _creatures,
        address _inventory,
        address _bagstoken,
        address _dungtoken,
        IEggs _eggs
    )
        DegenFarmBase(_land, _creatures, _inventory, _bagstoken, _dungtoken, _eggs)
    {
        require(CREATURE_TYPE_COUNT <= CREATURE_TYPE_COUNT_MAX, "CREATURE_TYPE_COUNT is greater than CREATURE_TYPE_COUNT_MAX");

        // Rinkeby amulet addrresses
        amulets[0] = [0xD533a949740bb3306d119CC777fa900bA034cd52, 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C];
        amulets[1] = [0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984, 0x111111111117dC0aa78b770fA6A738034120C302];
    }

    function getCreatureTypeCount() override internal view returns (uint16) {
        return CREATURE_TYPE_COUNT;
    }

    function getFarmingDuration() override internal view returns (uint) {
        return FARMING_DURATION;
    }

    function getNormieCountInType() override internal view returns (uint16) {
        return NORMIE_COUNT_IN_TYPE;
    }

    function getChadCountInType() override internal view returns (uint16) {
        return CHAD_COUNT_IN_TYPE;
    }

    function getMaxLands() override internal view returns (uint16) {
        return MAX_LANDS;
    }

    function getToolUnstakeDelay() override internal view returns (uint) {
        return TOOL_UNSTAKE_DELAY;
    }

}