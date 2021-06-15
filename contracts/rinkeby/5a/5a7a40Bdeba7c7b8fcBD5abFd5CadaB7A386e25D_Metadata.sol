/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File contracts/helpers/strings.sol

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 */

pragma solidity ^0.5.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function memcpy(uint dest, uint src, uint len) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Returns a newly allocated string containing the concatenation of
     *      `self` and `other`.
     * @param self The first slice to concatenate.
     * @param other The second slice to concatenate.
     * @return The concatenation of the two strings.
     */
    function concat(slice memory self, slice memory other) internal pure returns (string memory) {
        string memory ret = new string(self._len + other._len);
        uint retptr;
        assembly {
            retptr := add(ret, 32)
        }
        memcpy(retptr, self._ptr, self._len);
        memcpy(retptr + self._len, other._ptr, other._len);
        return ret;
    }
}


// File contracts/Metadata.sol

/**
 * Forked from folia-app/folia-contracts: https://github.com/folia-app/folia-contracts
 * Many thanks to Billy Rennekamp <https://github.com/okwme> and Folia <https://www.folia.app/> 💚
 */

pragma solidity ^0.5.0;

/**
 * Metadata contract is upgradeable and returns metadata about Token
 */

contract Metadata {
    using strings for *;

    function tokenURI(uint256 _tokenId)
        public
        pure
        returns (string memory _infoUrl)
    {
        string memory base = "https://seeder.mutant.garden/v1/tokens/";
        string memory id = uint2str(_tokenId);
        return base.toSlice().concat(id.toSlice());
    }

    function uint2str(uint256 i) internal pure returns (string memory) {
        if (i == 0) return "0";
        uint256 j = i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length - 1;
        while (i != 0) {
            uint256 _uint = 48 + (i % 10);
            bstr[k--] = toBytes(_uint)[31];
            i /= 10;
        }
        return string(bstr);
    }

    function toBytes(uint256 x) public pure returns (bytes memory b) {
        b = new bytes(32);
        assembly {
            mstore(add(b, 32), x)
        }
    }
}