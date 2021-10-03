//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract LootMirror is Ownable {
  // Mapping from token ID to owner address
  mapping(uint256 => address) private _owners;

  // Mapping owner address to token count
  mapping(address => uint256) private _balances;

  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // Struct for updating the owners
  struct OwnerUpdate {
    address owner;
    uint256[] tokenIds;
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view virtual returns (uint256) {
    require(owner != address(0), "ERC721: balance query for the zero address");
    return _balances[owner];
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view virtual returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), "ERC721: owner query for nonexistent token");
    return owner;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    virtual
    returns (uint256)
  {
    require(
      index < balanceOf(owner),
      "ERC721Enumerable: owner index out of bounds"
    );
    return _ownedTokens[owner][index];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public virtual {
    require(operator != _msgSender(), "ERC721: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * The owner of this contract can call this function to
   * update the owner states
   *
   * The update should include entries for incoming owners and
   * any existing owners whose balances have changed
   *
   * It can also include entries for owners whose balances
   * haven't yet been indexed by the contract
   *
   * It's not necessary to include entries for outgoing owners (they'll
   * be deleted automatically)
   */
  function setLootOwners(OwnerUpdate[] calldata _ownerUpdates)
    public
    onlyOwner
  {
    // For each of the owner updates
    for (uint256 i = 0; i < _ownerUpdates.length; i++) {
      address owner = _ownerUpdates[i].owner;
      uint256[] calldata tokenIds = _ownerUpdates[i].tokenIds;

      // Reset the owned tokens of the owner
      uint256 ownerBalance = _balances[owner];
      for (uint256 j = 0; j < ownerBalance; j++) {
        delete _ownedTokens[owner][j];
      }

      // Reset the balance of the owner
      delete _balances[owner];

      // For each of the token ids
      for (uint256 k = 0; k < tokenIds.length; k++) {
        address previousOwner = _owners[tokenIds[k]];

        // Reset the owned tokens of the previous owner
        uint256 previousOwnerBalance = _balances[previousOwner];
        for (uint256 l = 0; l < previousOwnerBalance; l++) {
          delete _ownedTokens[previousOwner][l];
        }

        // Reset the balances of the previous owner
        delete _balances[previousOwner];

        // Reset the owner of the token ids
        delete _owners[tokenIds[k]];
      }
    }

    // For each of the owner updates
    for (uint256 k = 0; k < _ownerUpdates.length; k++) {
      address owner = _ownerUpdates[k].owner;
      uint256[] calldata tokenIds = _ownerUpdates[k].tokenIds;

      // Set the balances of the owner
      _balances[owner] = tokenIds.length;

      for (uint256 l = 0; l < tokenIds.length; l++) {
        // Set the owner of the token ids
        _owners[tokenIds[l]] = owner;
        // Set the owned tokens of the owner
        _ownedTokens[owner][l] = tokenIds[l];
      }
    }
  }

  /**
   * Loot utils
   */
  string[] private weapons = [
    "Warhammer",
    "Quarterstaff",
    "Maul",
    "Mace",
    "Club",
    "Katana",
    "Falchion",
    "Scimitar",
    "Long Sword",
    "Short Sword",
    "Ghost Wand",
    "Grave Wand",
    "Bone Wand",
    "Wand",
    "Grimoire",
    "Chronicle",
    "Tome",
    "Book"
  ];

  string[] private chestArmor = [
    "Divine Robe",
    "Silk Robe",
    "Linen Robe",
    "Robe",
    "Shirt",
    "Demon Husk",
    "Dragonskin Armor",
    "Studded Leather Armor",
    "Hard Leather Armor",
    "Leather Armor",
    "Holy Chestplate",
    "Ornate Chestplate",
    "Plate Mail",
    "Chain Mail",
    "Ring Mail"
  ];

  string[] private headArmor = [
    "Ancient Helm",
    "Ornate Helm",
    "Great Helm",
    "Full Helm",
    "Helm",
    "Demon Crown",
    "Dragon's Crown",
    "War Cap",
    "Leather Cap",
    "Cap",
    "Crown",
    "Divine Hood",
    "Silk Hood",
    "Linen Hood",
    "Hood"
  ];

  string[] private waistArmor = [
    "Ornate Belt",
    "War Belt",
    "Plated Belt",
    "Mesh Belt",
    "Heavy Belt",
    "Demonhide Belt",
    "Dragonskin Belt",
    "Studded Leather Belt",
    "Hard Leather Belt",
    "Leather Belt",
    "Brightsilk Sash",
    "Silk Sash",
    "Wool Sash",
    "Linen Sash",
    "Sash"
  ];

  string[] private footArmor = [
    "Holy Greaves",
    "Ornate Greaves",
    "Greaves",
    "Chain Boots",
    "Heavy Boots",
    "Demonhide Boots",
    "Dragonskin Boots",
    "Studded Leather Boots",
    "Hard Leather Boots",
    "Leather Boots",
    "Divine Slippers",
    "Silk Slippers",
    "Wool Shoes",
    "Linen Shoes",
    "Shoes"
  ];

  string[] private handArmor = [
    "Holy Gauntlets",
    "Ornate Gauntlets",
    "Gauntlets",
    "Chain Gloves",
    "Heavy Gloves",
    "Demon's Hands",
    "Dragonskin Gloves",
    "Studded Leather Gloves",
    "Hard Leather Gloves",
    "Leather Gloves",
    "Divine Gloves",
    "Silk Gloves",
    "Wool Gloves",
    "Linen Gloves",
    "Gloves"
  ];

  string[] private necklaces = ["Necklace", "Amulet", "Pendant"];

  string[] private rings = [
    "Gold Ring",
    "Silver Ring",
    "Bronze Ring",
    "Platinum Ring",
    "Titanium Ring"
  ];

  string[] private suffixes = [
    "of Power",
    "of Giants",
    "of Titans",
    "of Skill",
    "of Perfection",
    "of Brilliance",
    "of Enlightenment",
    "of Protection",
    "of Anger",
    "of Rage",
    "of Fury",
    "of Vitriol",
    "of the Fox",
    "of Detection",
    "of Reflection",
    "of the Twins"
  ];

  string[] private namePrefixes = [
    "Agony",
    "Apocalypse",
    "Armageddon",
    "Beast",
    "Behemoth",
    "Blight",
    "Blood",
    "Bramble",
    "Brimstone",
    "Brood",
    "Carrion",
    "Cataclysm",
    "Chimeric",
    "Corpse",
    "Corruption",
    "Damnation",
    "Death",
    "Demon",
    "Dire",
    "Dragon",
    "Dread",
    "Doom",
    "Dusk",
    "Eagle",
    "Empyrean",
    "Fate",
    "Foe",
    "Gale",
    "Ghoul",
    "Gloom",
    "Glyph",
    "Golem",
    "Grim",
    "Hate",
    "Havoc",
    "Honour",
    "Horror",
    "Hypnotic",
    "Kraken",
    "Loath",
    "Maelstrom",
    "Mind",
    "Miracle",
    "Morbid",
    "Oblivion",
    "Onslaught",
    "Pain",
    "Pandemonium",
    "Phoenix",
    "Plague",
    "Rage",
    "Rapture",
    "Rune",
    "Skull",
    "Sol",
    "Soul",
    "Sorrow",
    "Spirit",
    "Storm",
    "Tempest",
    "Torment",
    "Vengeance",
    "Victory",
    "Viper",
    "Vortex",
    "Woe",
    "Wrath",
    "Light's",
    "Shimmering"
  ];

  string[] private nameSuffixes = [
    "Bane",
    "Root",
    "Bite",
    "Song",
    "Roar",
    "Grasp",
    "Instrument",
    "Glow",
    "Bender",
    "Shadow",
    "Whisper",
    "Shout",
    "Growl",
    "Tear",
    "Peak",
    "Form",
    "Sun",
    "Moon"
  ];

  function random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function getWeapon(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "WEAPON", weapons);
  }

  function getChest(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "CHEST", chestArmor);
  }

  function getHead(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "HEAD", headArmor);
  }

  function getWaist(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "WAIST", waistArmor);
  }

  function getFoot(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "FOOT", footArmor);
  }

  function getHand(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "HAND", handArmor);
  }

  function getNeck(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "NECK", necklaces);
  }

  function getRing(uint256 tokenId) public view returns (string memory) {
    return pluck(tokenId, "RING", rings);
  }

  function pluck(
    uint256 tokenId,
    string memory keyPrefix,
    string[] memory sourceArray
  ) internal view returns (string memory) {
    uint256 rand = random(
      string(abi.encodePacked(keyPrefix, toString(tokenId)))
    );
    string memory output = sourceArray[rand % sourceArray.length];
    uint256 greatness = rand % 21;
    if (greatness > 14) {
      output = string(
        abi.encodePacked(output, " ", suffixes[rand % suffixes.length])
      );
    }
    if (greatness >= 19) {
      string[2] memory name;
      name[0] = namePrefixes[rand % namePrefixes.length];
      name[1] = nameSuffixes[rand % nameSuffixes.length];
      if (greatness == 19) {
        output = string(
          abi.encodePacked('"', name[0], " ", name[1], '" ', output)
        );
      } else {
        output = string(
          abi.encodePacked('"', name[0], " ", name[1], '" ', output, " +1")
        );
      }
    }
    return output;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    returns (string memory)
  {
    string[17] memory parts;
    parts[
      0
    ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';

    parts[1] = getWeapon(tokenId);

    parts[2] = '</text><text x="10" y="40" class="base">';

    parts[3] = getChest(tokenId);

    parts[4] = '</text><text x="10" y="60" class="base">';

    parts[5] = getHead(tokenId);

    parts[6] = '</text><text x="10" y="80" class="base">';

    parts[7] = getWaist(tokenId);

    parts[8] = '</text><text x="10" y="100" class="base">';

    parts[9] = getFoot(tokenId);

    parts[10] = '</text><text x="10" y="120" class="base">';

    parts[11] = getHand(tokenId);

    parts[12] = '</text><text x="10" y="140" class="base">';

    parts[13] = getNeck(tokenId);

    parts[14] = '</text><text x="10" y="160" class="base">';

    parts[15] = getRing(tokenId);

    parts[16] = "</text></svg>";

    string memory output = string(
      abi.encodePacked(
        parts[0],
        parts[1],
        parts[2],
        parts[3],
        parts[4],
        parts[5],
        parts[6],
        parts[7],
        parts[8]
      )
    );
    output = string(
      abi.encodePacked(
        output,
        parts[9],
        parts[10],
        parts[11],
        parts[12],
        parts[13],
        parts[14],
        parts[15],
        parts[16]
      )
    );

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name": "Bag #',
            toString(tokenId),
            '", "description": "Loot is randomized adventurer gear generated and stored on chain. Stats, images, and other functionality are intentionally omitted for others to interpret. Feel free to use Loot in any way you want.", "image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(output)),
            '"}'
          )
        )
      )
    );
    output = string(abi.encodePacked("data:application/json;base64,", json));

    return output;
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
        out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}