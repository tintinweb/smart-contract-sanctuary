/**
 *Submitted for verification at Etherscan.io on 2021-09-04
*/

// SPDX-License-Identifier: AGPL V3.0

pragma solidity 0.8.0;



// Part: IPowerCalculator

interface IPowerCalculator {
    function calculatePower(uint256 weaponId) external returns (uint256);
}

// File: PowerCalculatorV0.sol

contract PowerCalculatorV0 is IPowerCalculator {
    function calculatePower(uint256 weaponId)
        external
        pure
        override
        returns (uint256)
    {
        // get the actual weapon class and greatness
        uint256 rand = random(
            string(abi.encodePacked("WEAPON", toString(weaponId)))
        );
        uint256 greatness = rand % 21;
        return greatness * 100;
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}