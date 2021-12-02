// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import {IGorfDecorator} from './IGorfDecorator.sol';
import {IGorfDescriptor} from './IGorfDescriptor.sol';
import {IGorfSeeder} from './IGorfSeeder.sol';
import {MultiPartRLEToSVG} from './MultiPartRLEToSVG.sol';
import {Base64} from 'base64-sol/base64.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract Decorator is IGorfDecorator, Ownable {
    IGorfDescriptor public descriptor;

    // Noun Backgrounds
    string[] public backgroundMapping;

    // Noun Bodies
    string[] public bodyMapping;

    // Noun Accessories
    string[] public accessoryMapping;

    // Noun Heads
    string[] public headMapping;

    // Noun Glasses
    string[] public glassesMapping;

    // Noun Color Palettes (Index => Hex Colors)
    mapping(uint8 => string[]) public palettes;

    constructor() {
        //todo: mainnet
        descriptor = IGorfDescriptor(0x53cB482c73655D2287AE3282AD1395F82e6a402F);
    }

    function addManyBackgroundsToMap(string[] calldata _backgrounds) external onlyOwner {
        for (uint256 i = 0; i < _backgrounds.length; i++) {
            _addBackgroundToMap(_backgrounds[i]);
        }
    }

    function addManyBodiesToMap(string[] calldata _bodies) external onlyOwner {
        for (uint256 i = 0; i < _bodies.length; i++) {
            _addBodyToMap(_bodies[i]);
        }
    }

    function addManyAccessoriesToMap(string[] calldata _accessories) external onlyOwner {
        for (uint256 i = 0; i < _accessories.length; i++) {
            _addAccessoryToMap(_accessories[i]);
        }
    }

    function addManyHeadsToMap(string[] calldata _heads) external onlyOwner {
        for (uint256 i = 0; i < _heads.length; i++) {
            _addHeadToMap(_heads[i]);
        }
    }

    function addManyGlassesToMap(string[] calldata _glasses) external onlyOwner {
        for (uint256 i = 0; i < _glasses.length; i++) {
            _addGlassesToMap(_glasses[i]);
        }
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(string memory name, string memory description, IGorfSeeder.Seed memory seed) public view override returns (string memory) {
        MultiPartRLEToSVG.SVGParams memory params = MultiPartRLEToSVG.SVGParams({
            parts: _getPartsForSeed(seed),
            background: descriptor.backgrounds(seed.background)
        });

        string memory image = Base64.encode(bytes(MultiPartRLEToSVG.generateSVG(params, palettes)));
        string memory attributes = generateAttributes(seed);

        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', name, '", "description":"', description, '", "image": "', 'data:image/svg+xml;base64,', image, '", "attributes": [', attributes, ']}')
                    )
                )
            )
        );
    }

    function generateAttributes(IGorfSeeder.Seed memory seed) public view returns (string memory) {
        return string(
            abi.encodePacked(
                '{"trait_type": "Background", "value": "', backgroundMapping[seed.background], '"},',
                '{"trait_type": "Body", "value": "', bodyMapping[seed.body], '"},',
                '{"trait_type": "Accessory", "value": "', accessoryMapping[seed.accessory], '"},',
                '{"trait_type": "Head", "value": "', headMapping[seed.head], '"},',
                '{"trait_type": "Glasses", "value": "', glassesMapping[seed.glasses], '"}'
            )
        );
    }

    function _addBackgroundToMap(string calldata _background) internal {
        backgroundMapping.push(_background);
    }

    function _addBodyToMap(string calldata _body) internal {
        bodyMapping.push(_body);
    }

    function _addAccessoryToMap(string calldata _accessory) internal {
        accessoryMapping.push(_accessory);
    }

    function _addHeadToMap(string calldata _head) internal {
        headMapping.push(_head);
    }

    function _addGlassesToMap(string calldata _glasses) internal {
        glassesMapping.push(_glasses);
    }

    /**
     * @notice Add colors to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external onlyOwner {
        require(palettes[paletteIndex].length + newColors.length <= 256, 'Palettes can only hold 256 colors');
        for (uint256 i = 0; i < newColors.length; i++) {
            _addColorToPalette(paletteIndex, newColors[i]);
        }
    }

    /**
     * @notice Add a single color to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addColorToPalette(uint8 _paletteIndex, string calldata _color) external onlyOwner {
        require(palettes[_paletteIndex].length <= 255, 'Palettes can only hold 256 colors');
        _addColorToPalette(_paletteIndex, _color);
    }

    /**
     * @notice Add a single color to a color palette.
     */
    function _addColorToPalette(uint8 _paletteIndex, string calldata _color) internal {
        palettes[_paletteIndex].push(_color);
    }

    /**
     * @notice Get all Noun parts for the passed `seed`.
     */
    function _getPartsForSeed(IGorfSeeder.Seed memory seed) internal view returns (bytes[] memory) {
        bytes[] memory _parts = new bytes[](4);
        _parts[0] = descriptor.bodies(seed.body);
        _parts[1] = descriptor.accessories(seed.accessory);
        _parts[2] = descriptor.heads(seed.head);
        _parts[3] = descriptor.glasses(seed.glasses);
        return _parts;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import { IGorfSeeder } from './IGorfSeeder.sol';

interface IGorfDecorator {
    function genericDataURI(
        string calldata name,
        string calldata description,
        IGorfSeeder.Seed memory seed
    ) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import { IGorfSeeder } from './IGorfSeeder.sol';

interface IGorfDescriptor {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function glasses(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addManyBodies(bytes[] calldata bodies) external;

    function addManyAccessories(bytes[] calldata accessories) external;

    function addManyHeads(bytes[] calldata heads) external;

    function addManyGlasses(bytes[] calldata glasses) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function addBody(bytes calldata body) external;

    function addAccessory(bytes calldata accessory) external;

    function addHead(bytes calldata head) external;

    function addGlasses(bytes calldata glasses) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, IGorfSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, IGorfSeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IGorfSeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(IGorfSeeder.Seed memory seed) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import { IGorfDescriptor } from './IGorfDescriptor.sol';

interface IGorfSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(uint256 nounId, IGorfDescriptor descriptor) external view returns (Seed memory);
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

library MultiPartRLEToSVG {
    struct SVGParams {
        bytes[] parts;
        string background;
    }

    struct ContentBounds {
        uint8 top;
        uint8 right;
        uint8 bottom;
        uint8 left;
    }

    struct Rect {
        uint8 length;
        uint8 colorIndex;
    }

    struct DecodedImage {
        uint8 paletteIndex;
        ContentBounds bounds;
        uint256 width;
        Rect[] rects;
    }

    /**
     * @notice Given RLE image parts and color palettes, merge to generate a single SVG image.
     */
    function generateSVG(SVGParams memory params, mapping(uint8 => string[]) storage palettes) internal view returns (string memory svg) {
        // prettier-ignore
        return string(
            abi.encodePacked(
                '<svg width="320" height="320" viewBox="0 0 320 320" xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges">',
                '<rect width="100%" height="100%" fill="#', params.background, '" />',
                _generateSVGRects(params, palettes),
                '</svg>'
            )
        );
    }

    /**
     * @notice Given RLE image parts and color palettes, generate SVG rects.
     */
    // prettier-ignore
    function _generateSVGRects(SVGParams memory params, mapping(uint8 => string[]) storage palettes) private view returns (string memory svg) {
        string[33] memory lookup = [
            '0', '10', '20', '30', '40', '50', '60', '70',
            '80', '90', '100', '110', '120', '130', '140', '150',
            '160', '170', '180', '190', '200', '210', '220', '230',
            '240', '250', '260', '270', '280', '290', '300', '310',
            '320'
        ];

        string memory rects;
        for (uint8 p = 0; p < params.parts.length; p++) {
            DecodedImage memory image = _decodeRLEImage(params.parts[p]);
            string[] storage palette = palettes[image.paletteIndex];
            uint256 currentX = image.bounds.left; //+rect.length
            uint256 currentY = image.bounds.top; //+1
            uint256 cursor;
            string[16] memory buffer;

            string memory part;
            for (uint256 i = 0; i < image.rects.length; i++) {
                Rect memory rect = image.rects[i];
                if (rect.colorIndex != 0) {
                    buffer[cursor] = lookup[rect.length]; // width
                    buffer[cursor + 1] = lookup[33-currentX-rect.length]; // x
                    buffer[cursor + 2] = lookup[currentY]; // y
                    buffer[cursor + 3] = palette[rect.colorIndex]; // color

                    cursor += 4;

                    if (cursor >= 16) {
                        part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
                        cursor = 0;
                    }
                }

                currentX += rect.length;
                if (currentX - image.bounds.left == image.width) {
                    currentX = image.bounds.left;
                    currentY++;
                }
            }

            if (cursor != 0) {
                part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
            }
            rects = string(abi.encodePacked(rects, part));
        }
        return rects;
    }

    /**
     * @notice Return a string that consists of all ellipse in the provided `buffer`.
     */
    // prettier-ignore
    function _getChunk(uint256 cursor, string[16] memory buffer) private pure returns (string memory) {
        string memory chunk;
        for (uint256 i = 0; i < cursor; i += 4) {
            chunk = string(
                abi.encodePacked(
                    chunk,
                    '<rect width="', buffer[i], '" height="10" x="', buffer[i + 1], '" y="', buffer[i + 2], '" fill="#', buffer[i + 3], '" />'
                )
            );
        }
        return chunk;
    }

    /**
     * @notice Decode a single RLE compressed image into a `DecodedImage`.
     */
    function _decodeRLEImage(bytes memory image) private pure returns (DecodedImage memory) {
        uint8 paletteIndex = uint8(image[0]);
        ContentBounds memory bounds = ContentBounds({
            top : uint8(image[1]),
            right : uint8(image[2]),
            bottom : uint8(image[3]),
            left : uint8(image[4])
        });
        uint256 width = bounds.right - bounds.left;

        uint256 cursor;
        Rect[] memory rects = new Rect[]((image.length - 5) / 2);
        for (uint256 i = 5; i < image.length; i += 2) {
            rects[cursor] = Rect({length : uint8(image[i]), colorIndex : uint8(image[i + 1])});
            cursor++;
        }
        return DecodedImage({paletteIndex : paletteIndex, bounds : bounds, width : width, rects : rects});
    }
}

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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