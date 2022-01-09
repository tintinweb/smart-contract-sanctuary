// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

library LibHelper {
    uint256 constant MAX_QUALITY = 5;
    uint256 constant MAX_QUALITY_BURNABLE = 2;
    uint256 constant CLEAR_QUALITY_MASK = ~(uint256(0xffff) << 240);
    uint256 constant CLEAR_ROLE_MASK = ~(uint256(0xffff) << 224);

    function getQualityTrait(uint256 numericTrait)
        internal
        pure
        returns (uint16)
    {
        return uint16(numericTrait >> 240);
    }

    function getRoleTrait(uint256 numericTrait) internal pure returns (uint16) {
        return uint16(numericTrait >> 224);
    }

    function getTraits(uint256 numericTrait)
        internal
        pure
        returns (uint16 role, uint16 quality)
    {
        role = getRoleTrait(numericTrait);
        quality = getQualityTrait(numericTrait);
    }

    function setQualityTrait(uint256 numericTrait, uint16 typeId)
        internal
        pure
        returns (uint256)
    {
        return (uint256(typeId) << 240) | (numericTrait & CLEAR_QUALITY_MASK);
    }

    function setRoleTrait(uint256 numericTrait, uint16 level)
        internal
        pure
        returns (uint256)
    {
        return (uint256(level) << 224) | (numericTrait & CLEAR_ROLE_MASK);
    }

    function getBurnReward(uint256 quality) external pure returns (uint256) {
        if (quality == 1) {
            return 7 ether;
        } else if (quality == 2) {
            return 21 ether;
        }
        return 0;
    }
}