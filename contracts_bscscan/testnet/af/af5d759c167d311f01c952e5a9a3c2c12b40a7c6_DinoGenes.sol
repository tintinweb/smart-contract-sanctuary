/**
 *Submitted for verification at BscScan.com on 2022-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract DinoGenes {
    constructor() {

    }
    event GenesGenerated(uint256 genes);
    event TraitsGenerated(uint8[] traits);
    uint256[] public rates = [5000, 7500, 9000, 9700, 10000];
    uint256[] public maxTraits = [3, 3, 2, 1, 1];
    
    function calculateTraitIndex(uint256 _rarity, uint256 _rand) public view returns(uint256 traitIndex) {
        uint256 maxTraitByRarity = maxTraits[_rarity - 1];
        traitIndex = _rand % maxTraitByRarity;
        for(uint256 i = 0; i < _rarity - 1; i ++) {
            traitIndex += maxTraits[i];
        }
    }

    function calculateRarity(uint256 _rand) public view returns(uint256 rarity) {
        uint256 rand = uint256(_rand) % 10000;
        uint i = 0;
        while (rates[i] < rand && i < rates.length) {
            i++;
        }
        return i + 1;
    }

    /// @dev Slice _nbits bits from _offset of _n, also can use to get random number as well
    function _sliceNumber(uint256 _n, uint256 _nbits, uint256 _offset) private pure returns (uint256) {
        uint256 mask = uint256((2**_nbits) - 1) << _offset;
        return uint256((_n & mask) >> _offset);
    }
    /// @dev Slice and return 4 bits from _slot
    function _get4Bits(uint256 _input, uint256 _slot) internal pure returns(uint8) {
        return uint8(_sliceNumber(_input, uint256(4), _slot * 4));
    }

    /// @dev Decode dino genes to uint8 array, we have 21 group and 4 bit per group
    function decodeDino(uint256 _genes) public pure returns(uint8[] memory) {
        uint8[] memory traits = new uint8[](21);
        uint256 i;
        for(i = 0; i < 21; i++) {
            traits[i] = _get4Bits(_genes, i);
        }
        return traits;
    }

    /// @dev Encode dino traits array to uint256 genes
    function encodeDino(uint8[] memory _traits) public pure returns (uint256 _genes) {
        _genes = 0;
        for(uint256 i = 0; i < 21; i++) {
            _genes = _genes << 4;
            // bitwise OR trait with _genes
            _genes = _genes | _traits[20 - i];
        }
        return _genes;
    }
    /// @dev Random dino genes
    function generateGenes(uint256 _block) public returns (uint256 genes) {
        uint8[] memory traits = new uint8[](21);
        uint256 rand = uint256(blockhash(_block));
        uint256 randomIndex;
        for(uint256 i = 0; i < 21; i ++) {
            if(i % 3 == 0) {
                uint256 rarity = calculateRarity(rand);
                rand = rand + _sliceNumber(rand, 3, randomIndex) * 500;
                if(rarity <= 3) randomIndex += 3;
                randomIndex += 2;
                traits[i] = uint8(calculateTraitIndex(rarity, rand));

                if(i == 0) {
                    traits[i] = traits[i] % 3;
                    traits[i + 1] = uint8(calculateTraitIndex(rarity, rand)) % 3;
                    traits[i + 2] = uint8(calculateTraitIndex(rarity, rand)) % 3;
                } else {
                    uint256 rand1 = _sliceNumber(rand, 2, randomIndex);
                    randomIndex += 2;
                    uint256 recessiveTrait1Rarity = rarity;
                    if(rand1 == 0) {
                        recessiveTrait1Rarity = calculateRarity(uint256(rand + block.number));
                    }
                    traits[i + 1] = uint8(calculateTraitIndex(recessiveTrait1Rarity, rand1));
                    randomIndex += 2;
                    uint256 rand2 = _sliceNumber(rand, 2, randomIndex);
                    uint256 recessiveTrait2Rarity = recessiveTrait1Rarity;
                    if(rand1 == 0) {
                        recessiveTrait2Rarity = calculateRarity(uint256(rand + rand1));
                    }
                    traits[i + 2] = uint8(calculateTraitIndex(recessiveTrait2Rarity, rand2));
                }
                
            }
        }
        emit GenesGenerated(encodeDino(traits));
        return encodeDino(traits);
    }
}