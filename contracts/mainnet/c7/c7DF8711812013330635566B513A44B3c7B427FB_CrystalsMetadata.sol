// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Interfaces.sol";

// takes crystal data and shapes it for our eyes
contract CrystalsMetadata is ICrystalsMetadata {
    using strings for string;
    using strings for strings.slice;

    string public description;

    ICrystals public iCrystals;

    uint32 private constant GEN_THRESH = 10000000;
    uint32 private constant glootOffset = 9997460;
    string private constant cursedSuffixes =
        "of Nightmares,of Darkness,of Death,of Doom,of Madness,of Temptation,of the Underworld,of Corruption,of Revelation";
    string private constant suffixes =
        "of Power,of Giants,of Titans,of Skill,of Perfection,of Brilliance,of Enlightenment,of Protection,of Anger,of Rage,of Fury,of Vitriol,of the Fox,of Detection,of Reflection,of the Twins,of Relevance,of the Rift";
    string private constant colors =
        "Beige,Blue,Green,Red,Cyan,Yellow,Orange,Pink,Gray,White,Purple";
    string private constant specialColors =
        "Aqua,black,Crimson,Ghostwhite,Indigo,Turquoise,Maroon,Magenta,Fuchsia,Firebrick,Hotpink";
    string private constant slabs = "&#9698;,&#9699;,&#9700;,&#9701;";

    uint8 private constant presuffLength = 9;
    uint8 private constant suffixesLength = 18;
    uint8 private constant colorsLength = 11;
    uint8 private constant slabsLength = 4;

    constructor(address crystalsAddress) {
        description = "Mana Crystals from the Rift";
        iCrystals = ICrystals(crystalsAddress);
    }

    function tokenURI(uint256 tokenId) override external view returns (string memory) {
        require(iCrystals.crystalsMap(tokenId).focus > 0, "INV");

        uint256 rows = iCrystals.crystalsMap(tokenId).attunement;

        if (rows > 10) {
          rows = rows % 10;

          if (rows == 0) {
            rows = 10;
          }
        }

        string memory output;

        output = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>text{fill:',
                getColor(tokenId),
                ";font-family:serif;font-size:14px}.slab{transform:rotate(180deg)translate(75px, 79px);transform-origin:bottom right;font-size:",
                toString(160 / rows),
                'px;}</style><rect width="100%" height="100%" fill="',
                getBG(tokenId),
                '" /><text x="10" y="20">',
                getName(tokenId)
            )
        );

        output = string(
            abi.encodePacked(
                output,
                '</text><text x="10" y="40">Attunement: ',
                toString(iCrystals.crystalsMap(tokenId).attunement),
                '</text><text x="10" y="60">Focus: ',
                toString(iCrystals.crystalsMap(tokenId).focus),
                '</text><text x="10" y="80">Resonance: ',
                toString(iCrystals.getResonance(tokenId)),
                '</text><text x="10" y="100">Spin: ',
                toString(iCrystals.getSpin(tokenId)),
                '</text>',
                getSlabs(tokenId, rows),
                '</svg>'
            )
        );

        string memory prefix = string(
            abi.encodePacked(
                '{"id": ',
                toString(tokenId),
                ', "name": "#',
                toString(tokenId),
                '", "bagId": ',
                toString(tokenId % GEN_THRESH),
                ', "description": "This crystal vibrates with energy from the Rift!", "background_color": "000000", "attributes": [{ "trait_type": "Focus", "value":',
                toString(iCrystals.crystalsMap(tokenId).focus),
                ' }, { "trait_type": "Resonance", "value": ',
                toString(iCrystals.getResonance(tokenId)),
                ' }, { "trait_type": "Spin", "value": '
        ));

        string memory attributes = string(
            abi.encodePacked(
                toString(iCrystals.getSpin(tokenId)),
                ' }, { "trait_type": "Loot Type", "value": "',
                getLootType(tokenId),
                '" }, { "trait_type": "Surface", "value": "',
                getSurfaceType(tokenId),
                '" }, { "trait_type": "Attunement", "value": ',
                toString(iCrystals.crystalsMap(tokenId).attunement),
                ' }, { "trait_type": "Color", "value": "',
                getColor(tokenId)
        ));

        return string(
            abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(string(
                abi.encodePacked(
                    prefix,
                    attributes,
                    '" }], "image": "data:image/svg+xml;base64,',
                    Base64.encode(bytes(output)), '"}'
                )
        )))));
    }

    function getBG(uint256 tokenId) internal view returns (string memory) {
        uint256 r = 100 / uint256(iCrystals.crystalsMap(tokenId).focus);
        uint256 d = r * diffDays(iCrystals.crystalsMap(tokenId).lastClaim, block.timestamp);
        if (d < 10) {
            return "#000000";
        }
        if (d < 40) {
            return "#2C2C2C";
        }
        if (d < 60) {
            return "#686868";
        }
        if (d < 80 ) {
            return "#9F9F9F";
        }
        if (d < 95) {
            return "#DEDEDE";
        }

        return "#FFFFFF";
    }

    /// @dev returns random number based on the tokenId
    function getRandom(uint256 tokenId, string memory key)
        internal
        view
        returns (uint256)
    {
        return random(string(abi.encodePacked(
            tokenId,
            key,
            iCrystals.crystalsMap(tokenId).regNum
        )));
    }

    /// @dev returns random roll based on the tokenId
    function getRoll(
        uint256 tokenId,
        string memory key,
        uint256 size,
        uint256 times
    ) internal view returns (uint256) {
        return ((getRandom(tokenId, key) % size) + 1) * times;
    }

    function getColor(uint256 tokenId) public view returns (string memory) {
        if (getRoll(tokenId, "%CLR_RARITY", 20, 1) > 18) {
            return getItemFromCSV(
                specialColors,
                getRandom(tokenId, "%CLR") % colorsLength
            );
        }

        return getItemFromCSV(colors, getRandom(tokenId, "%CLR") % colorsLength);
    }

    function getName(uint256 tokenId) public view returns (string memory output) {
        // check original seed to determine name type
        if ((tokenId % GEN_THRESH) > 8000 && (tokenId % GEN_THRESH) <= glootOffset) {
            output = getBasicName(tokenId);
        } else {
            output = getLootName(tokenId);
        }

        return output;
    }

    function getBasicName(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        uint256 rand = getRandom(tokenId, "%NAME");
        uint256 alignment = getRoll(tokenId, "%ALIGN", 20, 1);

        string memory surface = getSurfaceType(tokenId);
        string memory suffix = "";
        string memory prefix = "";
        
        if (
            alignment == 10
            && getRoll(tokenId, "%CLR_RARITY", 20, 1) == 10
        ) {
            prefix = "Average";
        }
        
        if (alignment < 5) {
          suffix = getItemFromCSV(cursedSuffixes, rand % presuffLength);
        } else if (alignment > 15) {
          suffix = getItemFromCSV(suffixes, rand % suffixesLength);
        }

        return string(abi.encodePacked(prefix, " ", surface, " Crystal ", suffix));
    }

    function getLootName(uint256 tokenId)
        internal
        view
        returns (string memory)
    {
        uint256 rand = getRandom(tokenId, "%NAME");
        uint256 alignment = getRoll(tokenId, "%ALIGN", 20, 1);

        string memory surface = getSurfaceType(tokenId);
        string memory suffix = "";
        string memory prefix = "";
        
        if (
            alignment == 10
            && getRoll(tokenId, "%CLR_RARITY", 20, 1) == 10
        ) {
            prefix = "Perfectly Average";
        } else if (alignment == 20) {
            prefix = "Divine";
        } else if (alignment == 1) {
            prefix = "Demonic";
        }
        
        if (alignment < 5) {
          suffix = getItemFromCSV(cursedSuffixes, rand % presuffLength);
        } else if (alignment > 15) {
          suffix = getItemFromCSV(suffixes, rand % suffixesLength);
        }

        return string(abi.encodePacked(prefix, " ", surface, " Crystal ", suffix));
    }

    function getSurfaceType(uint256 tokenId)
        internal
        view
        returns (string memory) 
    {
        uint256 rand = getRandom(tokenId, "%SURFACE");
        uint256 alignment = getRoll(tokenId, "%ALIGN", 20, 1);

        if (alignment < 6) {
            return getItemFromCSV("Broken,Twisted,Cracked,Fragmented,Splintered,Beaten,Ruined", rand % 7);
        } else if (alignment > 15) {
            return getItemFromCSV("Gleaming,Glowing,Shiny,Luminous,Radiant,Brilliant", rand % 6);
        } else {
            return getItemFromCSV("Dull,Smooth,Faceted,Glassy,Polished,", rand % 5);
        }
    }

    function getSlabs(uint256 tokenId) external view returns (string memory output) {
        uint256 rows = iCrystals.crystalsMap(tokenId).attunement;

        if (rows > 10) {
          rows = rows % 10;

          if (rows == 0) {
            rows = 10;
          }
        }

        output = '';

        for (uint256 i = 0; i < rows; i++) {
            for (uint256 j = 0; j < rows; j++) {
                output = string(abi.encodePacked(output, getSlab(tokenId, i, j)));
            }
            output = string(abi.encodePacked(output, '\n'));
        }

        return output;
    }

    function getSlabs(uint256 tokenId, uint256 rows) private view returns (string memory output) {
        output = '';

        for (uint256 i = 0; i < rows; i++) {
            output = string(
                abi.encodePacked(
                    output,
                    '<text class="slab" x="285" y="',
                    toString((415 + (rows * 4)) - (160 / rows * i)),
                    '">'
            ));

            for (uint256 j = 0; j < rows; j++) {
                output = string(abi.encodePacked(output, getSlab(tokenId, i, j)));
            }

            output = string(abi.encodePacked(output, '</text>'));
        }

        return output;
    }

    function getSlab(uint256 tokenId, uint256 x, uint256 y) internal view returns (string memory output) {
        output = getItemFromCSV(
                        slabs,
                        getRandom(
                            tokenId,
                            string(abi.encodePacked("SLAB_", toString(x), "_", toString(y)))
                        ) % slabsLength
                    );

        return output;
    }

    function getLootType(uint256 tokenId) public pure returns (string memory) {
        uint256 oSeed = tokenId % GEN_THRESH;
        if (oSeed > 0 && oSeed < 8001) {
            return 'Loot';
        }

        if (oSeed > glootOffset) {
            return 'gLoot';
        }

        return 'mLoot';
    }

    function getItemFromCSV(string memory str, uint256 index)
        internal
        pure
        returns (string memory)
    {
        strings.slice memory strSlice = str.toSlice();
        string memory separatorStr = ",";
        strings.slice memory separator = separatorStr.toSlice();
        strings.slice memory item;
        for (uint256 i = 0; i <= index; i++) {
            item = strSlice.split(separator);
        }
        return item.toString();
    }

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input, "%RIFT-OPEN")));
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256)
    {
        require(fromTimestamp <= toTimestamp);
        return (toTimestamp - fromTimestamp) / (24 * 60 * 60);
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

    function toHexString(uint i) internal pure returns (string memory) {
        // https://stackoverflow.com/a/69302348/424107
        
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0) {
            length++;
            j = j >> 4;
        }
        uint mask = 15;
        bytes memory bstr = new bytes(length);
        uint k = length;
        while (i != 0) {
            uint curr = (i & mask);
            bstr[--k] = curr > 9 ?
                bytes1(uint8(55 + curr)) :
                bytes1(uint8(48 + curr)); // 55 = 65 - 10
            i = i >> 4;
        }
        return string(bstr);
    }
}

