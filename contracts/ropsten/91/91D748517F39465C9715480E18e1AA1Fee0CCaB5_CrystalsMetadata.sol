// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICrystals.sol";

interface ICrystalsMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract CrystalsMetadata is Ownable, ICrystalsMetadata {
    using strings for string;
    using strings for strings.slice;

    string public description;

    address public crystalsAddress;

    uint32 private constant MAX_CRYSTALS = 10000000;
    uint32 private constant RESERVED_OFFSET = MAX_CRYSTALS - 100000; // reserved for collabs

    string private constant cursedSuffixes =
        "of Crypts,of Nightmares,of Sadness,of Darkness,of Death,of Doom,of Gloom,of Madness";
    string private constant suffixes =
        "of Power,of Giants,of Titans,of Skill,of Perfection,of Brilliance,of Enlightenment,of Protection,of Anger,of Rage,of Fury,of Vitriol,of the Fox,of Detection,of Reflection,of the Twins,of Relevance,of the Rift";
    string private constant colors =
        "Beige,Blue,Green,Red,Cyan,Yellow,Orange,Pink,Gray,White,Purple";
    string private constant specialColors =
        "Aqua,black,Crimson,Ghostwhite,Indigo,Turquoise,Maroon,Magenta,Fuchsia,Firebrick,Hotpink";
    string private constant slabs = "&#9698;,&#9699;,&#9700;,&#9701;";

    uint8 private constant presuffLength = 8;
    uint8 private constant suffixesLength = 18;
    uint8 private constant colorsLength = 11;
    uint8 private constant slabsLength = 4;

    constructor(address _crystals) Ownable() { 
        crystalsAddress = _crystals;
        description = "Unknown";
    }

    function setCrystalsAddress(address addr) public onlyOwner {
        crystalsAddress = addr;
    }

    function setDescription(string memory desc) public onlyOwner {
        description = desc;
    }

    function tokenURI(uint256 tokenId) override external view returns (string memory) {
        ICrystals crystals = ICrystals(crystalsAddress);

        require(crystals.crystalsMap(tokenId).level > 0, "INV");

        uint256 rows = tokenId / MAX_CRYSTALS + 1;

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
                ';}</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20">',
                getName(tokenId)
            )
        );

        output = string(
            abi.encodePacked(
                output,
                '</text><text x="10" y="40">Resonance: ',
                toString(crystals.getResonance(tokenId)),
                '</text><text x="10" y="60">Spin: ',
                toString(crystals.getSpin(tokenId)),
                '</text><text x="10" y="338" style="font-size: 12px;">gen.',
                toString(tokenId / MAX_CRYSTALS + 1),
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
                toString(tokenId % MAX_CRYSTALS),
                ', "description": "This crystal vibrates with energy from the Rift!", "background_color": "000000", "attributes": [{ "trait_type": "Level", "value":',
                toString(crystals.crystalsMap(tokenId).level),
                ' }, { "trait_type": "Resonance", "value": ',
                toString(crystals.getResonance(tokenId)),
                ' }, { "trait_type": "Spin", "value": '
        ));

        string memory attributes = string(
            abi.encodePacked(
                toString(crystals.getSpin(tokenId)),
                ' }, { "trait_type": "Loot Type", "value": "',
                getLootType(tokenId),
                '" }, { "trait_type": "Surface", "value": "',
                getSurfaceType(tokenId),
                '" }, { "trait_type": "Generation", "value": ',
                toString(tokenId / MAX_CRYSTALS + 1),
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

    function getLevelRolls(
        uint256 tokenId,
        string memory key,
        uint256 size,
        uint256 times
    ) internal view returns (uint256) {
        ICrystals crystals = ICrystals(crystalsAddress);

        uint256 index = 1;
        uint256 score = getRoll(tokenId, key, size, times);
        uint256 level = crystals.crystalsMap(tokenId).level;

        while (index < level) {
            score += ((
                random(string(abi.encodePacked(
                    (index * MAX_CRYSTALS) + tokenId,
                    key
                ))) % size
            ) + 1) * times;

            index++;
        }

        return score;
    }

    /// @dev returns random number based on the tokenId
    function getRandom(uint256 tokenId, string memory key)
        internal
        view
        returns (uint256)
    {
        return random(string(abi.encodePacked(tokenId, key, ICrystals(crystalsAddress).crystalsMap(tokenId).regNum)));
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
        if ((tokenId % MAX_CRYSTALS) > 8000 && (tokenId % MAX_CRYSTALS) <= RESERVED_OFFSET) {
            output = getBasicName(tokenId);
        } else {
            output = getLootName(tokenId);
        }

        return ICrystals(crystalsAddress).crystalsMap(tokenId).level > 1 ?
            string(abi.encodePacked(
                output,
                " +",
                toString(ICrystals(crystalsAddress).crystalsMap(tokenId).level - 1)
            )) : output;
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
        string memory baseName = "Crystal";

        if (tokenId % MAX_CRYSTALS > RESERVED_OFFSET) {
            baseName = string(abi.encodePacked(
                ICrystals(crystalsAddress).collabMap(uint8(((tokenId % MAX_CRYSTALS) - RESERVED_OFFSET) / 10000)).namePrefix,
                ' ',
                baseName
            ));
        }
        
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

    function getLootType(uint256 tokenId) public view returns (string memory) {
        uint256 oSeed = tokenId % MAX_CRYSTALS;
        if (oSeed > 0 && oSeed < 8001) {
            return 'Loot';
        }

        if (oSeed > RESERVED_OFFSET) {
            return ICrystals(crystalsAddress).collabMap(uint8((oSeed - RESERVED_OFFSET) / 10000)).namePrefix;
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

struct Crystal {
    bool minted;
    uint64 lastClaim;
    uint64 lastLevelUp;
    uint64 lastTransfer;
    uint64 numOfTransfers;
    uint64 level;
    uint256 manaProduced;
    uint256 regNum;
}

struct Collab {
        address contractAddress;
        string namePrefix;
        uint256 levelBonus;
    }

interface ICrystals {
    function crystalsMap(uint256 tokenID) external view returns (Crystal memory);
    function collabMap(uint256 tokenID) external view returns (Collab memory);
    function getResonance(uint256 tokenId) external view returns (uint256);
    function getSpin(uint256 tokenId) external view returns (uint256);
    function claimableMana(uint256 tokenID) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}