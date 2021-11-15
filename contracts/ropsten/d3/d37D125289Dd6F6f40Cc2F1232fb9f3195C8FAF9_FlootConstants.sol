// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.0;

import { strings } from "./strings.sol";

/**
 * @title FlootConstants
 * @author the-torn
 *
 * @notice External library for constants used by Floot.
 *
 *  This is an external library in order to keep the main contract within the bytecode limit.
 *
 *  Based closely on the original Loot implementation (MIT License).
 *  https://etherscan.io/address/0xff9c1b15b16263c61d017ee9f65c50e4ae0113d7#code#L1
 *  The CSV optimization is owed to zefram.eth.
 */
library FlootConstants {
  using strings for string;
  using strings for strings.slice;

  enum ListName {
    WEAPON,
    CHEST,
    HEAD,
    WAIST,
    FOOT,
    HAND,
    NECK,
    RING,
    SUFFIX,
    NAME_PREFIX,
    NAME_SUFFIX
  }

  string internal constant WEAPONS = "Warhammer,Quarterstaff,Maul,Mace,Club,Katana,Falchion,Scimitar,Long Sword,Short Sword,Ghost Wand,Grave Wand,Bone Wand,Wand,Grimoire,Chronicle,Tome,Book";
  uint256 internal constant WEAPONS_LENGTH = 18;

  string internal constant CHEST_ARMOR = "Divine Robe,Silk Robe,Linen Robe,Robe,Shirt,Demon Husk,Dragonskin Armor,Studded Leather Armor,Hard Leather Armor,Leather Armor,Holy Chestplate,Ornate Chestplate,Plate Mail,Chain Mail,Ring Mail";
  uint256 internal constant CHEST_ARMOR_LENGTH = 15;

  string internal constant HEAD_ARMOR = "Ancient Helm,Ornate Helm,Great Helm,Full Helm,Helm,Demon Crown,Dragon's Crown,War Cap,Leather Cap,Cap,Crown,Divine Hood,Silk Hood,Linen Hood,Hood";
  uint256 internal constant HEAD_ARMOR_LENGTH = 15;

  string internal constant WAIST_ARMOR = "Ornate Belt,War Belt,Plated Belt,Mesh Belt,Heavy Belt,Demonhide Belt,Dragonskin Belt,Studded Leather Belt,Hard Leather Belt,Leather Belt,Brightsilk Sash,Silk Sash,Wool Sash,Linen Sash,Sash";
  uint256 internal constant WAIST_ARMOR_LENGTH = 15;

  string internal constant FOOT_ARMOR = "Holy Greaves,Ornate Greaves,Greaves,Chain Boots,Heavy Boots,Demonhide Boots,Dragonskin Boots,Studded Leather Boots,Hard Leather Boots,Leather Boots,Divine Slippers,Silk Slippers,Wool Shoes,Linen Shoes,Shoes";
  uint256 internal constant FOOT_ARMOR_LENGTH = 15;

  string internal constant HAND_ARMOR = "Holy Gauntlets,Ornate Gauntlets,Gauntlets,Chain Gloves,Heavy Gloves,Demon's Hands,Dragonskin Gloves,Studded Leather Gloves,Hard Leather Gloves,Leather Gloves,Divine Gloves,Silk Gloves,Wool Gloves,Linen Gloves,Gloves";
  uint256 internal constant HAND_ARMOR_LENGTH = 15;

  string internal constant NECKLACES = "Necklace,Amulet,Pendant";
  uint256 internal constant NECKLACES_LENGTH = 3;

  string internal constant RINGS = "Gold Ring,Silver Ring,Bronze Ring,Platinum Ring,Titanium Ring";
  uint256 internal constant RINGS_LENGTH = 5;

  string internal constant SUFFIXES = "of Power,of Giants,of Titans,of Skill,of Perfection,of Brilliance,of Enlightenment,of Protection,of Anger,of Rage,of Fury,of Vitriol,of the Fox,of Detection,of Reflection,of the Twins";
  uint256 internal constant SUFFIXES_LENGTH = 16;

  string internal constant NAME_PREFIXES = "Agony,Apocalypse,Armageddon,Beast,Behemoth,Blight,Blood,Bramble,Brimstone,Brood,Carrion,Cataclysm,Chimeric,Corpse,Corruption,Damnation,Death,Demon,Dire,Dragon,Dread,Doom,Dusk,Eagle,Empyrean,Fate,Foe,Gale,Ghoul,Gloom,Glyph,Golem,Grim,Hate,Havoc,Honour,Horror,Hypnotic,Kraken,Loath,Maelstrom,Mind,Miracle,Morbid,Oblivion,Onslaught,Pain,Pandemonium,Phoenix,Plague,Rage,Rapture,Rune,Skull,Sol,Soul,Sorrow,Spirit,Storm,Tempest,Torment,Vengeance,Victory,Viper,Vortex,Woe,Wrath,Light's,Shimmering";
  uint256 internal constant NAME_PREFIXES_LENGTH = 69;

  string internal constant NAME_SUFFIXES = "Bane,Root,Bite,Song,Roar,Grasp,Instrument,Glow,Bender,Shadow,Whisper,Shout,Growl,Tear,Peak,Form,Sun,Moon";
  uint256 internal constant NAME_SUFFIXES_LENGTH = 18;

  function getItem(
    uint256 rand,
    ListName listName
  )
    external
    pure
    returns (string memory)
  {
    if (listName == ListName.WEAPON) {
      return getItemFromCsv(WEAPONS, rand % WEAPONS_LENGTH);
    }
    if (listName == ListName.CHEST) {
      return getItemFromCsv(CHEST_ARMOR, rand % CHEST_ARMOR_LENGTH);
    }
    if (listName == ListName.HEAD) {
      return getItemFromCsv(HEAD_ARMOR, rand % HEAD_ARMOR_LENGTH);
    }
    if (listName == ListName.WAIST) {
      return getItemFromCsv(WAIST_ARMOR, rand % WAIST_ARMOR_LENGTH);
    }
    if (listName == ListName.FOOT) {
      return getItemFromCsv(FOOT_ARMOR, rand % FOOT_ARMOR_LENGTH);
    }
    if (listName == ListName.HAND) {
      return getItemFromCsv(HAND_ARMOR, rand % HAND_ARMOR_LENGTH);
    }
    if (listName == ListName.NECK) {
      return getItemFromCsv(NECKLACES, rand % NECKLACES_LENGTH);
    }
    if (listName == ListName.RING) {
      return getItemFromCsv(RINGS, rand % RINGS_LENGTH);
    }
    if (listName == ListName.SUFFIX) {
      return getItemFromCsv(SUFFIXES, rand % SUFFIXES_LENGTH);
    }
    if (listName == ListName.NAME_PREFIX) {
      return getItemFromCsv(NAME_PREFIXES, rand % NAME_PREFIXES_LENGTH);
    }
    if (listName == ListName.NAME_SUFFIX) {
      return getItemFromCsv(NAME_SUFFIXES, rand % NAME_SUFFIXES_LENGTH);
    }
    revert("Invalid list name");
  }

  /**
   * @notice Convert an integer to a string.
   *
   * Inspired by OraclizeAPI's implementation (MIT license).
   * https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol
   */
  function toString(
    uint256 value
  )
    internal
    pure
    returns (string memory)
  {
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
   * @notice Read an item from a string of comma-separated values.
   *
   * Based on zefram.eth's implementation (MIT license).
   * https://etherscan.io/address/0xb9310af43f4763003f42661f6fc098428469adab#code
   */
  function getItemFromCsv(
    string memory str,
    uint256 index
  )
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
}

// SPDX-License-Identifier: Apache-2.0
//
// Retrieved from https://github.com/Arachnid/solidity-stringutils/blob/master/src/strings.sol
// Modified to update Solidity version and include only certain functions.

pragma solidity ^0.8.0;

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
    uint _len;
    uint _ptr;
  }

  function memcpy(uint dest, uint src, uint len) private pure {
    // Copy word-length chunks while possible
    for(; len >= 32; len -= 32) {
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
   * @dev Copies a slice to a new string.
   * @param self The slice to copy.
   * @return A newly allocated string containing the slice's text.
   */
  function toString(slice memory self) internal pure returns (string memory) {
    string memory ret = new string(self._len);
    uint retptr;
    assembly { retptr := add(ret, 32) }

    memcpy(retptr, self._ptr, self._len);
    return ret;
  }

  // Returns the memory address of the first byte of the first occurrence of
  // `needle` in `self`, or the first byte after `self` if not found.
  function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
    uint ptr = selfptr;
    uint idx;

    if (needlelen <= selflen) {
      if (needlelen <= 32) {
        bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

        bytes32 needledata;
        assembly { needledata := and(mload(needleptr), mask) }

        uint end = selfptr + selflen - needlelen;
        bytes32 ptrdata;
        assembly { ptrdata := and(mload(ptr), mask) }

        while (ptrdata != needledata) {
          if (ptr >= end)
            return selfptr + selflen;
          ptr++;
          assembly { ptrdata := and(mload(ptr), mask) }
        }
        return ptr;
      } else {
        // For long needles, use hashing
        bytes32 hash;
        assembly { hash := keccak256(needleptr, needlelen) }

        for (idx = 0; idx <= selflen - needlelen; idx++) {
          bytes32 testHash;
          assembly { testHash := keccak256(ptr, needlelen) }
          if (hash == testHash)
            return ptr;
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
  function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
    uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
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
  function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
    split(self, needle, token);
  }
}

