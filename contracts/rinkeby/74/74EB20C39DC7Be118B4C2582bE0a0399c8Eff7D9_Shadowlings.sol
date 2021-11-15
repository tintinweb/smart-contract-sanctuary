// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/metadata/ShadowlingMetadata.sol";
import "./libraries/Random.sol";
import "./libraries/MetadataUtils.sol";
import "./libraries/Currency.sol";

contract Shadowlings is ShadowlingMetadata, Ownable, ReentrancyGuard {
    /// @notice Mints Shadowlings to `msg.sender`, cannot mint 0 tokenId
    /// @param  tokenId Token with `id` to mint. Maps id to individual item ids in ItemIds
    /// @param  recipient Address which is minted a Shadowling
    /// @param  seed Psuedorandom number hopefully generated from commit-reveal scheme
    function claim(
        uint256 tokenId,
        address recipient,
        uint256 seed
    ) external nonReentrant onlyOwner {
        propertiesOf[tokenId] = Attributes.ids(seed);
        _safeMint(recipient, tokenId);
    }

    /// @notice Modifies the attributes of Shadowling with `tokenId` using the type of currency
    /// @param tokenId Shadowling tokenId to modify
    /// @param currencyId Type of currency to use
    /// @param seed Pseudorandom value hopefully generated from a commit-reveal scheme
    function modify(
        uint256 tokenId,
        uint256 currencyId,
        uint256 seed
    ) external nonReentrant onlyOwner {
        Attributes.ItemIds memory cache = propertiesOf[tokenId]; // cache the shadowling props

        uint256[4] memory values;
        values[0] = cache.creature;
        values[1] = cache.item;
        values[2] = cache.perk;
        values[3] = cache.name;

        values = Currency.modify(currencyId, values, seed); // Most important fn

        cache.creature = values[0] > 0 ? Attributes.creatureId(values[0]) : 0;
        cache.item = values[1] > 0 ? Attributes.itemId(values[1]) : 0;
        cache.perk = values[2] > 0 ? Attributes.perkId(values[2]) : 0;
        cache.name = values[3] > 0 ? Attributes.nameId(values[3]) : 0;

        propertiesOf[tokenId] = cache;
    }

    constructor(address altar) {
        transferOwnership(altar);
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
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./Attributes.sol";
import "./Stats.sol";
import "../TokenId.sol";
import { Base64, toString } from "../MetadataUtils.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

/// @title Helper contract for generating ERC-1155 token ids and descriptions for
/// the individual items inside a Loot bag.
/// @author Georgios Konstantopoulos
/// @dev Inherit from this contract and use it to generate metadata for your tokens
contract ShadowlingMetadata is ERC721Enumerable {
    mapping(uint256 => Attributes.ItemIds) public propertiesOf;

    constructor() ERC721("Shadowlings", "SHDW") {}

    /// @dev Opensea contract metadata: https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() external pure returns (string memory) {
        string
            memory json = '{"name": "Shadowlings", "description": "Shadowlings follow you in your journey across chainspace, the shadowchain, and beyond..."}';
        string memory encodedJson = Base64.encode(bytes(json));
        string memory output = string(
            abi.encodePacked("data:application/json;base64,", encodedJson)
        );

        return output;
    }

    /// @notice Returns an SVG for the provided token id
    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721)
        returns (string memory)
    {
        Attributes.ItemStrings memory props = properties(tokenId);
        string memory svg = string(
            abi.encodePacked(Attributes.render(props), Stats.render(tokenId))
        );
        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "',
                        "Shadowlings",
                        '", ',
                        '"description" : ',
                        '"Shadowlings follow you in your journey across chainspace, the shadowchain, and beyond...", ',
                        render(svg),
                        attributes(tokenId)
                    )
                )
            )
        );
        string memory output = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return output;
    }

    function render(string memory attr) public pure returns (string memory) {
        string[4] memory parts;
        parts[
            0
        ] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="#000026" />';

        parts[1] = attr;

        string memory output = string(abi.encodePacked(parts[0], parts[1]));

        output = string(abi.encodePacked(output, "</svg>"));

        output = string(
            abi.encodePacked(
                '"image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(output)),
                '", '
            )
        );

        return output;
    }

    /// @notice Returns the attributes properties of a `tokenId`
    /// @dev Opensea Standards: https://docs.opensea.io/docs/metadata-standards
    function attributes(uint256 tokenId) public view returns (string memory) {
        string memory output;

        string memory res = string(
            abi.encodePacked("[", Attributes.attributes(properties(tokenId)))
        );

        res = string(abi.encodePacked(res, ", ", Stats.attributes(tokenId)));

        res = string(abi.encodePacked(res, "]"));

        output = string(abi.encodePacked('"attributes": ', res, "}"));
        return output;
    }

    /// @dev Opensea Standards: https://docs.opensea.io/docs/metadata-standards
    /// @param  itemId A value in propertiesOf[tokenId]
    /// @return Attributes properties of a single item
    function attributesItem(uint256 itemId)
        public
        pure
        returns (string memory)
    {
        return Scanner.attributes(itemId);
    }

    /// @return Each item as a string from a Shadowling with `tokenId`
    function properties(uint256 tokenId)
        public
        view
        returns (Attributes.ItemStrings memory)
    {
        return Attributes.props(propertiesOf[tokenId]);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/// @notice Is this really random?
library Random {
    /// @notice Uses a commit-reveal scheme to get randomness from miners and users, separately
    /// @param schemeHash Hash of the blockhash at the commit block.number, and their reveal hash
    /// @return pseudorandom uint value to use as randomness
    function random(string memory schemeHash) internal view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encode(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.number,
                            tx.origin,
                            msg.sender,
                            gasleft(),
                            schemeHash,
                            blockhash(block.number),
                            blockhash(block.number - 69)
                        )
                    )
                )
            )
        );
        return seed;
    }

    /// @param input Hash of roll number, tokenId
    /// @return pseudorandom number between 1 and 6
    function roll(string memory input) internal pure returns (uint256) {
        return (uint256(keccak256(abi.encodePacked(input))) % 6) + 1;
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

// Helper for encoding as json w/ trait_type / value from opensea
function trait(string memory _traitType, string memory _value)
    pure
    returns (string memory)
{
    return
        string(
            abi.encodePacked(
                "{",
                '"trait_type": "',
                _traitType,
                '", ',
                '"value": "',
                _value,
                '"',
                "}"
            )
        );
}

function toString(uint256 value) pure returns (string memory) {
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./Random.sol";

library Currency {
    uint256 internal constant MOD_FOUR = 2;
    uint256 internal constant MOD_TWO = 3;
    uint256 internal constant ADD_TWO = 4;
    uint256 internal constant ADD_FOUR = 5;
    uint256 internal constant REMOVE = 6;
    uint256 internal constant AUGMENT_TWO = 7;
    uint256 internal constant AUGUMENT_FOUR = 8;
    uint256 internal constant MEM_COPY = 9;
    uint256 internal constant START_INDEX = 10;

    error ModifyError();

    /// @return Count of attribute Ids > 0
    function amountOf(uint256[4] memory params)
        internal
        pure
        returns (uint256)
    {
        uint256 len = params.length;
        uint256 count;
        for (uint256 i; i < len; i++) {
            uint256 value = params[i];
            if (value > 0) count++;
        }
        return count;
    }

    function slot(string memory prefix, uint256 seed)
        internal
        pure
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(prefix, seed)));
    }

    /// @notice Modifies an array of values which are the tokenIds for the attributes
    /// @param currencyId Type of currency being used
    /// @param params Values to manipulate; directly converted to attributes
    /// @param seed Pseudorandom value hopefully generated through a commit-reveal scheme
    function modify(
        uint256 currencyId,
        uint256[4] memory params,
        uint256 seed
    ) internal pure returns (uint256[4] memory) {
        seed = seed % 21;
        uint256 len = params.length;
        uint256 count = amountOf(params); // count how many properties are > 0

        // adds a property to a one property item
        if (currencyId == AUGMENT_TWO) {
            if (count != 1) revert ModifyError();
            // for each attribute, find the currently set one and modify the one above it
            for (uint256 i; i < len; i++) {
                uint256 value = params[i];
                // if its the last one, set the first slot
                if (i == len - 1) params[0] = slot("SLOT0", seed);
                if (value > 0) params[i + 1] = slot("SLOT1", seed);
            }
        }

        // adds a property to a three property item
        if (currencyId == AUGUMENT_FOUR) {
            if (count != 3) revert ModifyError();
            // for each attribute, find the one that is not set, and modify it
            for (uint256 i; i < len; i++) {
                uint256 value = params[i];
                // if its the last one, set the first slot
                if (value == 0) params[i] = slot("SLOT1", seed);
            }
        }

        // deletes all properties
        if (currencyId == REMOVE) {
            // for each attribute, find the one that is set, and set it to 0
            for (uint256 i; i < len; i++) {
                uint256 value = params[i];
                // if its not 0, set it to 0
                if (value > 0) params[i] = 0;
            }
        }

        // adds up to two properties to a zero property item
        if (currencyId == ADD_TWO) {
            if (count > 0) revert ModifyError();
            if (seed > 14) params[1] = slot("SLOT1", seed);
            else params[len - 1] = slot("SLOT2", seed);
        }

        // adds up to four properties to a zero property item
        if (currencyId == ADD_FOUR) {
            if (count > 0) revert ModifyError();
            for (uint256 i; i < len; i++) {
                // if its the last one, set the first slot
                if (seed > 19) params[i] = 0;
                else params[i] = slot("SLOT1", seed);
            }
        }

        // modifies up to four properties on a max four property item
        if (currencyId == MOD_FOUR) {
            if (seed > 19) params = update(seed, 1);
            else if (seed < 4) params = update(seed, 2);
            else if (seed < 19 && seed > 16) params = update(seed, 3);
            else params = update(seed, 4);
        }

        // modifies up to two properties on a max two property item
        if (currencyId == MOD_TWO) {
            if (count > 2) revert ModifyError();
            if (seed > 14) params = update(seed, 1);
            else params = update(seed, 2);
        }

        return params;
    }

    /// @notice Updates an array of values up to `max` using `seed`
    function update(uint256 seed, uint256 max)
        internal
        pure
        returns (uint256[4] memory)
    {
        uint256[4] memory params;
        uint256 updated = 1;
        params[0] = slot("SLOT0", seed);
        if (updated >= max) return params;
        updated++;
        params[1] = slot("SLOT1", seed);
        if (updated >= max) return params;
        updated++;
        params[2] = slot("SLOT2", seed);
        if (updated >= max) return params;
        params[3] = slot("SLOT3", seed);
        return params;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./Components.sol";
import "./Scanner.sol";
import "../TokenId.sol";
import { Base64, toString, trait } from "../MetadataUtils.sol";

/// @title Helper contract for generating ERC-1155 token ids.
/// @author Georgios Konstantopoulos
/// @dev Inherit from this contract and use it to generate metadata for your tokens
/// Flow:
/// 1. tokenId from top level NFT
/// 2. tokenId -> encodedId per attribute
/// 3. Scanner(encodedId) -> individual attributes of each item
/// 4. return all attributes of NFT
library Attributes {
    using Components for uint256;

    // ====== Attribute Storage =====

    /// @notice Item Attribute Identifiers
    struct ItemIds {
        uint256 creature;
        uint256 item;
        uint256 origin;
        uint256 bloodline;
        uint256 perk;
        uint256 name;
    }

    /// @notice Item Attributes Raw
    struct ItemStrings {
        string creature;
        string item;
        string origin;
        string bloodline;
        string perk;
        string name;
    }

    // ===== Encoding Ids =====

    /// @notice Given an item id, returns its name by decoding and parsing the id
    function encodedIdToString(uint256 id)
        internal
        pure
        returns (string memory)
    {
        (uint256[5] memory components, uint256 itemType) = TokenId.fromId(id);
        return Scanner.componentsToString(components, itemType);
    }

    // ===== SVG Rendering =====

    /// @notice Returns an SVG for the provided token id
    /// @param  item Attributes of an item as strings
    /// @return SVG string that renders the Attributes as text
    function render(ItemStrings memory item)
        internal
        pure
        returns (string memory)
    {
        string[13] memory parts;
        parts[0] = '<text x="10" y="20" class="base">';

        parts[1] = item.creature;

        parts[2] = '</text><text x="10" y="40" class="base">';

        parts[3] = item.item;

        parts[4] = '</text><text x="10" y="60" class="base">';

        parts[5] = item.origin;

        parts[6] = '</text><text x="10" y="80" class="base">';

        parts[7] = item.bloodline;

        parts[8] = '</text><text x="10" y="100" class="base">';

        parts[9] = item.perk;

        parts[10] = '</text><text x="10" y="120" class="base">';

        parts[11] = item.name;

        parts[12] = "</text>";

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
            abi.encodePacked(output, parts[9], parts[10], parts[11], parts[12])
        );
        return output;
    }

    // ====== Attributes of NFT =====

    /// @notice Returns the attributes of a `tokenId`
    /// @dev Opensea Standards: https://docs.opensea.io/docs/metadata-standards
    function attributes(ItemStrings memory items)
        internal
        pure
        returns (string memory)
    {
        string memory res = trait(Scanner.getItemType(0), items.creature);

        res = string(
            abi.encodePacked(
                res,
                ", ",
                trait(Scanner.getItemType(1), items.item)
            )
        );

        res = string(
            abi.encodePacked(
                res,
                ", ",
                trait(Scanner.getItemType(2), items.origin)
            )
        );

        res = string(
            abi.encodePacked(
                res,
                ", ",
                trait(Scanner.getItemType(3), items.bloodline)
            )
        );

        res = string(
            abi.encodePacked(
                res,
                ", ",
                trait(Scanner.getItemType(4), items.perk)
            )
        );

        res = string(
            abi.encodePacked(
                res,
                ", ",
                trait(Scanner.getItemType(5), items.name)
            )
        );
        return res;
    }

    // ===== Encode Individual Item Ids =====

    // View helpers for getting the item ID that corresponds to a bag's items
    function creatureId(uint256 seed) internal pure returns (uint256) {
        return TokenId.toId(seed.creatureComponents(), Scanner.CREATURE);
    }

    function itemId(uint256 seed) internal pure returns (uint256) {
        return TokenId.toId(seed.itemComponents(), Scanner.ITEM);
    }

    function originId(uint256 seed, bool shadowChain)
        internal
        pure
        returns (uint256)
    {
        return TokenId.toId(seed.originComponents(shadowChain), Scanner.ORIGIN);
    }

    function bloodlineId(uint256 seed) internal pure returns (uint256) {
        return TokenId.toId(seed.bloodlineComponents(), Scanner.BLOODLINE);
    }

    function perkId(uint256 seed) internal pure returns (uint256) {
        return TokenId.toId(seed.perkComponents(), Scanner.PERK);
    }

    function nameId(uint256 seed) internal pure returns (uint256) {
        return TokenId.toId(seed.nameComponents(), Scanner.NAME);
    }

    // ===== Utility =====

    /// @notice Uses a seed to get 6 items, each with their own encoded Ids
    /// @param seed Pseudorandom number hopefully generated from a commit-reveal scheme
    /// @return Item attributes as ids
    function ids(uint256 seed) internal pure returns (ItemIds memory) {
        return
            ItemIds({
                creature: Attributes.creatureId(seed),
                item: Attributes.itemId(seed),
                origin: Attributes.originId(seed, false),
                bloodline: Attributes.bloodlineId(seed),
                perk: Attributes.perkId(seed),
                name: Attributes.nameId(seed)
            });
    }

    /// @notice Converts an Item's attribute identifiers into strings
    /// @return Item attributes as strings
    function props(ItemIds memory items)
        internal
        pure
        returns (ItemStrings memory)
    {
        return
            ItemStrings({
                creature: encodedIdToString(items.creature),
                item: encodedIdToString(items.item),
                origin: encodedIdToString(items.origin),
                bloodline: encodedIdToString(items.bloodline),
                perk: encodedIdToString(items.perk),
                name: encodedIdToString(items.name)
            });
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../Random.sol";
import { Base64, toString, trait } from "../MetadataUtils.sol";

/// @notice Inspired by Andy
library Stats {
    // ===== Stats in SVG =====

    /// @param tokenId Shadowling tokenId; stats are static to each tokenId
    /// @return SVG string that renders the stats as text
    function render(uint256 tokenId) internal pure returns (string memory) {
        string[13] memory stats;

        stats[0] = '<text x="10" y="140" class="base">';
        stats[1] = strStat(tokenId);
        stats[2] = '</text><text x="10" y="160" class="base">';
        stats[3] = dexStat(tokenId);
        stats[4] = '</text><text x="10" y="180" class="base">';
        stats[5] = conStat(tokenId);
        stats[6] = '</text><text x="10" y="200" class="base">';
        stats[7] = intStat(tokenId);
        stats[8] = '</text><text x="10" y="220" class="base">';
        stats[9] = wisStat(tokenId);
        stats[10] = '</text><text x="10" y="240" class="base">';
        stats[11] = chaStat(tokenId);
        stats[12] = "</text>";

        string memory output = string(
            abi.encodePacked(
                stats[0],
                stats[1],
                stats[2],
                stats[3],
                stats[4],
                stats[5],
                stats[6],
                stats[7],
                stats[8]
            )
        );

        output = string(
            abi.encodePacked(output, stats[9], stats[10], stats[11], stats[12])
        );
        return output;
    }

    // ===== Attributes =====

    /// @notice Returns the attributes of a `tokenId`
    /// @dev Opensea Standards: https://docs.opensea.io/docs/metadata-standards
    function attributes(uint256 tokenId) internal pure returns (string memory) {
        string memory res = trait("Str", strStat(tokenId));

        res = string(
            abi.encodePacked(res, ", ", trait("Dex", dexStat(tokenId)))
        );

        res = string(
            abi.encodePacked(res, ", ", trait("Con", conStat(tokenId)))
        );

        res = string(
            abi.encodePacked(res, ", ", trait("Int", intStat(tokenId)))
        );

        res = string(
            abi.encodePacked(res, ", ", trait("Wis", wisStat(tokenId)))
        );

        res = string(
            abi.encodePacked(res, ", ", trait("Cha", chaStat(tokenId)))
        );

        return res;
    }

    // ===== Individual Stats =====

    function strStat(uint256 tokenId) internal pure returns (string memory) {
        return pluckStat(tokenId, "Str");
    }

    function dexStat(uint256 tokenId) internal pure returns (string memory) {
        return pluckStat(tokenId, "Dex");
    }

    function conStat(uint256 tokenId) internal pure returns (string memory) {
        return pluckStat(tokenId, "Con");
    }

    function intStat(uint256 tokenId) internal pure returns (string memory) {
        return pluckStat(tokenId, "Int");
    }

    function wisStat(uint256 tokenId) internal pure returns (string memory) {
        return pluckStat(tokenId, "Wis");
    }

    function chaStat(uint256 tokenId) internal pure returns (string memory) {
        return pluckStat(tokenId, "Cha");
    }

    // ===== Roll Stat =====

    function pluckStat(uint256 tokenId, string memory keyPrefix)
        internal
        pure
        returns (string memory)
    {
        uint256 roll1 = Random.roll(
            string(abi.encodePacked(keyPrefix, toString(tokenId), "1"))
        );
        uint256 min = roll1;
        uint256 roll2 = Random.roll(
            string(abi.encodePacked(keyPrefix, toString(tokenId), "2"))
        );
        min = min > roll2 ? roll2 : min;
        uint256 roll3 = Random.roll(
            string(abi.encodePacked(keyPrefix, toString(tokenId), "3"))
        );
        min = min > roll3 ? roll3 : min;
        uint256 roll4 = Random.roll(
            string(abi.encodePacked(keyPrefix, toString(tokenId), "4"))
        );
        min = min > roll4 ? roll4 : min;

        // get 3 highest dice rolls
        uint256 stat = roll1 + roll2 + roll3 + roll4 - min;
        return toString(stat);
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/// @title Encoding / decoding utilities for token ids
/// @author Georgios Konstantopoulos
/// @dev Token ids are generated from the components via a bijective encoding
/// using the token type and its attributes. We shift left by 16 bits, i.e. 2 bytes
/// each time so that the IDs do not overlap, assuming that components are smaller than 256
library TokenId {
    // 2 bytes
    uint256 constant SHIFT = 16;

    /// Encodes an array of Loot components and an item type (weapon, chest etc.)
    /// to a token id
    function toId(uint256[5] memory components, uint256 itemType)
        internal
        pure
        returns (uint256)
    {
        uint256 id = itemType;
        id += encode(components[0], 1);
        id += encode(components[1], 2);
        id += encode(components[2], 3);
        id += encode(components[3], 4);
        id += encode(components[4], 5);

        return id;
    }

    /// Decodes a token id to an array of Loot components and its item type (weapon, chest etc.)
    function fromId(uint256 id)
        internal
        pure
        returns (uint256[5] memory components, uint256 itemType)
    {
        itemType = decode(id, 0);
        components[0] = decode(id, 1);
        components[1] = decode(id, 2);
        components[2] = decode(id, 3);
        components[3] = decode(id, 4);
        components[4] = decode(id, 5);
    }

    /// Masks the component with 0xff and left shifts it by `idx * 2 bytes
    function encode(uint256 component, uint256 idx)
        private
        pure
        returns (uint256)
    {
        return (component & 0xff) << (SHIFT * idx);
    }

    /// Right shifts the provided token id by `idx * 2 bytes` and then masks the
    /// returned value with 0xff.
    function decode(uint256 id, uint256 idx) private pure returns (uint256) {
        return (id >> (SHIFT * idx)) & 0xff;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "../strings.sol";
import "../MetadataUtils.sol";
import "../Random.sol";

/// @notice Inspired by LootComponents by dhof
/// @dev    Raw materials arrays and a plucker
library Components {
    using strings for string;
    using strings for strings.slice;

    string internal constant suffixes =
        "of Borrowed Souls,of Synthetics,of Yield,of Qua'Driga,of Liquidation Pools,of Asteroids,of Atoms,of Betelgeuse,of Celestial,of the Cosmics,of Cybernetics,of Dark Nebulas,of Dopplers,of Electromagnetism,of the Elements,of Meta,of the Hyperscape,of Mars,of Parallax,of Zenith,of Judgement,of Technology,of Hyperspace,of Cyberspace";
    uint256 constant suffixesLength = 24;

    string internal constant namePrefixes =
        "Balthazar,Larp,Rugged,Doxxed,Simp,Meme,Moon,Oracle,Astrogate,Android,Blaster,Cloaking,Continuum,Cyborg,Death Ray,Disintegrator,Earthborn,Digital,Force,Genetic,Holographic,Hyperdrive,Ionic,Jump,Light Speed,Martian,Mech,Matrix,Multiversal,Nebula,Null,Outerworld,Phase,Replicant,Machine,Shield,Space,Starbase,Paradox,Time,Ultraviolet,Fusion,Zero,Quantum,Artificial,Intelligent";
    uint256 constant namePrefixesLength = 46;

    string internal constant nameSuffixes =
        "Nocoiner,Maximus,Degen,All-In,Apesbane,Bearsbane,Minimaxi,Bridgecrosser,Bridgeburner,Goldman,Beam,Comlink,Cyberpunk,Dimensional,Disruptor,Dystopian,Nomadic,Scan,Galactic,Gravity,Humanoid,Hyperspeed,Interplanetary,Laser,Lunar,Matter,Mercurial,Morphic,Mutant,Nova,Orbital,Parallel,Ray,Robot,Sapient,Sol,Pirate,Temporal,Terra,Warp,Uranium,Worm,Xeno";
    uint256 constant nameSuffixesLength = 43;

    string internal constant creatures =
        "None,Twisted Memwraith,Hashenhorror,Shadow Wen,Bear Ape,Moon Wolf,Size Lorde,Degendragon,GM Doge,Lite Llama,Yearning Nymph,Crvaceous Snake,Holovyper,Wailing Integer,Craaven Defaulter,Byzantine Princesss,Manbearpig,Larping Terror,T-Rekt,Defi-ant,Ropsten Whale,Llama,Enchanted Rug,Blind Oracle,Gwei Accountant,Lazarus Cotten,Mempool Wraith,Pernicious Penguin,Seed Stalker,Snark,Shadowswapper,Ravage 0xxl,Market Rat,Dread Dip Dog,Axallaxxa,Fragmented Cobielodon,Jomoeon,Umbramystics,Pepboi,Cypher Ghouls,Censor Vines,Tormented Gorgon,Sushi Kraken,Alpha-eating Ooze,Kirby,Rinkeby Raider,Smol banteg,Blockworm,Metaworm";
    uint256 internal constant creaturesLength = 49;

    string internal constant items =
        "Cybernetic Arm,Cybernetic Eye,Cybernetic Leg,Cybernetic Chest,Cybernetic Foot,Plasma Rifle,Blue Pill,Red Pill,A Block,Cloaking Device,Transporter,Bridge Key,Digital Land,Metawallet,Orb of Protection,Coin,Deck of Cards,Gas,Godblood,Memfruit,Calldata,Event Data,Transaction Data,Metadata,Royalties,Killswitch,Private Key,Cyberknife,Vial of Corruption,Vial of Regeneration,Meta Planet,Meta Golf Course,Meta Tower,Meta Skyscaper,Meta Race Track,Key to the City,Extra Life,Pocket Vehicle,Meta Apartment,Meta House,Meta Company,Divine Bodysuit,Phase Katana,Orb of Summoning,Bottomless Bag,Hoverboard,Merkle Root,Ancient Tattoo";
    uint256 internal constant itemsLength = 48;

    string internal constant origins =
        "Shadowkain's Domain,Kulechovs Dominion ,Perilous Farms,Dark Forest,Mempool,Shadowchain,Polygonal Meshspace,Lands of Arbitrum,Chainspace,Chains of Nazarov,Blue Lagoon,Swamp,Genesis Cube,Lands of Optimism,Ether Chain,Outerblocks";
    uint256 internal constant originsLength = 16;

    string internal constant bloodlines =
        "O,Wokr,Vmew,Kali-Zui,Zaphthrot,Luban,Yu-Koth,Sturrosh,Ia-Ngai,Khakh,Gyathna,Huacas,Zhar and Lloigor,Xl-rho,Shudde Mell,Crethagu,Unsca Norna,Phvithvre,Yorae,Ydheut,Pa'ch,Waarza,Chhnghu,Shi-Yvgaa,Ximayya Xan,l'Totoxl,Wakan,Ythogtha,Ub-ji,Shuaicha,Sthuma,Senne'll,Xyngogtha";
    uint256 internal constant bloodlinesLength = 33;

    string internal constant perks =
        "3'3,Shitposting,Diamond Bull Horns,Masternode,Front Running,MEV Collector,NFT Flipper,Artblocks Connoisseur ,Diamond Hands,Free Transactions,Made It ,Flash Bundler,Private Relays,Compounding,Galaxy Brain,Low IQ,High IQ,Rugged,Doxxed,Liquidated,Waifu Simp,Exploited,Paper Hands,Flash Loaned,UTXO,Theorist,NGMI,Mid IQ,Copy Trader,Larper,Floor seller,Goxxed,Oyster Forked,Chad Bro,Exit Liquidity,Hacked,Failed Transaction,Black Hat,White Hat,Zero Knowledge";
    uint256 internal constant perksLength = 40;

    string internal constant names =
        "Satoshi,Vitalik,Vlad,Adam,Ailmar,Darfin,Jhaan,Zabbas,Neldor,Gandor,Bellas,Daealla,Nym,Vesryn,Angor,Gogu,Malok,Rotnam,Chalia,Astra,Fabien,Orion,Quintus,Remus,Rorik,Sirius,Sybella,Azura,Dorath,Freya,Ophelia,Yvanna,Zeniya,James,Robert,John,Michael,William,David,Richard,Joseph,Thomas,Charles,Mary,Patricia,Jennifer,Linda,Elizabeth,Kwisatz,Barbara,Susan,Jessica,Sarah,Karen,Dilibe,Eva,Matthew,Bolethe,Polycarp,Ambrogino,Jiri,Chukwuebuka,Chinonyelum,Mikael,Mira,Aniela,Samuel,Isak,Archibaldo,Chinyelu,Kerstin,Abigail,Olympia,Grace,Nahum,Elisabeth,Serge,Sugako,Patrick,Florus,Svatava,Ilona,Lachlan,Caspian,Filippa,Paulo,Darda,Linda,Gradasso,Carly,Jens,Betty,Ebony,Dennis,Martin Davorin,Laura,Jesper,Remy,Onyekachukwu,Jan,Dioscoro,Hilarij,Rosvita,Noah,Patrick,Mohammed,Chinwemma,Raff,Aron,Miguel,Dzemail,Gawel,Gustave,Efraim,Adelbert,Jody,Mackenzie,Victoria,Selam,Jenci,Ulrich,Chishou,Domonkos,Stanislaus,Fortinbras,George,Daniel,Annabelle,Shunichi,Bogdan,Anastazja,Marcus,Monica,Martin,Yuukou,Harriet,Geoffrey,Jonas,Dennis,Hana,Abdelhak,Ravil,Patrick,Karl,Eve,Csilla,Isabella,Radim,Thomas,Faina,Rasmus,Alma,Charles,Chad,Zefram,Hayden,Joseph,Andre,Irene,Molly,Cindy,Su,Stani,Ed,Janet,Cathy,Kyle,Zaki,Belle,Bella,Jessica,Amou,Steven,Olgu,Eva,Ivan,Vllad,Helga,Anya,John,Rita,Evan,Jason,Donald,Tyler,Changpeng,Sam";
    uint256 internal constant namesLength = 187;

    // ===== Components ====

    function creatureComponents(uint256 seed)
        internal
        pure
        returns (uint256[5] memory)
    {
        return pluck(seed, "CREATURE", creaturesLength);
    }

    function itemComponents(uint256 seed)
        internal
        pure
        returns (uint256[5] memory)
    {
        return pluck(seed, "ITEM", itemsLength);
    }

    function originComponents(uint256 seed, bool shadowChain)
        internal
        pure
        returns (uint256[5] memory)
    {
        if (shadowChain) return pluck(seed, "ORIGIN", 5);
        return pluck(seed, "ORIGIN", originsLength);
    }

    function bloodlineComponents(uint256 seed)
        internal
        pure
        returns (uint256[5] memory)
    {
        return pluck(seed, "BLOODLINE", bloodlinesLength);
    }

    function perkComponents(uint256 seed)
        internal
        pure
        returns (uint256[5] memory)
    {
        return pluck(seed, "PERK", perksLength);
    }

    function nameComponents(uint256 seed)
        internal
        pure
        returns (uint256[5] memory)
    {
        return pluck(seed, "NAME", namesLength);
    }

    // ===== Pluck Index Numbers of Raw Materials =====

    /// @notice Uses seed value to get a component
    /// @param seed Pseudorandom number from commit-reveal scheme
    /// @param keyPrefix Type of item being plucked, hashed together with seed
    /// @param sourceCSVLength Length of the array of values
    /// @return New array of values which act as index numbers for respective string csv arrays
    function pluck(
        uint256 seed,
        string memory keyPrefix,
        uint256 sourceCSVLength
    ) internal pure returns (uint256[5] memory) {
        uint256[5] memory components;

        seed = uint256(keccak256(abi.encodePacked(keyPrefix, seed)));

        components[0] = seed % sourceCSVLength;
        components[1] = 0;
        components[2] = 0;

        uint256 greatness = seed % 21;
        if (greatness > 14) {
            components[1] = (seed % suffixesLength) + 1;
        }
        if (greatness >= 19) {
            components[2] = (seed % namePrefixesLength) + 1;
            components[3] = (seed % nameSuffixesLength) + 1;
            if (greatness == 19) {
                // ...
            } else {
                components[4] = 1;
            }
        }

        return components;
    }

    // ===== Get Item from Components =====

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

    // ===== Get Item from Affixes ====

    function getNamePrefixes(uint256 index)
        internal
        pure
        returns (string memory)
    {
        return getItemFromCSV(namePrefixes, index);
    }

    function getNameSuffixes(uint256 index)
        internal
        pure
        returns (string memory)
    {
        return getItemFromCSV(nameSuffixes, index);
    }

    function getSuffixes(uint256 index) internal pure returns (string memory) {
        return getItemFromCSV(suffixes, index);
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "./Components.sol";
import "../TokenId.sol";
import { Base64, toString, trait } from "../MetadataUtils.sol";

/// @title Scans attributes of each component and parses them into traits
/// Flow:
/// 1. encodedId -> components[5] using TokenId.fromId()
/// 2. components[5] -> individual traits of each component
library Scanner {
    using Components for uint256;

    // ===== Attribute Slots =====

    uint256 internal constant CREATURE = 0x0;
    uint256 internal constant ITEM = 0x1;
    uint256 internal constant ORIGIN = 0x2;
    uint256 internal constant BLOODLINE = 0x3;
    uint256 internal constant PERK = 0x4;
    uint256 internal constant NAME = 0x5;

    string internal constant itemTypes =
        "Creature,Item,Origin,Bloodline,Perk,Name";

    // ====== Item Slot Fetcher =====

    /// @return Item at `index` of `itemTypes` csv, i.e. index = 0, item = Creature
    function getItemType(uint256 index) internal pure returns (string memory) {
        return Components.getItemFromCSV(itemTypes, index);
    }

    // ===== Attributes of Item of NFT =====

    /// @notice Parses encodedIds into an array of components, which is stringified
    /// @dev Opensea Standards: https://docs.opensea.io/docs/metadata-standards
    /// @return Attributes of each component of the item string
    function attributes(uint256 id) internal pure returns (string memory) {
        (uint256[5] memory components, uint256 itemType) = TokenId.fromId(id);
        // should we also use components[0] which contains the item name?
        string memory slot = getItemType(itemType);
        string memory res = string(abi.encodePacked("[", trait("Slot", slot)));

        string memory item = base(itemType, components[0]);
        res = string(abi.encodePacked(res, ", ", trait("Item", item)));

        if (components[1] > 0) {
            string memory data = Components.getSuffixes(components[1] - 1);
            res = string(abi.encodePacked(res, ", ", trait("Suffix", data)));
        }

        if (components[2] > 0) {
            string memory data = Components.getNamePrefixes(components[2] - 1);
            res = string(
                abi.encodePacked(res, ", ", trait("Name Prefix", data))
            );
        }

        if (components[3] > 0) {
            string memory data = Components.getNameSuffixes(components[3] - 1);
            res = string(
                abi.encodePacked(res, ", ", trait("Name Suffix", data))
            );
        }

        if (components[4] > 0) {
            res = string(
                abi.encodePacked(res, ", ", trait("Augmentation", "Yes"))
            );
        }

        res = string(abi.encodePacked(res, "]"));

        return res;
    }

    // ===== Gets the Attribute Slot =====

    // Returns the "vanilla" item name w/o any prefix/suffixes or augmentations
    function base(uint256 itemType, uint256 idx)
        internal
        pure
        returns (string memory)
    {
        string memory arr;
        if (itemType == CREATURE) {
            arr = Components.creatures;
        } else if (itemType == ITEM) {
            arr = Components.items;
        } else if (itemType == ORIGIN) {
            arr = Components.origins;
        } else if (itemType == BLOODLINE) {
            arr = Components.bloodlines;
        } else if (itemType == PERK) {
            arr = Components.perks;
        } else if (itemType == NAME) {
            arr = Components.names;
        } else {
            revert("Unexpected property");
        }

        return Components.getItemFromCSV(arr, idx);
    }

    // ===== Components -> Items as strings =====

    /// @notice Creates the token description given its components and what type it is
    function componentsToString(uint256[5] memory components, uint256 itemType)
        internal
        pure
        returns (string memory)
    {
        // item type: what slot to get
        // components[0] the index in the array
        string memory item = base(itemType, components[0]);

        // We need to do -1 because the 'no description' is not part of loot copmonents

        // add the suffix
        if (components[1] > 0) {
            item = string(
                abi.encodePacked(
                    item,
                    " ",
                    Components.getItemFromCSV(
                        Components.suffixes,
                        components[1] - 1
                    )
                )
            );
        }

        // add the name prefix / suffix
        if (components[2] > 0) {
            // prefix
            string memory namePrefixSuffix = string(
                abi.encodePacked(
                    "'",
                    Components.getNamePrefixes(components[2] - 1)
                )
            );
            if (components[3] > 0) {
                namePrefixSuffix = string(
                    abi.encodePacked(
                        namePrefixSuffix,
                        " ",
                        Components.getNameSuffixes(components[3] - 1)
                    )
                );
            }

            namePrefixSuffix = string(abi.encodePacked(namePrefixSuffix, "' "));

            item = string(abi.encodePacked(namePrefixSuffix, item));
        }

        // add the augmentation
        if (components[4] > 0) {
            item = string(abi.encodePacked(item, " +SE"));
        }

        return item;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
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

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

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
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}