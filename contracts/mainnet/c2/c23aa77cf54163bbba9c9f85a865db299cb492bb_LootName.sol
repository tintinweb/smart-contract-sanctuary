/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-05
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

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

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint256 ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint256 retptr;
        assembly {
            retptr := add(ret, 32)
        }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
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

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
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

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle)
        internal
        pure
        returns (slice memory token)
    {
        split(self, needle, token);
    }
}

contract LootName {
    using strings for string;
    using strings for strings.slice;

    string private constant firstNames =
        "Satoshi,Vitalik,Vlad,Adam,Ailmar,Darfin,Jhaan,Zabbas,Neldor,Gandor,Bellas,Daealla,Derek,Nym,Vesryn,Angor,Gogu,Malok,Rotnam,Chalia,Astra,Fabien,Orion,Quintus,Remus,Rorik,Sirius,Sybella,Azura,Dorath,Freya,Ophelia,Yvanna,Zeniya,James,Robert,John,Michael,William,David,Richard,Joseph,Thomas,Charles,Mary,Patricia,Jennifer,Linda,Elizabeth,Barbara,Susan,Jessica,Sarah,Karen,Dilibe,Eva,Matthew,Bolethe,Polycarp,Ambrogino,Jiri,Chukwuebuka,Chinonyelum,Mikael,Mira,Aniela,Samuel,Isak,Archibaldo,Chinyelu,Kerstin,Abigail,Olympia,Grace,Nahum,Elisabeth,Serge,Sugako,Patrick,Florus,Svatava,Ilona,Lachlan,Caspian,Filippa,Paulo,Darda,Linda,Gradasso,Carly,Jens,Betty,Ebony,Dennis,Martin Davorin,Laura,Jesper,Remy,Onyekachukwu,Jan,Dioscoro,Hilarij,Rosvita,Noah,Patrick,Mohammed,Chinwemma,Raff,Aron,Miguel,Dzemail,Gawel,Gustave,Efraim,Adelbert,Jody,Mackenzie,Victoria,Selam,Jenci,Ulrich,Chishou,Domonkos,Stanislaus,Fortinbras,George,Daniel,Annabelle,Shunichi,Bogdan,Anastazja,Marcus,Monica,Martin,Yuukou,Harriet,Geoffrey,Jonas,Dennis,Hana,Abdelhak,Ravil,Patrick,Karl,Eve,Csilla,Isabella,Radim,Thomas,Faina,Rasmus,Alma,Charles,Chad,Zefram,Hayden,Joseph,Andre,Irene,Molly,Cindy,Su,Stani,Ed,Janet,Cathy,Kyle,Zaki,Belle,Bella,Amou,Steven,Olgu,Eva,Ivan,Vllad,Helga,Anya,John,Rita,Evan,Jason,Donald,Tyler,Changpeng,Sam";
    uint256 private constant firstNamesLength = 186;

    string private constant lastNames =
        "Nakamoto,Buterin,Zamfir,Mintz,Ashbluff,Marblemaw,Bozzelli,Fellowes,Windward,Yarrow,Yearwood,Wixx,Humblecut,Dustfinger,Biddercombe,Kicklighter,Vespertine,October,Gannon,Collymore,Stoll,Adler,Huxley,Ledger,Hayes,Ford,Finnegan,Beckett,Zimmerman,Crassus,Hendrix,Lennon,Thatcher,St. James,Cromwell,Monroe,West,Langley,Cassidy,Lopez,Jenkins,Udobata,Valova,Gresham,Frederiksen,Vasiliev,Mancini,Danicek,Okwuoma,Chibugo,Broberg,Strozak,Borkowska,Araujo,Geisler,Hidalgo,Ibekwe,Schmidt,Leehy,Rodrigue,Hines,Izmaylov,Egede,Pinette,Hakugi,McLellan,Mailhot,Lelkova,Simon,Tjangamarra,Sandgreen,Nystrom,Kjeldsen,Goncalves,Sos,Hornblower,Pelletier,Donaldson,Jackson,Rojo,Ermakov,Stornik,Lothran,Gousse,Henrichon,Onwuka,Horak,Elizondo,Mikulanc,Skotnik,Berg,Nilsson,Berg,Enyinnaya,Hermanns,Holmberg,Oliveira,Kufersin,Kwiatkowski,Courtois,Piest,Sandheaver,Woods,Ives,Dias,Grizelj,Viragh,Blau,Kodou,Torma,Sorokina,Took-Took,Allen,Melo,Bunker,Kiyomizu,Donkervoort,Maciejewska,Steffensen,Solomina,Zidek,Gotou,Bryant,Quenneville,Karlsen,Thomsen,Havlikova,Feron,Bazhenov,Amsel,Enoksen,Schneider,Kiss,Woodd,Benes,Probst,Aliyeva,Fleischer,Plain,Hoskinson,Chad,Maki,Gandhi,Zhao,Wintermute,Cronje,Felten,Yellen,Wood,Zhu,Davis,K,Delphine,Thorne,Kulechov,Nigiri,Goldfeder,Ranth,Galt,Lincoln,Trump";
    uint256 private constant lastNamesLength = 161;

    string private constant suffixes =
        "the Great,Jr.,Sr.,the Ape,the Magnificent,the Impaler,the Able,the Ambitious,the Astrologer,the Bad,the Bastard,the Blessed,the Bloody,the Conqueror,the Cruel,the Damned,Dracula,the Drunkard,the Elder,the Eloquent,the Enlightened,the Fair,the Farmer,the Fat,the Fearless,the Fighter,the Comfy,the Couch,the Fortunate,the Generous,the Gentle,the Glorious,the Good,the God-Given,the God,the Grim,the Handsome,the Hammer,Hadrada,the Hidden,the Holy,the Hunter,the Illustrious,the Invincible,the Iron,the Just,the Kind,the Lame,the Last,the Lawgiver,the Learned,the Liberator,the Lion,the Mad,the Magnanimous,the Mighty,the Monk,the Mild,the Musician,the Navigator,the Nobel,the Old,the One-Eyed,the Outlaw,the Pale,the Peaceful,the Philosopher,the Pilgrim,the Pious,the Poet,the Proud,the Quiet,the Rash,the Red,the Reformer,the Saint,the Savior,the Seer,the Short,the Silent,the Simple,the Sorcerer,the Strong,the Tall,the Terrible,the Thunderbolt,the Trembling,the Tyrant,the Unlucky,the Unready,the Vain,the Virgin,the Warrior,the Weak,the Wicked,the Wise,the Young,the Cuck,the Chad,the NoCoiner,.eth,da gay,the Prophet,the Paper-Handed,the Diamond-Handed";
    uint256 private constant suffixesLength = 104;

    function random(string memory input) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(input)));
    }

    function getFirstName(uint256 tokenId) public pure returns (string memory) {
        return pluck(tokenId, "FIRST_NAME", firstNames, firstNamesLength);
    }

    function getLastName(uint256 tokenId) public pure returns (string memory) {
        return pluck(tokenId, "LAST_NAME", lastNames, lastNamesLength);
    }

    function getSuffix(uint256 tokenId) public pure returns (string memory) {
        if (tokenId > 8000) {
            return "";
        }
        return pluck(tokenId, "SUFFIX", suffixes, suffixesLength);
    }

    function pluck(
        uint256 tokenId,
        string memory keyPrefix,
        string memory sourceCSV,
        uint256 sourceCSVLength
    ) internal pure returns (string memory) {
        uint256 rand = random(
            string(abi.encodePacked(keyPrefix, Strings.toString(tokenId)))
        );
        return getItemFromCSV(sourceCSV, rand % sourceCSVLength);
    }

    function shouldGib(uint256 tokenId, string memory keyPrefix)
        internal
        pure
        returns (bool)
    {
        uint256 rand = random(
            string(
                abi.encodePacked(
                    "SHOULD_GIB",
                    keyPrefix,
                    Strings.toString(tokenId)
                )
            )
        );
        uint256 greatness = rand % 21;
        return (greatness >= 19);
    }

    function getName(uint256 tokenId) public pure returns (string memory) {
        string[5] memory parts;

        parts[0] = getFirstName(tokenId);

        parts[1] = " ";

        parts[2] = getLastName(tokenId);

        parts[4] = getSuffix(tokenId);

        parts[3] = bytes(parts[4]).length > 0 ? " " : "";

        string memory fullName = string(
            abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4])
        );

        return fullName;
    }

    function tokenURI(uint256 tokenId) public pure returns (string memory) {
        string[3] memory parts;

        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

        parts[1] = getName(tokenId);

        parts[2] = "</text></svg>";

        string memory output = string(
            abi.encodePacked(parts[0], parts[1], parts[2])
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "',
                        parts[1],
                        '", "description": "LootName is randomized adventurer name generated on chain.  Feel free to use LootName in any way you want.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );

        output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
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

    constructor() {}
}