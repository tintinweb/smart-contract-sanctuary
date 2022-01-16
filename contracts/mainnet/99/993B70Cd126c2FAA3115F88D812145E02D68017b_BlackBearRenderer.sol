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
pragma solidity ^0.8.4;

import "@theappstudio/solidity/contracts/utils/DecimalStrings.sol";
import "@theappstudio/solidity/contracts/utils/SVG.sol";
import "./BearRendererErrors.sol";
import "../interfaces/IBearRenderer.sol";
import "../interfaces/IBearRenderTech.sol";
import "../interfaces/IBearRenderTechProvider.sol";

/// @title Base IBearRenderer
abstract contract BearRenderer is IBearRenderer {

    using Strings for uint256;

    /// @dev The IBearRenderTechProvider for this IBearRenderer
    IBearRenderTechProvider internal immutable _renderTech;

    /// @dev Constructs a new instance passing in the IBearRenderTechProvider
    constructor(address renderTech) {
        _renderTech = IBearRenderTechProvider(renderTech);
    }

    /// The ear ratio to apply based on the genes and token id
    /// @param geneBytes The Bear's genes as bytes22
    /// @param tokenId The Bear's Token Id
    /// @return ratio The ear ratio as a uint
    function earRatio(bytes22 geneBytes, uint256 tokenId) internal pure returns (uint ratio) {
        ratio = uint8(geneBytes[(tokenId + 21) % 22]);
    }

    /// The eye ratio to apply based on the genes and token id
    /// @param geneBytes The Bear's genes as bytes22
    /// @param tokenId The Bear's Token Id
    /// @return The eye ratio as a uint8
    function eyeRatio(bytes22 geneBytes, uint256 tokenId) internal pure returns (uint8) {
        return uint8(geneBytes[(tokenId + 20) % 22]);
    }

    /// The jowl ratio to apply based on the genes and token id
    /// @param geneBytes The Bear's genes as bytes22
    /// @param tokenId The Bear's Token Id
    /// @return The jowl ratio as a uint8
    function jowlRatio(bytes22 geneBytes, uint256 tokenId) internal pure returns (uint8) {
        return uint8(geneBytes[(tokenId + 19) % 22]);
    }

    /// Prevents a function from executing if not called by the IBearRenderTechProvider
    modifier onlyRenderTech() {
        if (msg.sender != address(_renderTech)) revert OnlyBearRenderTech();
        _;
    }

    function _assignScars(uint surfaceCount, IBear3Traits.ScarColor[] memory scars, bytes22 genes, uint256 tokenId) internal pure returns (IBear3Traits.ScarColor[] memory initializedScars) {
        initializedScars = new IBear3Traits.ScarColor[](surfaceCount);
        uint scarIndex = scars.length;
        for (uint i = 0; i < surfaceCount; i++) {
            if (scarIndex > 0 && scars[0] != IBear3Traits.ScarColor.None) {
                // The further we get, the more likely we assign the next scar (i.e. decrease the divisor)
                uint random = uint8(genes[(tokenId+i) % 18]);
                uint remaining = 1 + surfaceCount - i;
                if (random % remaining <= 1) { // Give our modulo a little push with <=
                    initializedScars[i] = scars[--scarIndex];
                    continue;
                }
            }
            initializedScars[i] = IBear3Traits.ScarColor.None;
        }
    }

    function _firstStop(ISVGTypes.Color memory color) internal pure returns (bytes memory) {
        return abi.encodePacked(" stop-color='", SVG.colorAttributeRGBValue(color) , "'");
    }

    function _firstStopPacked(uint24 packedColor) internal pure returns (bytes memory) {
        return _firstStop(SVG.fromPackedColor(packedColor));
    }

    function _lastStop(ISVGTypes.Color memory color) internal pure returns (bytes memory) {
        return abi.encodePacked(" offset='1' stop-color='", SVG.colorAttributeRGBValue(color) , "'");
    }

    function _lastStopPacked(uint24 packedColor) internal pure returns (bytes memory) {
        return _lastStop(SVG.fromPackedColor(packedColor));
    }

    function _scarColor(IBear3Traits.ScarColor scarColor) internal pure returns (ISVGTypes.Color memory, ISVGTypes.Color memory) {
        if (scarColor == IBear3Traits.ScarColor.Blue) {
            return (SVG.fromPackedColor(0x1795BA), SVG.fromPackedColor(0x9CF3FF));
        } else if (scarColor == IBear3Traits.ScarColor.Magenta) {
            return (SVG.fromPackedColor(0x9D143E), SVG.fromPackedColor(0xDB3F74));
        } else /* if (scarColor == IBear3Traits.ScarColor.Gold) */ {
            return (SVG.fromPackedColor(0xA06E01), SVG.fromPackedColor(0xFFC701));
        }
    }

    function _surfaceGradient(uint id, bytes memory points, uint24 firstStop, uint24 lastStop, IBear3Traits.ScarColor[] memory assignedScars) internal view returns (bytes memory) {
        bytes memory identifier = abi.encodePacked("paint", id.toString());
        if (assignedScars[id] == IBear3Traits.ScarColor.None) {
            return _renderTech.linearGradient(identifier, points, _firstStopPacked(firstStop), _lastStopPacked(lastStop));
        }
        (ISVGTypes.Color memory lower, ISVGTypes.Color memory higher) = _scarColor(assignedScars[id]);
        (ISVGTypes.Color memory first, ISVGTypes.Color memory last) = firstStop < lastStop ? (lower, higher) : (higher, lower);
        return _renderTech.linearGradient(identifier, points, _firstStop(first), _lastStop(last));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev When the caller is not the `IBearRenderTechProvider`
error OnlyBearRenderTech();

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./BearRenderer.sol";

/// @title BlackBearRenderer
contract BlackBearRenderer is BearRenderer {

    using DecimalStrings for uint256;

    // solhint-disable-next-line no-empty-blocks
    constructor(address renderTech) BearRenderer(renderTech) { }

    /// @inheritdoc IBearRenderer
    // solhint-disable-next-line no-unused-vars
    function customDefs(uint176 genes, ISVGTypes.Color memory eyeColor, IBear3Traits.ScarColor[] memory scars, uint256 tokenId) external view onlyRenderTech returns (bytes memory) {
        IBear3Traits.ScarColor[] memory assignedScars = _assignScars(16, scars, bytes22(genes), tokenId);
        bytes memory results = abi.encodePacked(
            _renderTech.linearGradient("chest", hex'3201f401f400e3033e', "", _lastStopPacked(0x323439)),
            _renderTech.linearGradient("neck", hex'3201f401f401f103e8', _firstStopPacked(0x171920), _lastStopPacked(0x393B42)),
            _surfaceGradient(0, hex'32031500f9007602b0', 0x171A22, 0x2E323A, assignedScars),
            _renderTech.linearGradient("leftCheek", hex'3a01f301f3800203e8', _firstStopPacked(0x24262E), _lastStopPacked(0x06080B)),
            _surfaceGradient(1, hex'3a800303d5813503ed', 0x404448, 0x212426, assignedScars),
            _surfaceGradient(2, hex'3201e001e0000003e8', 0x41444E, 0x13151C, assignedScars),
            _surfaceGradient(3, hex'3201f801f8000403e8', 0x3D4048, 0x1E2129, assignedScars),
            _surfaceGradient(4, hex'3201f401f4000003e8', 0x545757, 0x414444, assignedScars)
        );
        results = abi.encodePacked(results,
            _surfaceGradient(5, hex'32010c0284008303e9', 0x171A22, 0x2E323A, assignedScars),
            _surfaceGradient(6, hex'3201d602eb000a0395', 0x2D3134, 0x3D4043, assignedScars),
            _surfaceGradient(7, hex'3200d302ef007602b0', 0x171A22, 0x2E323A, assignedScars),
            _renderTech.linearGradient("rightCheek", hex'3a01f501f5800203e8', _firstStopPacked(0x24262E), _lastStopPacked(0x06080B)),
            _surfaceGradient(8, hex'3a03eb000c813703f6', 0x404448, 0x212426, assignedScars),
            _surfaceGradient(9, hex'3202080208000003e8', 0x41444E, 0x13151C, assignedScars),
            _surfaceGradient(10, hex'3201f001f0000403e8', 0x3D4048, 0x1E2129, assignedScars),
            _surfaceGradient(11, hex'3201f401f4000003e8', 0x545757, 0x414444, assignedScars)
        );
        results = abi.encodePacked(results,
            _surfaceGradient(12, hex'3202dc0164008303e9', 0x171A22, 0x2E323A, assignedScars),
            _surfaceGradient(13, hex'32021200fd000a0395', 0x2D3134, 0x3D4043, assignedScars),
            _surfaceGradient(14, hex'3201e001e0001103de', 0x655C4D, 0x6E6555, assignedScars),
            _renderTech.linearGradient("snout", hex'3a01010101800203e0', _firstStopPacked(0x7D6E5A), _lastStopPacked(0x8D7D67)),
            _renderTech.linearGradient("mouth", hex'3201010101000003be', _firstStopPacked(0x5E503E), _lastStopPacked(0x615341)),
            _surfaceGradient(15, hex'3202080208001103de', 0x655C4D, 0x6E6555, assignedScars)
        );
        return results;
    }

    /// @inheritdoc IBearRenderer
    function customEyeColor(ICubTraits.TraitsV1 memory dominantParent) external view onlyRenderTech returns (ISVGTypes.Color memory) {
        return SVG.mixColors(SVG.fromPackedColor(0), dominantParent.bottomColor, 85, 100);
    }

    /// @inheritdoc IBearRenderer
    function customSurfaces(uint176 genes, ISVGTypes.Color memory eyeColor, uint256 tokenId) external view onlyRenderTech returns (bytes memory) {
        bytes22 geneBytes = bytes22(genes);
        IBearRenderTechProvider.Substitution[] memory jowlSubstitutions = _jowlSubstitutions(_jowlRange(geneBytes, tokenId));
        IBearRenderTechProvider.Substitution[] memory eyeSubstitutions = _eyeSubstitutions(_eyeRange(geneBytes, tokenId));
        bytes memory eyeAttributes = SVG.colorAttributeRGBValue(eyeColor);
        bytes memory results = SVG.createElement("g",
            // Translation
            abi.encodePacked(" transform='translate(0,", earRatio(geneBytes, tokenId).toDecimalString(1, false), ")'"), abi.encodePacked(
            // Left ear
            _renderTech.polygonElement(hex'12068f037505f00305041f02ab0579044b', "#0F1216"),
            _renderTech.polygonElement(hex'12041f02ab0583044104af0588', "black"),
            _renderTech.polygonElement(hex'12041f02ac04c2025805f50308', "url(#paint1)"),
            _renderTech.polygonElement(hex'12041f02ab04b9058803c00450', "url(#paint2)"),
            // Right ear
            _renderTech.polygonElement(hex'120af203750b9103050d6202ab0c08044b', "#0F1216"),
            _renderTech.polygonElement(hex'120d6202ab0bfe04410cd20588', "black"),
            _renderTech.polygonElement(hex'120d6202ac0cbf02580b8f0306', "url(#paint8)"),
            _renderTech.polygonElement(hex'120d6202ab0cc805880dc10450', "url(#paint9)")
        ));
        results = abi.encodePacked(results,
            _renderTech.dynamicPolygonElement(hex'12055d0b7a04b10a54061409f607590bf4', "url(#paint0)", jowlSubstitutions),
            _renderTech.polygonElement(hex'1207da05be05d3064507120a730776094d', "url(#leftCheek)"),
            _renderTech.dynamicPolygonElement(hex'1205cd063f07db0701061a0849', eyeAttributes, eyeSubstitutions),
            _renderTech.polygonElement(hex'1208c1030c0633037b05c9064a08c10582', "url(#paint3)"),
            _renderTech.polygonElement(hex'120637037a05d2064503c1076204ba04d9', "url(#paint4)"),
            _renderTech.polygonElement(hex'1204b10a6403fd0794063b09f6', "url(#paint5)"),
            _renderTech.polygonElement(hex'1205d2063b078a0bcc07590bf4060409fb03ca075d', "url(#paint6)")
        );
        results = abi.encodePacked(results,
            _renderTech.dynamicPolygonElement(hex'120c240b7a0cd00a540b6d09f60a280bf4', "url(#paint7)", jowlSubstitutions),
            _renderTech.polygonElement(hex'1209a705be0bae06450a6f0a730a0b094d', "url(#rightCheek)"),
            _renderTech.dynamicPolygonElement(hex'120bb5063f09a607010b670849', eyeAttributes, eyeSubstitutions),
            _renderTech.polygonElement(hex'1208c0030c0b4e037b0bb8064a08c00582', "url(#paint10)"),
            _renderTech.polygonElement(hex'120b4a037a0baf06450dc007620cc704d9', "url(#paint11)"),
            _renderTech.polygonElement(hex'120cd00a640d8407940b4609f6', "url(#paint12)"),
            _renderTech.polygonElement(hex'120baf063b09f70bcc0a280bf40b7d09fb0db7075d', "url(#paint13)")
        );
        results = abi.encodePacked(results,
            _renderTech.polygonElement(hex'1207bd04ba08c1030c09c504ba09b205be07d305be', "#26292B"),
            _renderTech.polygonElement(hex'1207d105ae08cb056e076d094c', "url(#paint14)"),
            _renderTech.polygonElement(hex'1209b005ae08b6056e0a14094c', "url(#paint15)"),
            _renderTech.polygonElement(hex'1208c105820a1809330a700a6407120a64076a0933', "url(#snout)"),
            _renderTech.polygonElement(hex'120a720a5c0a320c0c08c30c5c07550c0c07130a5c08c30a07', "url(#mouth)"),
            _renderTech.polygonElement(hex'1208c109e207c70a0f07c80ad108c10b3609ba0ad209ba0a0f', "black")
        );
        return results;
    }

    function _jowlRange(bytes22 geneBytes, uint256 tokenId) private pure returns (uint replacementY) {
        return 2738 + uint(jowlRatio(geneBytes, tokenId)) * 300 / 255; // Between 0 & 300
    }

    function _eyeRange(bytes22 geneBytes, uint256 tokenId) private pure returns (uint replacementY) {
        return 1826 + uint(eyeRatio(geneBytes, tokenId)) * 765 / 255; // Between 0 & 765
    }

    function _jowlSubstitutions(uint replacementY) private pure returns (IBearRenderTechProvider.Substitution[] memory substitutions) {
        substitutions = new IBearRenderTechProvider.Substitution[](2);
        // 137.3,293.8 & 310.8,293.8
        substitutions[0].matchingX = 1373;
        substitutions[0].matchingY = 2938;
        substitutions[0].replacementX = 1373;
        substitutions[0].replacementY = replacementY;
        substitutions[1].matchingX = 3108;
        substitutions[1].matchingY = 2938;
        substitutions[1].replacementX = 3108;
        substitutions[1].replacementY = replacementY;
    }

    function _eyeSubstitutions(uint replacementY) private pure returns (IBearRenderTechProvider.Substitution[] memory substitutions) {
        substitutions = new IBearRenderTechProvider.Substitution[](2);
        // 156.2,212.1 & 291.9,212.1
        substitutions[0].matchingX = 1562;
        substitutions[0].matchingY = 2121;
        substitutions[0].replacementX = 1562;
        substitutions[0].replacementY = replacementY;
        substitutions[1].matchingX = 2919;
        substitutions[1].matchingY = 2121;
        substitutions[1].replacementX = 2919;
        substitutions[1].replacementY = replacementY;
    }
}