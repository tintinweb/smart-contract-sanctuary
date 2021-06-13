// SPDX-License-Identifier: MIT
// Degen'$ Farm: Collectible NFT game (https://degens.farm)
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

import "./DegensFarmBase.sol";

contract DegenFarm is DegenFarmBase {

    uint8   constant public CREATURE_TYPE_COUNT= 20;  // how much creatures types may be used
    uint256 constant public FARMING_DURATION   = 168 hours;
    uint256 constant public TOOL_UNSTAKE_DELAY = 1 weeks;
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

        // Mainnet amulet addresses
        amulets[0]  = 0xD533a949740bb3306d119CC777fa900bA034cd52; // Cow    $CRV
        amulets[1]  = 0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984; // Horse  $UNI
        amulets[2]  = 0xfA5047c9c78B8877af97BDcb85Db743fD7313d4a; // Rabbit $ROOK
        amulets[3]  = 0xDADA00A9C23390112D08a1377cc59f7d03D9df55; // Chicken $DUNG
        amulets[4]  = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2; // Pig    $SUSHI
        amulets[5]  = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF; // Cat    $BAT
        amulets[6]  = 0x3472A5A71965499acd81997a54BBA8D852C6E53d; // Dog	$BADGER
        amulets[7]  = 0x0d438F3b5175Bebc262bF23753C1E53d03432bDE; // Goose	$WNXM
        amulets[8]  = 0x3155BA85D5F96b2d030a4966AF206230e46849cb; // Goat	$RUNE
        amulets[9]  = 0x7Fc66500c84A76Ad7e9c93437bFc5Ac33E2DDaE9; // Sheep	$AAVE
        amulets[10] = 0xC011a73ee8576Fb46F5E1c5751cA3B9Fe0af2a6F; // Snake	$SNX
        amulets[11] = 0x967da4048cD07aB37855c090aAF366e4ce1b9F48; // Fish	$OCEAN
        amulets[12] = 0x0F5D2fB29fb7d3CFeE444a200298f468908cC942; // Frog	$MANA
        amulets[13] = 0x514910771AF9Ca656af840dff83E8264EcF986CA; // Worm	$LINK
        amulets[14] = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32; // Lama	$LDO
        amulets[15] = 0x1F573D6Fb3F13d689FF844B4cE37794d79a7FF1C; // Mouse	$BNT
        amulets[16] = 0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2; // Camel	$MKR
        amulets[17] = 0x111111111117dC0aa78b770fA6A738034120C302; // Donkey	$1INCH
        amulets[18] = 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e; // Bee	$YFI
        amulets[19] = 0xc00e94Cb662C3520282E6f5717214004A7f26888; // Duck	$COMP
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