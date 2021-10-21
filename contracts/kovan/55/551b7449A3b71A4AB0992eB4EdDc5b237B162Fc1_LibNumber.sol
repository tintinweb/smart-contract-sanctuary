// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library LibNumber {
    function toString(uint256 self) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (self == 0) {
            return "0";
        }
        uint256 temp = self;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (self != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(self % 10)));
            self /= 10;
        }
        return string(buffer);
    }
}