/// @notice Calculates the square root of x, rounding down.
/// @dev Uses the Babylonian method https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method.
/// @param x The uint256 number for which to calculate the square root.
/// @return result The result as an uint256.
function sqrt(uint256 x) pure returns (uint256 result) {
    if (x == 0) {
        return 0;
    }

    // Calculate the square root of the perfect square of a power of two that is the closest to x.
    uint256 xAux = uint256(x);
    result = 1;
    if (xAux >= 0x100000000000000000000000000000000) {
        xAux >>= 128;
        result <<= 64;
    }
    if (xAux >= 0x10000000000000000) {
        xAux >>= 64;
        result <<= 32;
    }
    if (xAux >= 0x100000000) {
        xAux >>= 32;
        result <<= 16;
    }
    if (xAux >= 0x10000) {
        xAux >>= 16;
        result <<= 8;
    }
    if (xAux >= 0x100) {
        xAux >>= 8;
        result <<= 4;
    }
    if (xAux >= 0x10) {
        xAux >>= 4;
        result <<= 2;
    }
    if (xAux >= 0x8) {
        result <<= 1;
    }

    // The operations can never overflow because the result is max 2^127 when it enters this block.
    unchecked {
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1;
        result = (result + x / result) >> 1; // Seven iterations should be enough
        uint256 roundedDownResult = x / result;
        return result >= roundedDownResult ? roundedDownResult : result;
    }
}

