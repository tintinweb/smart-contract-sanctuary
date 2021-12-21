// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library LibString {
    using LibString for string;

    function length(string memory self) internal pure returns (uint256) {
        return bytes(self).length;
    }

    function toBytes32(string memory self)
        internal
        pure
        returns (bytes32 result)
    {
        require(self.length() <= 32, "Length must be lower than 32");
        assembly {
            result := mload(add(self, 32))
        }
    }
}