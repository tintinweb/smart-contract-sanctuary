// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ISVG image library types interface
/// @dev Allows Solidity files to reference the library's input and return types without referencing the library itself
interface ISVGTypes {

    /// Represents a color in RGB format with alpha
    struct Color {
        uint8 red;
        uint8 green;
        uint8 blue;
        uint8 alpha;
    }

    /// Represents a color attribute in an SVG image file
    enum ColorAttribute {
        Fill, Stroke, Stop
    }

    /// Represents the kind of color attribute in an SVG image file
    enum ColorAttributeKind {
        RGB, URL
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev String operations with decimals
library DecimalStrings {

    /// @dev Converts a `uint256` to its ASCII `string` representation with decimal places.
    function toDecimalString(uint256 value, uint256 decimals, bool isNegative) internal pure returns (bytes memory) {
        // Inspired by OpenZeppelin's implementation - MIT licence
        // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

        uint256 temp = value;
        uint256 characters;
        do {
            characters++;
            temp /= 10;
        } while (temp != 0);
        if (characters <= decimals) {
            characters += 2 + (decimals - characters);
        } else if (decimals > 0) {
            characters += 1;
        }
        temp = isNegative ? 1 : 0; // reuse 'temp' as a sign symbol offset
        characters += temp;
        bytes memory buffer = new bytes(characters);
        while (characters > temp) {
            characters -= 1;
            if (decimals > 0 && (buffer.length - characters - 1) == decimals) {
                buffer[characters] = bytes1(uint8(46));
                decimals = 0; // Cut off any further checks for the decimal place
            } else if (value != 0) {
                buffer[characters] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
            } else {
                buffer[characters] = bytes1(uint8(48));
            }
        }
        if (isNegative) {
            buffer[0] = bytes1(uint8(45));
        }
        return buffer;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "base64-sol/base64.sol";

/// @title OnChain metadata support library
/**
 * @dev These methods are best suited towards view/pure only function calls (ALL the way through the call stack).
 * Do not waste gas using these methods in functions that also update state, unless your need requires it.
 */
library OnChain {

    /// Returns the prefix needed for a base64-encoded on chain svg image
    function baseSvgImageURI() internal pure returns (bytes memory) {
        return "data:image/svg+xml;base64,";
    }

    /// Returns the prefix needed for a base64-encoded on chain nft metadata
    function baseURI() internal pure returns (bytes memory) {
        return "data:application/json;base64,";
    }

    /// Returns the contents joined with a comma between them
    /// @param contents1 The first content to join
    /// @param contents2 The second content to join
    /// @return A collection of bytes that represent all contents joined with a comma
    function commaSeparated(bytes memory contents1, bytes memory contents2) internal pure returns (bytes memory) {
        return abi.encodePacked(contents1, continuesWith(contents2));
    }

    /// Returns the contents joined with commas between them
    /// @param contents1 The first content to join
    /// @param contents2 The second content to join
    /// @param contents3 The third content to join
    /// @return A collection of bytes that represent all contents joined with commas
    function commaSeparated(bytes memory contents1, bytes memory contents2, bytes memory contents3) internal pure returns (bytes memory) {
        return abi.encodePacked(commaSeparated(contents1, contents2), continuesWith(contents3));
    }

    /// Returns the contents joined with commas between them
    /// @param contents1 The first content to join
    /// @param contents2 The second content to join
    /// @param contents3 The third content to join
    /// @param contents4 The fourth content to join
    /// @return A collection of bytes that represent all contents joined with commas
    function commaSeparated(bytes memory contents1, bytes memory contents2, bytes memory contents3, bytes memory contents4) internal pure returns (bytes memory) {
        return abi.encodePacked(commaSeparated(contents1, contents2, contents3), continuesWith(contents4));
    }

    /// Returns the contents joined with commas between them
    /// @param contents1 The first content to join
    /// @param contents2 The second content to join
    /// @param contents3 The third content to join
    /// @param contents4 The fourth content to join
    /// @param contents5 The fifth content to join
    /// @return A collection of bytes that represent all contents joined with commas
    function commaSeparated(bytes memory contents1, bytes memory contents2, bytes memory contents3, bytes memory contents4, bytes memory contents5) internal pure returns (bytes memory) {
        return abi.encodePacked(commaSeparated(contents1, contents2, contents3, contents4), continuesWith(contents5));
    }

    /// Returns the contents joined with commas between them
    /// @param contents1 The first content to join
    /// @param contents2 The second content to join
    /// @param contents3 The third content to join
    /// @param contents4 The fourth content to join
    /// @param contents5 The fifth content to join
    /// @param contents6 The sixth content to join
    /// @return A collection of bytes that represent all contents joined with commas
    function commaSeparated(bytes memory contents1, bytes memory contents2, bytes memory contents3, bytes memory contents4, bytes memory contents5, bytes memory contents6) internal pure returns (bytes memory) {
        return abi.encodePacked(commaSeparated(contents1, contents2, contents3, contents4, contents5), continuesWith(contents6));
    }

    /// Returns the contents prefixed by a comma
    /// @dev This is used to append multiple attributes into the json
    /// @param contents The contents with which to prefix
    /// @return A bytes collection of the contents prefixed with a comma
    function continuesWith(bytes memory contents) internal pure returns (bytes memory) {
        return abi.encodePacked(",", contents);
    }

    /// Returns the contents wrapped in a json dictionary
    /// @param contents The contents with which to wrap
    /// @return A bytes collection of the contents wrapped as a json dictionary
    function dictionary(bytes memory contents) internal pure returns (bytes memory) {
        return abi.encodePacked("{", contents, "}");
    }

    /// Returns an unwrapped key/value pair where the value is an array
    /// @param key The name of the key used in the pair
    /// @param value The value of pair, as an array
    /// @return A bytes collection that is suitable for inclusion in a larger dictionary
    function keyValueArray(string memory key, bytes memory value) internal pure returns (bytes memory) {
        return abi.encodePacked("\"", key, "\":[", value, "]");
    }

    /// Returns an unwrapped key/value pair where the value is a string
    /// @param key The name of the key used in the pair
    /// @param value The value of pair, as a string
    /// @return A bytes collection that is suitable for inclusion in a larger dictionary
    function keyValueString(string memory key, bytes memory value) internal pure returns (bytes memory) {
        return abi.encodePacked("\"", key, "\":\"", value, "\"");
    }

    /// Encodes an SVG as base64 and prefixes it with a URI scheme suitable for on-chain data
    /// @param svg The contents of the svg
    /// @return A bytes collection that may be added to the "image" key/value pair in ERC-721 or ERC-1155 metadata
    function svgImageURI(bytes memory svg) internal pure returns (bytes memory) {
        return abi.encodePacked(baseSvgImageURI(), Base64.encode(svg));
    }

    /// Encodes json as base64 and prefixes it with a URI scheme suitable for on-chain data
    /// @param metadata The contents of the metadata
    /// @return A bytes collection that may be returned as the tokenURI in a ERC-721 or ERC-1155 contract
    function tokenURI(bytes memory metadata) internal pure returns (bytes memory) {
        return abi.encodePacked(baseURI(), Base64.encode(metadata));
    }

    /// Returns the json dictionary of a single trait attribute for an ERC-721 or ERC-1155 NFT
    /// @param name The name of the trait
    /// @param value The value of the trait
    /// @return A collection of bytes that can be embedded within a larger array of attributes
    function traitAttribute(string memory name, bytes memory value) internal pure returns (bytes memory) {
        return dictionary(commaSeparated(
            keyValueString("trait_type", bytes(name)),
            keyValueString("value", value)
        ));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./RandomizationErrors.sol";

/// @title Randomization library
/// @dev Lightweight library used for basic randomization capabilities for ERC-721 tokens when an Oracle is not available
library Randomization {

    /// Returns a value based on the spread of a random uint8 seed and provided percentages
    /// @dev The last percentage is assumed if the sum of all elements do not add up to 100, in which case the length of the array is returned
    /// @param random A uint8 random value
    /// @param percentages An array of percentages
    /// @return The index in which the random seed falls, which can be the length of the input array if the values do not add up to 100
    function randomIndex(uint8 random, uint8[] memory percentages) internal pure returns (uint256) {
        uint256 spread = (3921 * uint256(random) / 10000) % 100; // 0-255 needs to be balanced to evenly spread with % 100
        uint256 remainingPercent = 100;
        for (uint256 i = 0; i < percentages.length; i++) {
            uint256 nextPercentage = percentages[i];
            if (remainingPercent < nextPercentage) revert PercentagesGreaterThan100();
            remainingPercent -= nextPercentage;
            if (spread >= remainingPercent) {
                return i;
            }
        }
        return percentages.length;
    }

    /// Returns a random seed suitable for ERC-721 attribute generation when an Oracle such as Chainlink VRF is not available to a contract
    /// @dev Not suitable for mission-critical code. Always be sure to perform an analysis of your randomization before deploying to production
    /// @param initialSeed A uint256 that seeds the randomization function
    /// @return A seed that can be used for attribute generation, which may also be used as the `initialSeed` for a future call
    function randomSeed(uint256 initialSeed) internal view returns (uint256) {
        // Unit tests should confirm that this provides a more-or-less even spread of randomness
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, initialSeed >> 1)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev When the percentages array sum up to more than 100
error PercentagesGreaterThan100();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../interfaces/ISVGTypes.sol";
import "./OnChain.sol";
import "./SVGErrors.sol";

/// @title SVG image library
/**
 * @dev These methods are best suited towards view/pure only function calls (ALL the way through the call stack).
 * Do not waste gas using these methods in functions that also update state, unless your need requires it.
 */
library SVG {

    using Strings for uint256;

    /// Returns a named element based on the supplied attributes and contents
    /// @dev attributes and contents is usually generated from abi.encodePacked, attributes is expecting a leading space
    /// @param name The name of the element
    /// @param attributes The attributes of the element, as bytes, with a leading space
    /// @param contents The contents of the element, as bytes
    /// @return a bytes collection representing the whole element
    function createElement(string memory name, bytes memory attributes, bytes memory contents) internal pure returns (bytes memory) {
        return abi.encodePacked(
            "<", attributes.length == 0 ? bytes(name) : abi.encodePacked(name, attributes),
            contents.length == 0 ? bytes("/>") : abi.encodePacked(">", contents, "</", name, ">")
        );
    }

    /// Returns the root SVG attributes based on the supplied width and height
    /// @dev includes necessary leading space for createElement's `attributes` parameter
    /// @param width The width of the SVG view box
    /// @param height The height of the SVG view box
    /// @return a bytes collection representing the root SVG attributes, including a leading space
    function svgAttributes(uint256 width, uint256 height) internal pure returns (bytes memory) {
        return abi.encodePacked(" viewBox='0 0 ", width.toString(), " ", height.toString(), "' xmlns='http://www.w3.org/2000/svg'");
    }

    /// Returns an RGB bytes collection suitable as an attribute for SVG elements based on the supplied Color and ColorType
    /// @dev includes necessary leading space for all types _except_ None
    /// @param attribute The `ISVGTypes.ColorAttribute` of the desired attribute
    /// @param value The converted color value as bytes
    /// @return a bytes collection representing a color attribute in an SVG element
    function colorAttribute(ISVGTypes.ColorAttribute attribute, bytes memory value) internal pure returns (bytes memory) {
        if (attribute == ISVGTypes.ColorAttribute.Fill) return _attribute("fill", value);
        if (attribute == ISVGTypes.ColorAttribute.Stop) return _attribute("stop-color", value);
        return  _attribute("stroke", value); // Fallback to Stroke
    }

    /// Returns an RGB color attribute value
    /// @param color The `ISVGTypes.Color` of the color
    /// @return a bytes collection representing the url attribute value
    function colorAttributeRGBValue(ISVGTypes.Color memory color) internal pure returns (bytes memory) {
        return _colorValue(ISVGTypes.ColorAttributeKind.RGB, OnChain.commaSeparated(
            bytes(uint256(color.red).toString()),
            bytes(uint256(color.green).toString()),
            bytes(uint256(color.blue).toString())
        ));
    }

    /// Returns a URL color attribute value
    /// @param url The url to the color
    /// @return a bytes collection representing the url attribute value
    function colorAttributeURLValue(bytes memory url) internal pure returns (bytes memory) {
        return _colorValue(ISVGTypes.ColorAttributeKind.URL, url);
    }

    /// Returns an `ISVGTypes.Color` that is brightened by the provided percentage
    /// @param source The `ISVGTypes.Color` to brighten
    /// @param percentage The percentage of brightness to apply
    /// @param minimumBump A minimum increase for each channel to ensure dark Colors also brighten
    /// @return color the brightened `ISVGTypes.Color`
    function brightenColor(ISVGTypes.Color memory source, uint32 percentage, uint8 minimumBump) internal pure returns (ISVGTypes.Color memory color) {
        color.red = _brightenComponent(source.red, percentage, minimumBump);
        color.green = _brightenComponent(source.green, percentage, minimumBump);
        color.blue = _brightenComponent(source.blue, percentage, minimumBump);
        color.alpha = source.alpha;
    }

    /// Returns an `ISVGTypes.Color` based on a packed representation of r, g, and b
    /// @notice Useful for code where you want to utilize rgb hex values provided by a designer (e.g. #835525)
    /// @dev Alpha will be hard-coded to 100% opacity
    /// @param packedColor The `ISVGTypes.Color` to convert, e.g. 0x835525
    /// @return color representing the packed input
    function fromPackedColor(uint24 packedColor) internal pure returns (ISVGTypes.Color memory color) {
        color.red = uint8(packedColor >> 16);
        color.green = uint8(packedColor >> 8);
        color.blue = uint8(packedColor);
        color.alpha = 0xFF;
    }

    /// Returns a mixed Color by balancing the ratio of `color1` over `color2`, with a total percentage (for overmixing and undermixing outside the source bounds)
    /// @dev Reverts with `RatioInvalid()` if `ratioPercentage` is > 100
    /// @param color1 The first `ISVGTypes.Color` to mix
    /// @param color2 The second `ISVGTypes.Color` to mix
    /// @param ratioPercentage The percentage ratio of `color1` over `color2` (e.g. 60 = 60% first, 40% second)
    /// @param totalPercentage The total percentage after mixing (for overmixing and undermixing outside the input colors)
    /// @return color representing the result of the mixture
    function mixColors(ISVGTypes.Color memory color1, ISVGTypes.Color memory color2, uint32 ratioPercentage, uint32 totalPercentage) internal pure returns (ISVGTypes.Color memory color) {
        if (ratioPercentage > 100) revert RatioInvalid();
        color.red = _mixComponents(color1.red, color2.red, ratioPercentage, totalPercentage);
        color.green = _mixComponents(color1.green, color2.green, ratioPercentage, totalPercentage);
        color.blue = _mixComponents(color1.blue, color2.blue, ratioPercentage, totalPercentage);
        color.alpha = _mixComponents(color1.alpha, color2.alpha, ratioPercentage, totalPercentage);
    }

    /// Returns a proportionally-randomized Color between the start and stop colors using a random Color seed
    /// @dev Each component (r,g,b) will move proportionally together in the direction from start to stop
    /// @param start The starting bound of the `ISVGTypes.Color` to randomize
    /// @param stop The stopping bound of the `ISVGTypes.Color` to randomize
    /// @param random An `ISVGTypes.Color` to use as a seed for randomization
    /// @return color representing the result of the randomization
    function randomizeColors(ISVGTypes.Color memory start, ISVGTypes.Color memory stop, ISVGTypes.Color memory random) internal pure returns (ISVGTypes.Color memory color) {
        uint16 percent = uint16((1320 * (uint(random.red) + uint(random.green) + uint(random.blue)) / 10000) % 101); // Range is from 0-100
        color.red = _randomizeComponent(start.red, stop.red, random.red, percent);
        color.green = _randomizeComponent(start.green, stop.green, random.green, percent);
        color.blue = _randomizeComponent(start.blue, stop.blue, random.blue, percent);
        color.alpha = 0xFF;
    }

    function _attribute(bytes memory name, bytes memory contents) private pure returns (bytes memory) {
        return abi.encodePacked(" ", name, "='", contents, "'");
    }

    function _brightenComponent(uint8 component, uint32 percentage, uint8 minimumBump) private pure returns (uint8 result) {
        uint32 wideComponent = uint32(component);
        uint32 brightenedComponent = wideComponent * (percentage + 100) / 100;
        uint32 wideMinimumBump = uint32(minimumBump);
        if (brightenedComponent - wideComponent < wideMinimumBump) {
            brightenedComponent = wideComponent + wideMinimumBump;
        }
        if (brightenedComponent > 0xFF) {
            result = 0xFF; // Clamp to 8 bits
        } else {
            result = uint8(brightenedComponent);
        }
    }

    function _colorValue(ISVGTypes.ColorAttributeKind attributeKind, bytes memory contents) private pure returns (bytes memory) {
        return abi.encodePacked(attributeKind == ISVGTypes.ColorAttributeKind.RGB ? "rgb(" : "url(#", contents, ")");
    }

    function _mixComponents(uint8 component1, uint8 component2, uint32 ratioPercentage, uint32 totalPercentage) private pure returns (uint8 component) {
        uint32 mixedComponent = (uint32(component1) * ratioPercentage + uint32(component2) * (100 - ratioPercentage)) * totalPercentage / 10000;
        if (mixedComponent > 0xFF) {
            component = 0xFF; // Clamp to 8 bits
        } else {
            component = uint8(mixedComponent);
        }
    }

    function _randomizeComponent(uint8 start, uint8 stop, uint8 random, uint16 percent) private pure returns (uint8 component) {
        if (start == stop) {
            component = start;
        } else { // This is the standard case
            (uint8 floor, uint8 ceiling) = start < stop ? (start, stop) : (stop, start);
            component = floor + uint8(uint16(ceiling - (random & 0x01) - floor) * percent / uint16(100));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev When the ratio percentage provided to a function is > 100
error RatioInvalid();

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Gen 3 TwoBitBear traits
/// @notice Describes the traits of a Gen 3 TwoBitBear
interface IBear3Traits {

    /// Represents the backgrounds of a Gen 3 TwoBitBear
    enum BackgroundType {
        White, Green, Blue
    }

    /// Represents the scars of a Gen 3 TwoBitBear
    enum ScarColor {
        None, Blue, Magenta, Gold
    }

    /// Represents the species of a Gen 3 TwoBitBear
    enum SpeciesType {
        Brown, Black, Polar, Panda
    }

    /// Represents the mood of a Gen 3 TwoBitBear
    enum MoodType {
        Happy, Hungry, Sleepy, Grumpy, Cheerful, Excited, Snuggly, Confused, Ravenous, Ferocious, Hangry, Drowsy, Cranky, Furious
    }

    /// Represents the traits of a Gen 3 TwoBitBear
    struct Traits {
        BackgroundType background;
        MoodType mood;
        SpeciesType species;
        bool gen4Claimed;
        uint8 nameIndex;
        uint8 familyIndex;
        uint16 firstParentTokenId;
        uint16 secondParentTokenId;
        uint176 genes;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBear3Traits.sol";

/// @title Main Tech for Gen 3 TwoBitBear rendering
/// @dev Supports the ERC-721 contract
interface IBearRenderTech {

    /// Returns the text of a background based on the supplied type
    /// @param background The BackgroundType
    /// @return The background text
    function backgroundForType(IBear3Traits.BackgroundType background) external pure returns (string memory);

    /// Creates the SVG for a Gen 3 TwoBitBear given its IBear3Traits.Traits and Token Id
    /// @dev Passes rendering on to a specific species' IBearRenderer
    /// @param traits The Bear's traits structure
    /// @param tokenId The Bear's Token Id
    /// @return The raw xml as bytes
    function createSvg(IBear3Traits.Traits memory traits, uint256 tokenId) external view returns (bytes memory);

    /// Returns the family of a Gen 3 TwoBitBear as a string
    /// @param traits The Bear's traits structure
    /// @return The family text
    function familyForTraits(IBear3Traits.Traits memory traits) external view returns (string memory);

    /// @dev Returns the ERC-721 for a Gen 3 TwoBitBear given its IBear3Traits.Traits and Token Id
    /// @param traits The Bear's traits structure
    /// @param tokenId The Bear's Token Id
    /// @return The raw json as bytes
    function metadata(IBear3Traits.Traits memory traits, uint256 tokenId) external view returns (bytes memory);

    /// Returns the text of a mood based on the supplied type
    /// @param mood The MoodType
    /// @return The mood text
    function moodForType(IBear3Traits.MoodType mood) external pure returns (string memory);

    /// Returns the name of a Gen 3 TwoBitBear as a string
    /// @param traits The Bear's traits structure
    /// @return The name text
    function nameForTraits(IBear3Traits.Traits memory traits) external view returns (string memory);

    /// Returns the scar colors of a bear with the provided traits
    /// @param traits The Bear's traits structure
    /// @return The array of scar colors
    function scarsForTraits(IBear3Traits.Traits memory traits) external view returns (IBear3Traits.ScarColor[] memory);

    /// Returns the text of a scar based on the supplied color
    /// @param scarColor The ScarColor
    /// @return The scar color text
    function scarForType(IBear3Traits.ScarColor scarColor) external pure returns (string memory);

    /// Returns the text of a species based on the supplied type
    /// @param species The SpeciesType
    /// @return The species text
    function speciesForType(IBear3Traits.SpeciesType species) external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IBear3Traits.sol";

/// @title Bear RenderTech provider
/// @dev Provides IBearRenderTech to an IBearRenderer
interface IBearRenderTechProvider {

    /// Represents a point substitution
    struct Substitution {
        uint matchingX;
        uint matchingY;
        uint replacementX;
        uint replacementY;
    }

    /// Generates an SVG <polygon> element based on a points array and fill color
    /// @param points The encoded points array
    /// @param fill The fill attribute
    /// @param substitutions An array of point substitutions
    /// @return A <polygon> element as bytes
    function dynamicPolygonElement(bytes memory points, bytes memory fill, Substitution[] memory substitutions) external view returns (bytes memory);

    /// Generates an SVG <linearGradient> element based on a points array and stop colors
    /// @param id The id of the linear gradient
    /// @param points The encoded points array
    /// @param stop1 The first stop attribute
    /// @param stop2 The second stop attribute
    /// @return A <linearGradient> element as bytes
    function linearGradient(bytes memory id, bytes memory points, bytes memory stop1, bytes memory stop2) external view returns (bytes memory);

    /// Generates an SVG <path> element based on a points array and fill color
    /// @param path The encoded path array
    /// @param fill The fill attribute
    /// @return A <path> segment as bytes
    function pathElement(bytes memory path, bytes memory fill) external view returns (bytes memory);

    /// Generates an SVG <polygon> segment based on a points array and fill colors
    /// @param points The encoded points array
    /// @param fill The fill attribute
    /// @return A <polygon> segment as bytes
    function polygonElement(bytes memory points, bytes memory fill) external view returns (bytes memory);

    /// Generates an SVG <rect> element based on a points array and fill color
    /// @param widthPercentage The width expressed as a percentage of its container
    /// @param heightPercentage The height expressed as a percentage of its container
    /// @param attributes Additional attributes for the <rect> element
    /// @return A <rect> element as bytes
    function rectElement(uint256 widthPercentage, uint256 heightPercentage, bytes memory attributes) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@theappstudio/solidity/contracts/interfaces/ISVGTypes.sol";
import "./IBear3Traits.sol";
import "./ICubTraits.sol";

/// @title Gen 3 TwoBitBear Renderer
/// @dev Renders a specific species of a Gen 3 TwoBitBear
interface IBearRenderer {

    /// The eye ratio to apply based on the genes and token id
    /// @param genes The Bear's genes
    /// @param eyeColor The Bear's eye color
    /// @param scars Zero, One, or Two ScarColors
    /// @param tokenId The Bear's Token Id
    /// @return The eye ratio as a uint8
    function customDefs(uint176 genes, ISVGTypes.Color memory eyeColor, IBear3Traits.ScarColor[] memory scars, uint256 tokenId) external view returns (bytes memory);

    /// Influences the eye color given the dominant parent
    /// @param dominantParent The Dominant parent bear
    /// @return The eye color
    function customEyeColor(ICubTraits.TraitsV1 memory dominantParent) external view returns (ISVGTypes.Color memory);

    /// The eye ratio to apply based on the genes and token id
    /// @param genes The Bear's genes
    /// @param eyeColor The Bear's eye color
    /// @param tokenId The Bear's Token Id
    /// @return The eye ratio as a uint8
    function customSurfaces(uint176 genes, ISVGTypes.Color memory eyeColor, uint256 tokenId) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ICubTraits.sol";

/// @title TwoBitCubs NFT Interface for provided ICubTraits
interface ICubTraitProvider{

    /// Returns the family of a TwoBitCub as a string
    /// @param traits The traits of the Cub
    /// @return The family text
    function familyForTraits(ICubTraits.TraitsV1 memory traits) external pure returns (string memory);

    /// Returns the text of a mood based on the supplied type
    /// @param moodType The CubMoodType
    /// @return The mood text
    function moodForType(ICubTraits.CubMoodType moodType) external pure returns (string memory);

    /// Returns the mood of a TwoBitCub based on its TwoBitBear parents
    /// @param firstParentTokenId The ID of the token that represents the first parent
    /// @param secondParentTokenId The ID of the token that represents the second parent
    /// @return The mood type
    function moodFromParents(uint256 firstParentTokenId, uint256 secondParentTokenId) external view returns (ICubTraits.CubMoodType);

    /// Returns the name of a TwoBitCub as a string
    /// @param traits The traits of the Cub
    /// @return The name text
    function nameForTraits(ICubTraits.TraitsV1 memory traits) external pure returns (string memory);

    /// Returns the text of a species based on the supplied type
    /// @param speciesType The CubSpeciesType
    /// @return The species text
    function speciesForType(ICubTraits.CubSpeciesType speciesType) external pure returns (string memory);

    /// Returns the v1 traits associated with a given token ID.
    /// @dev Throws if the token ID is not valid.
    /// @param tokenId The ID of the token that represents the Cub
    /// @return traits memory
    function traitsV1(uint256 tokenId) external view returns (ICubTraits.TraitsV1 memory traits);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@theappstudio/solidity/contracts/interfaces/ISVGTypes.sol";

/// @title ICubTraits interface
interface ICubTraits {

    /// Represents the species of a TwoBitCub
    enum CubSpeciesType {
        Brown, Black, Polar, Panda
    }

    /// Represents the mood of a TwoBitCub
    enum CubMoodType {
        Happy, Hungry, Sleepy, Grumpy, Cheerful, Excited, Snuggly, Confused, Ravenous, Ferocious, Hangry, Drowsy, Cranky, Furious
    }

    /// Represents the DNA for a TwoBitCub
    /// @dev organized to fit within 256 bits and consume the least amount of resources
    struct DNA {
        uint16 firstParentTokenId;
        uint16 secondParentTokenId;
        uint224 genes;
    }

    /// Represents the v1 traits of a TwoBitCub
    struct TraitsV1 {
        uint256 age;
        ISVGTypes.Color topColor;
        ISVGTypes.Color bottomColor;
        uint8 nameIndex;
        uint8 familyIndex;
        CubMoodType mood;
        CubSpeciesType species;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "../interfaces/ICubTraitProvider.sol";

/// @title TwoBitCubs
abstract contract TwoBitCubs is IERC721Enumerable, ICubTraitProvider {

    /// @dev The number of blocks until a growing cub becomes an adult (roughly 1 week)
    uint256 public constant ADULT_AGE = 44000;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@theappstudio/solidity/contracts/utils/DecimalStrings.sol";
import "@theappstudio/solidity/contracts/utils/OnChain.sol";
import "@theappstudio/solidity/contracts/utils/Randomization.sol";
import "@theappstudio/solidity/contracts/utils/SVG.sol";
import "./BearRenderTechErrors.sol";
import "../interfaces/ICubTraits.sol";
import "../interfaces/IBear3Traits.sol";
import "../interfaces/IBearRenderer.sol";
import "../interfaces/IBearRenderTech.sol";
import "../interfaces/IBearRenderTechProvider.sol";
import "../tokens/TwoBitCubs.sol";

/// @title BearRendering3
contract BearRenderTech is Ownable, IBearRenderTech, IBearRenderTechProvider {

    using Strings for uint256;
    using DecimalStrings for uint256;

    /// Represents an encoding of a number
    struct NumberEncoding {
        uint8 bytesPerPoint;
        uint8 decimals;
        bool signed;
    }

    /// @dev The Black Bear SVG renderer
    IBearRenderer private _blackBearRenderer;

    /// @dev The Brown Bear SVG renderer
    IBearRenderer private _brownBearRenderer;

    /// @dev The Panda Bear SVG renderer
    IBearRenderer private _pandaBearRenderer;

    /// @dev The Polar Bear SVG renderer
    IBearRenderer private _polarBearRenderer;

    /// @dev Reference to the TwoBitCubs contract
    TwoBitCubs private immutable _twoBitCubs;

    /// @dev Controls the reveal
    bool private _wenReveal;

    /// Look...at these...Bears
    constructor(address twoBitCubs) {
        _twoBitCubs = TwoBitCubs(twoBitCubs);
    }

    /// Applies the four IBearRenderers
    /// @param blackRenderer The Black Bear renderer
    /// @param brownRenderer The Brown Bear renderer
    /// @param pandaRenderer The Panda Bear renderer
    /// @param polarRenderer The Polar Bear renderer
    function applyRenderers(address blackRenderer, address brownRenderer, address pandaRenderer, address polarRenderer) external onlyOwner {
        if (address(_blackBearRenderer) != address(0) ||
            address(_brownBearRenderer) != address(0) ||
            address(_pandaBearRenderer) != address(0) ||
            address(_polarBearRenderer) != address(0)) revert AlreadyConfigured();
        _blackBearRenderer = IBearRenderer(blackRenderer);
        _brownBearRenderer = IBearRenderer(brownRenderer);
        _pandaBearRenderer = IBearRenderer(pandaRenderer);
        _polarBearRenderer = IBearRenderer(polarRenderer);
    }

    function backgroundForType(IBear3Traits.BackgroundType background) public pure returns (string memory) {
        string[3] memory backgrounds = ["White Tundra", "Green Forest", "Blue Shore"];
        return backgrounds[uint(background)];
    }

    /// @inheritdoc IBearRenderTech
    function createSvg(IBear3Traits.Traits memory traits, uint256 tokenId) public view onlyWenRevealed returns (bytes memory) {
        IBearRenderer renderer = _rendererForTraits(traits);
        ISVGTypes.Color memory eyeColor = renderer.customEyeColor(_twoBitCubs.traitsV1(traits.firstParentTokenId));
        return SVG.createElement("svg", SVG.svgAttributes(447, 447), abi.encodePacked(
            _defs(renderer, traits, eyeColor, tokenId),
            this.rectElement(100, 100, " fill='url(#background)'"),
            this.pathElement(hex'224d76126b084c81747bfb4381f57cdd821c7de981df7ee74381a37fe5810880c2802f81514c5b3b99a8435a359a5459049aaf57cc9ab0569ab04356939ab055619a55545b99a94c2f678151432e8e80c22df37fe52db77ee7432d7b7de92da17cdd2e227bfb4c39846b0a4c57ca6b0a566b084c76126b085a', "url(#chest)"),
            this.polygonElement(hex'1207160d0408bc0da20a620d040c0a0a9b08bc0a9b056e0a9b', "url(#neck)"),
            renderer.customSurfaces(traits.genes, eyeColor, tokenId)
        ));
    }

    /// @inheritdoc IBearRenderTechProvider
    function dynamicPolygonElement(bytes memory points, bytes memory fill, Substitution[] memory substitutions) external view onlyRenderer returns (bytes memory) {
        return SVG.createElement("polygon", abi.encodePacked(" points='", _polygonPoints(points, substitutions), "' fill='", fill, "'"), "");
    }

    /// @inheritdoc IBearRenderTech
    function familyForTraits(IBear3Traits.Traits memory traits) public view override onlyWenRevealed returns (string memory) {
        string[18] memory families = ["Hirst", "Stark", "xCopy", "Watkinson", "Davis", "Evan Dennis", "Anderson", "Pak", "Greenawalt", "Capacity", "Hobbs", "Deafbeef", "Rainaud", "Snowfro", "Winkelmann", "Fairey", "Nines", "Maeda"];
        return families[(uint(uint8(bytes22(traits.genes)[1])) + uint(traits.familyIndex)) % 18];
    }

    /// @inheritdoc IBearRenderTechProvider
    function linearGradient(bytes memory id, bytes memory points, bytes memory stop1, bytes memory stop2) external view onlyRenderer returns (bytes memory) {
        string memory stop = "stop";
        NumberEncoding memory encoding = _readEncoding(points);
        bytes memory attributes = abi.encodePacked(
            " id='", id,
            "' x1='", _decimalStringFromBytes(points, 1, encoding),
            "' x2='", _decimalStringFromBytes(points, 1 + encoding.bytesPerPoint, encoding),
            "' y1='", _decimalStringFromBytes(points, 1 + 2 * encoding.bytesPerPoint, encoding),
            "' y2='", _decimalStringFromBytes(points, 1 + 3 * encoding.bytesPerPoint, encoding), "'"
        );
        return SVG.createElement("linearGradient", attributes, abi.encodePacked(
            SVG.createElement(stop, stop1, ""), SVG.createElement(stop, stop2, "")
        ));
    }

    /// @inheritdoc IBearRenderTech
    function metadata(IBear3Traits.Traits memory traits, uint256 tokenId) external view returns (bytes memory) {
        string memory token = tokenId.toString();
        if (_wenReveal) {
            return OnChain.dictionary(OnChain.commaSeparated(
                OnChain.keyValueString("name", abi.encodePacked(nameForTraits(traits), " ", familyForTraits(traits), " the ", moodForType(traits.mood), " ", speciesForType(traits.species), " Bear ", token)),
                OnChain.keyValueArray("attributes", _attributesFromTraits(traits)),
                OnChain.keyValueString("image", OnChain.svgImageURI(bytes(createSvg(traits, tokenId))))
            ));
        }
        return OnChain.dictionary(OnChain.commaSeparated(
            OnChain.keyValueString("name", abi.encodePacked("Rendering Bear ", token)),
            OnChain.keyValueString("image", "ipfs://QmUZ3ojSLv3rbu8egkS5brb4ETkNXXmcgCFG66HeFBXn54")
        ));
    }

    /// @inheritdoc IBearRenderTech
    function moodForType(IBear3Traits.MoodType mood) public pure override returns (string memory) {
        string[14] memory moods = ["Happy", "Hungry", "Sleepy", "Grumpy", "Cheerful", "Excited", "Snuggly", "Confused", "Ravenous", "Ferocious", "Hangry", "Drowsy", "Cranky", "Furious"];
        return moods[uint256(mood)];
    }

    /// @inheritdoc IBearRenderTech
    function nameForTraits(IBear3Traits.Traits memory traits) public view override onlyWenRevealed returns (string memory) {
        string[50] memory names = ["Cophi", "Trace", "Abel", "Ekko", "Goomba", "Milk", "Arth", "Roeleman", "Adjudicator", "Kelly", "Tropo", "Type3", "Jak", "Srsly", "Triggity", "SNR", "Drogate", "Scott", "Timm", "Nutsaw", "Rugged", "Vaypor", "XeR0", "Toasty", "BN3", "Dunks", "JFH", "Eallen", "Aspen", "Krueger", "Nouside", "Fonky", "Ian", "Metal", "Bones", "Cruz", "Daniel", "Buz", "Bliargh", "Strada", "Lanky", "Westwood", "Rie", "Moon", "Mango", "Hammer", "Pizza", "Java", "Gremlin", "Hash"];
        return names[(uint(uint8(bytes22(traits.genes)[0])) + uint(traits.nameIndex)) % 50];
    }

    /// Prevents a function from executing if not called by an authorized party
    modifier onlyRenderer() {
        if (_msgSender() != address(_blackBearRenderer) &&
            _msgSender() != address(_brownBearRenderer) &&
            _msgSender() != address(_pandaBearRenderer) &&
            _msgSender() != address(_polarBearRenderer) &&
            _msgSender() != address(this)) revert OnlyRenderer();
        _;
    }

    /// Prevents a function from executing until wenReveal is set
    modifier onlyWenRevealed() {
        if (!_wenReveal) revert NotYetRevealed();
        _;
    }

    /// @inheritdoc IBearRenderTechProvider
    function pathElement(bytes memory path, bytes memory fill) external view onlyRenderer returns (bytes memory result) {
        NumberEncoding memory encoding = _readEncoding(path);
        bytes memory attributes = " d='";
        uint index = 1;
        while (index < path.length) {
            bytes1 control = path[index++];
            attributes = abi.encodePacked(attributes, control);
            if (control == "C") {
                attributes = abi.encodePacked(attributes, _readNext(path, encoding, 6, index));
                index += 6 * encoding.bytesPerPoint;
            } else if (control == "H") { // Not used by any IBearRenderers anymore
                attributes = abi.encodePacked(attributes, _readNext(path, encoding, 1, index));
                index += encoding.bytesPerPoint;
            } else if (control == "L") {
                attributes = abi.encodePacked(attributes, _readNext(path, encoding, 2, index));
                index += 2 * encoding.bytesPerPoint;
            } else if (control == "M") {
                attributes = abi.encodePacked(attributes, _readNext(path, encoding, 2, index));
                index += 2 * encoding.bytesPerPoint;
            } else if (control == "V") {
                attributes = abi.encodePacked(attributes, _readNext(path, encoding, 1, index));
                index += encoding.bytesPerPoint;
            }
        }
        return SVG.createElement("path", abi.encodePacked(attributes, "' fill='", fill, "'"), "");
    }

    /// @inheritdoc IBearRenderTechProvider
    function polygonElement(bytes memory points, bytes memory fill) external view onlyRenderer returns (bytes memory) {
        return SVG.createElement("polygon", abi.encodePacked(" points='", _polygonPoints(points, new Substitution[](0)), "' fill='", fill, "'"), "");
    }

    /// @inheritdoc IBearRenderTechProvider
    function rectElement(uint256 widthPercentage, uint256 heightPercentage, bytes memory attributes) external view onlyRenderer returns (bytes memory) {
        return abi.encodePacked("<rect width='", widthPercentage.toString(), "%' height='", heightPercentage.toString(), "%'", attributes, "/>");
    }

    /// Wen the world is ready
    /// @dev Only the contract owner can invoke this
    function revealBears() external onlyOwner {
        _wenReveal = true;
    }

    /// @inheritdoc IBearRenderTech
    function scarsForTraits(IBear3Traits.Traits memory traits) public view onlyWenRevealed returns (IBear3Traits.ScarColor[] memory) {
        bytes22 geneBytes = bytes22(traits.genes);
        uint8 scarCountProvider = uint8(geneBytes[18]);
        uint scarCount = Randomization.randomIndex(scarCountProvider, _scarCountPercentages());
        IBear3Traits.ScarColor[] memory scars = new IBear3Traits.ScarColor[](scarCount == 0 ? 1 : scarCount);
        if (scarCount == 0) {
            scars[0] = IBear3Traits.ScarColor.None;
        } else {
            uint8 scarColorProvider = uint8(geneBytes[17]);
            uint scarColor = Randomization.randomIndex(scarColorProvider, _scarColorPercentages());
            for (uint scar = 0; scar < scarCount; scar++) {
                scars[scar] = IBear3Traits.ScarColor(scarColor+1);
            }
        }
        return scars;
    }

    /// @inheritdoc IBearRenderTech
    function scarForType(IBear3Traits.ScarColor scarColor) public pure override returns (string memory) {
        string[4] memory scarColors = ["None", "Blue", "Magenta", "Gold"];
        return scarColors[uint256(scarColor)];
    }

    /// @inheritdoc IBearRenderTech
    function speciesForType(IBear3Traits.SpeciesType species) public pure override returns (string memory) {
        string[4] memory specieses = ["Brown", "Black", "Polar", "Panda"];
        return specieses[uint256(species)];
    }

    function _attributesFromTraits(IBear3Traits.Traits memory traits) private view returns (bytes memory) {
        bytes memory attributes = OnChain.commaSeparated(
            OnChain.traitAttribute("Species", bytes(speciesForType(traits.species))),
            OnChain.traitAttribute("Mood", bytes(moodForType(traits.mood))),
            OnChain.traitAttribute("Background", bytes(backgroundForType(traits.background))),
            OnChain.traitAttribute("First Name", bytes(nameForTraits(traits))),
            OnChain.traitAttribute("Last Name (Gen 4 Scene)", bytes(familyForTraits(traits))),
            OnChain.traitAttribute("Parents", abi.encodePacked("#", uint(traits.firstParentTokenId).toString(), " & #", uint(traits.secondParentTokenId).toString()))
        );
        bytes memory scarAttributes = OnChain.traitAttribute("Scars", _scarDescription(scarsForTraits(traits)));
        attributes = abi.encodePacked(attributes, OnChain.continuesWith(scarAttributes));
        bytes memory gen4Attributes = OnChain.traitAttribute("Gen 4 Claim Status", bytes(traits.gen4Claimed ? "Claimed" : "Unclaimed"));
        return abi.encodePacked(attributes, OnChain.continuesWith(gen4Attributes));
    }

    function _decimalStringFromBytes(bytes memory encoded, uint startIndex, NumberEncoding memory encoding) private pure returns (bytes memory) {
        (uint value, bool isNegative) = _uintFromBytes(encoded, startIndex, encoding);
        return value.toDecimalString(encoding.decimals, isNegative);
    }

    function _defs(IBearRenderer renderer, IBear3Traits.Traits memory traits, ISVGTypes.Color memory eyeColor, uint256 tokenId) private view returns (bytes memory) {
        string[3] memory firstStop = ["#fff", "#F3FCEE", "#EAF4F9"];
        string[3] memory lastStop = ["#9C9C9C", "#A6B39E", "#98ADB5"];
        return SVG.createElement("defs", "", abi.encodePacked(
            this.linearGradient("background", hex'32000003ea000003e6',
                abi.encodePacked(" offset='0.44521' stop-color='", firstStop[uint(traits.background)], "'"),
                abi.encodePacked(" offset='0.986697' stop-color='", lastStop[uint(traits.background)], "'")
            ),
            renderer.customDefs(traits.genes, eyeColor, scarsForTraits(traits), tokenId)
        ));
    }

    function _polygonCoordinateFromBytes(bytes memory encoded, uint startIndex, NumberEncoding memory encoding, Substitution[] memory substitutions) private pure returns (bytes memory) {
        (uint x, bool xIsNegative) = _uintFromBytes(encoded, startIndex, encoding);
        (uint y, bool yIsNegative) = _uintFromBytes(encoded, startIndex + encoding.bytesPerPoint, encoding);
        for (uint index = 0; index < substitutions.length; index++) {
            if (x == substitutions[index].matchingX && y == substitutions[index].matchingY) {
                x = substitutions[index].replacementX;
                y = substitutions[index].replacementY;
                break;
            }
        }
        return OnChain.commaSeparated(x.toDecimalString(encoding.decimals, xIsNegative), y.toDecimalString(encoding.decimals, yIsNegative));
    }

    function _polygonPoints(bytes memory points, Substitution[] memory substitutions) private pure returns (bytes memory pointsValue) {
        NumberEncoding memory encoding = _readEncoding(points);

        pointsValue = abi.encodePacked(_polygonCoordinateFromBytes(points, 1, encoding, substitutions));
        uint bytesPerIteration = encoding.bytesPerPoint << 1; // Double because this method processes 2 points at a time
        for (uint byteIndex = 1 + bytesPerIteration; byteIndex < points.length; byteIndex += bytesPerIteration) {
            pointsValue = abi.encodePacked(pointsValue, " ", _polygonCoordinateFromBytes(points, byteIndex, encoding, substitutions));
        }
    }

    function _readEncoding(bytes memory encoded) private pure returns (NumberEncoding memory encoding) {
        encoding.decimals = uint8(encoded[0] >> 4) & 0xF;
        encoding.bytesPerPoint = uint8(encoded[0]) & 0x7;
        encoding.signed = uint8(encoded[0]) & 0x8 == 0x8;
    }

    function _readNext(bytes memory encoded, NumberEncoding memory encoding, uint numbers, uint startIndex) private pure returns (bytes memory result) {
        result = _decimalStringFromBytes(encoded, startIndex, encoding);
        for (uint index = startIndex + encoding.bytesPerPoint; index < startIndex + (numbers * encoding.bytesPerPoint); index += encoding.bytesPerPoint) {
            result = abi.encodePacked(result, " ", _decimalStringFromBytes(encoded, index, encoding));
        }
    }

    function _rendererForTraits(IBear3Traits.Traits memory traits) private view returns (IBearRenderer) {
        if (traits.species == IBear3Traits.SpeciesType.Black) {
            return _blackBearRenderer;
        } else if (traits.species == IBear3Traits.SpeciesType.Brown) {
            return _brownBearRenderer;
        } else if (traits.species == IBear3Traits.SpeciesType.Panda) {
            return _pandaBearRenderer;
        } else /* if (traits.species == IBear3Traits.SpeciesType.Polar) */ {
            return _polarBearRenderer;
        }
    }

    function _scarColorPercentages() private pure returns (uint8[] memory percentages) {
        uint8[] memory array = new uint8[](2);
        array[0] = 60; // 60% Blue
        array[1] = 30; // 30% Magenta
        return array; // 10% Gold
    }

    function _scarCountPercentages() private pure returns (uint8[] memory percentages) {
        uint8[] memory array = new uint8[](2);
        array[0] = 70; // 70% None
        array[1] = 20; // 20% One
        return array; // 10% Two
    }

    function _scarDescription(IBear3Traits.ScarColor[] memory scarColors) private pure returns (bytes memory) {
        if (scarColors.length == 0 || scarColors[0] == IBear3Traits.ScarColor.None) {
            return bytes(scarForType(IBear3Traits.ScarColor.None));
        } else {
            return abi.encodePacked(scarColors.length.toString(), " ", scarForType(scarColors[0]));
        }
    }

    function _uintFromBytes(bytes memory encoded, uint startIndex, NumberEncoding memory encoding) private pure returns (uint result, bool isNegative) {
        result = uint8(encoded[startIndex]);
        if (encoding.signed) {
            isNegative = result & 0x80 == 0x80;
            result &= 0x7F;
        }
        uint stopIndex = startIndex + encoding.bytesPerPoint;
        for (uint index = startIndex + 1; index < stopIndex; index++) {
            result = (result << 8) + uint(uint8(encoded[index]));
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev When the renderers are already configured
error AlreadyConfigured();

/// @dev When Reveal is false
error NotYetRevealed();

/// @dev Only the Renderer can make these calls
error OnlyRenderer();