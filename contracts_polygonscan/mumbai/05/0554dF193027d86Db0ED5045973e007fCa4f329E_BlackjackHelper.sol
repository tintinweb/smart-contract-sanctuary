// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract BlackjackHelper {
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