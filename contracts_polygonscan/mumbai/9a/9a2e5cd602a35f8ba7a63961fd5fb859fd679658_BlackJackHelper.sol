/**
 *Submitted for verification at polygonscan.com on 2021-08-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract BlackJackHelper {
    mapping(uint8 => bool) public isHashUsed;

    bytes32[100] public hashChilds;

    function verifyHash(uint8 _index, uint256 _hashParent)
        public
        view
        returns (bool)
    {
        return keccak256(abi.encodePacked(_hashParent)) == hashChilds[_index];
    }

    function updateHash(uint8 _index, bytes32 _newHashChild) external {
        isHashUsed[_index] = false;
        hashChilds[_index] = _newHashChild;
    }

    function updateHashes(uint8[] memory _indices, bytes32[] memory _newHashes)
        external
    {
        for (uint256 i = 0; i < _indices.length; i++) {
            isHashUsed[_indices[i]] = false;
            hashChilds[_indices[i]] = _newHashes[i];
        }
    }

    // function getCardPower(uint8 _card) public pure returns (uint8 cardPower) {
    //     uint8[13] memory cardsPower = [
    //         11,
    //         2,
    //         3,
    //         4,
    //         5,
    //         6,
    //         7,
    //         8,
    //         9,
    //         10,
    //         10,
    //         10,
    //         10
    //     ];
    //     return cardsPower[_card % 13];
    // }

    function getCardPower(uint8 _card) public pure returns (uint8) {
        bytes13 cardsPower = "\x0B\x02\x03\x04\x05\x06\x07\x08\x09\x0A\x0A\x0A\x0A";
        return uint8(cardsPower[_card % 13]);
    }

    function getHandPower(uint8[] memory _cards)
        public
        pure
        returns (uint8 powerMax)
    {
        uint8 aces;
        uint8 power;

        for (uint8 i = 0; i < _cards.length; i++) {
            power = getCardPower(_cards[i]);
            powerMax += power;
            if (power == 11) {
                aces += 1;
            }
        }
        if (powerMax > 21) {
            for (uint8 i = 0; i < aces; i++) {
                powerMax -= 10;
                if (powerMax <= 21) {
                    break;
                }
            }
        }
    }
}