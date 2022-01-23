// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./libraries/BytesUtils.sol";

contract TokenRangeVerifier {
    using BytesUtils for bytes;

    function verify(uint256 startTokenId, uint256 endTokenId) public pure {
        uint256 tokenId = abi.decode(msg.data.slice(136, 32), (uint256));
        require(
            startTokenId <= tokenId && tokenId <= endTokenId,
            "Invalid token id"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Inspired from the Wyvern V3 source code:
// https://github.com/wyvernprotocol/wyvern-v3/blob/1d89d6a91faddf3c3494e6ebdcb07b46fe111fb4/contracts/lib/ArrayUtils.sol

library BytesUtils {
    function drop(bytes memory array, uint256 start)
        public
        pure
        returns (bytes memory result)
    {
        result = slice(array, start, array.length - start);
    }

    function slice(
        bytes memory array,
        uint256 start,
        uint256 length
    ) public pure returns (bytes memory result) {
        assembly {
            switch iszero(length)
            case 0 {
                // Get a location of some free memory and store it in `result`
                result := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthMod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthMod := and(length, 31)

                // The multiplication in the next line is necessary because when
                // slicing multiples of 32 bytes (`lengthMod == 0`) the following
                // copy loop was copying the origin's length and then ending in a
                // premature way not copying everything it should.
                let mc := add(
                    add(result, lengthMod),
                    mul(0x20, iszero(lengthMod))
                )
                let end := add(mc, length)

                for {
                    // The multiplication below has the same exact purpose as the one above
                    let cc := add(
                        add(
                            add(array, lengthMod),
                            mul(0x20, iszero(lengthMod))
                        ),
                        start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(result, length)

                // Update free-memory pointer, allocating the array padded to 32 bytes
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            // If we want a zero-length slice then simply return a zero-length array
            default {
                result := mload(0x40)

                mstore(0x40, add(result, 0x20))
            }
        }
    }
}