library strings {
    struct slice {
        uint256 _len;
        uint256 _ptr;
    }

    function memcpy(
        uint256 dest,
        uint256 src,
        uint256 len
    ) private pure {
        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint256 mask = 256**(32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function toSlice(string memory self) internal pure returns (slice memory) {
        uint256 ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    function findPtr(
        uint256 selflen,
        uint256 selfptr,
        uint256 needlelen,
        uint256 needleptr
    ) private pure returns (uint256) {
        uint256 ptr = selfptr;
        uint256 idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly {
                    needledata := and(mload(needleptr), mask)
                }

                uint256 end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly {
                    ptrdata := and(mload(ptr), mask)
                }

                while (ptrdata != needledata) {
                    if (ptr >= end) return selfptr + selflen;
                    ptr++;
                    assembly {
                        ptrdata := and(mload(ptr), mask)
                    }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly {
                    hash := keccak256(needleptr, needlelen)
                }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly {
                        testHash := keccak256(ptr, needlelen)
                    }
                    if (hash == testHash) return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    function split(
        slice memory self,
        slice memory needle,
        slice memory token
    ) internal pure returns (slice memory) {
        uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    function split(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory token)
    {
        split(self, needle, token);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

struct Bag {
    uint64 totalManaProduced;
    uint64 mintCount;
}

struct Crystal {
    uint16 attunement;
    uint64 lastClaim;
    uint16 focus;
    uint32 focusManaProduced;
    uint32 regNum;
    uint16 lvlClaims;
}

interface ICrystalsMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface ICrystals {
    function crystalsMap(uint256 tokenID) external view returns (Crystal memory);
    function bags(uint256 tokenID) external view returns (Bag memory);
    function getResonance(uint256 tokenId) external view returns (uint32);
    function getSpin(uint256 tokenId) external view returns (uint32);
    function claimableMana(uint256 tokenID) external view returns (uint32);
    function availableClaims(uint256 tokenId) external view returns (uint8);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}