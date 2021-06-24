// SPDX-License-Identifier: MIT
// Degen'$ Farm: Collectible NFT game (https://degens.farm)
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./DegensFarmBase.sol";

contract DegenFarmLite is DegenFarmBase {

    uint8   constant public CREATURE_TYPE_COUNT= 3;  //how much creatures types may be used
    uint256 constant public FARMING_DURATION   = 10 seconds; //in seconds
    uint256 constant public TOOL_UNSTAKE_DELAY = 10 minutes;
    uint16  constant public NORMIE_COUNT_IN_TYPE = 100;
    uint16  constant public CHAD_COUNT_IN_TYPE = 20;
    uint16  constant public MAX_LANDS = 2500;

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

        // Rinkeby amulet addresses
        amulets[0] = 0xD533a949740bb3306d119CC777fa900bA034cd52;
        amulets[1] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
        amulets[2] = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984;
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