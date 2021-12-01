// SPDX-License-Identifier: GPL-3.0

/// @title The Bitstrays NFT descriptor

/***********************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@%[email protected]@@@@@@@@@@@@
[email protected]@@@@@@..............................
./@@@@@@@@@[email protected]@@....*@@@@.......*@@@@@@@@@.
./@@@@@@@[email protected]@@@@[email protected]@@[email protected]@@@@[email protected]@@@@.
@%[email protected]@[email protected]@[email protected]@@[email protected]
@%**.........,**.........................................**@
@@@@##.....##(**#######   .........  ,#######  .......###@@@
@@@@@@[email protected]@@@#  @@   @@   .........  ,@@  @@@  [email protected]@@@@@
@@@@@@[email protected]@#  @@@@@@@   .........  ,@@@@@@@  [email protected]@@@@@
@@@@@@[email protected]@@@@       @@%............       [email protected]@@@@@
@@@@@@@@@..../@@@@@@@@@[email protected]@@@@@@@
@@@@@@@@@............                   [email protected]@@@@@@@
@@@@@@@@@@@..........  @@@@@@@@@@@@@@%  .........*@@@@@@@@@@
@@@@@@@@@@@@@%....   @@//////////////#@@  [email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  @@@///////////////////@@   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  ************************   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
************************************************************/

pragma solidity ^0.8.6;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { Strings } from '@openzeppelin/contracts/utils/Strings.sol';
import { IBitstraysDescriptor } from './interfaces/IBitstraysDescriptor.sol';
import { IBitstraysSeeder } from './interfaces/IBitstraysSeeder.sol';
import { NFTDescriptor } from './libs/NFTDescriptor.sol';
import { MultiPartRLEToSVG } from './libs/MultiPartRLEToSVG.sol';
import { StringUtil } from './libs/StringUtil.sol';

contract BitstraysDescriptor is IBitstraysDescriptor, Ownable {
    using Strings for uint256;

    // prettier-ignore
    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    // Whether or not new Bitstray parts can be added
    bool public override arePartsLocked;

    // Whether or not `tokenURI` should be returned as a data URI (Default: true)
    bool public override isDataURIEnabled = true;

    // Whether or not attributes should be returned in tokenURI response (Default: true)
    bool public override areAttributesEnabled = true;

    // Base URI
    string public override baseURI;

    // Bitstray Color Palettes (Index => Hex Colors)
    mapping(uint8 => string[]) public override palettes;

    // Bitstray Backgrounds (Hex Colors)
    string[] public override backgrounds;

    // Bitstray Arms (Custom RLE)
    bytes[] public override arms;

    // Bitstray Shirts (Custom RLE)
    bytes[] public override shirts;

    // Bitstray Motives (Custom RLE)
    bytes[] public override motives;

    // Bitstray Heads (Custom RLE)
    bytes[] public override heads;

    // Bitstray Eyes (Custom RLE)
    bytes[] public override eyes;

    // Bitstray Mouths (Custom RLE)
    bytes[] public override mouths;

    // Bitstary Metadata (Array of String)
    mapping(uint8 => string[]) public override metadata;

    // Bitstary Trait Names (Array of String)
    string[] public override traitNames;

    /**
     * @notice Require that the parts have not been locked.
     */
    modifier whenPartsNotLocked() {
        require(!arePartsLocked, 'Parts are locked');
        _;
    }

    /**
     * @notice Get the number of available Bitstray `backgrounds`.
     */
    function backgroundCount() external view override returns (uint256) {
        return backgrounds.length;
    }

    /**
     * @notice Get the number of available Bitstray `arms`.
     */
    function armsCount() external view override returns (uint256) {
        return arms.length;
    }

    /**
     * @notice Get the number of available Bitstray `shirts`.
     */
    function shirtsCount() external view override returns (uint256) {
        return shirts.length;
    }

    /**
     * @notice Get the number of available Bitstray `motives`.
     */
    function motivesCount() external view override returns (uint256) {
        return motives.length;
    }

    /**
     * @notice Get the number of available Bitstray `heads`.
     */
    function headCount() external view override returns (uint256) {
        return heads.length;
    }

    /**
     * @notice Get the number of available Bitstray `eyes`.
     */
    function eyesCount() external view override returns (uint256) {
        return eyes.length;
    }

    /**
     * @notice Get the number of available Bitstray `mouths`.
     */
    function mouthsCount() external view override returns (uint256) {
        return mouths.length;
    }

    /**
     * @notice Add metadata for all parts.
     * @dev This function can only be called by the owner.
     * should container encoding details for traits [#traits, trait1, #elements, trait2, #elements, data ...]
     */
    function addManyMetadata(string[] calldata _metadata) external override onlyOwner {
        require(_metadata.length >= 1, '_metadata length < 1');
        uint256 _traits = StringUtil.parseInt(_metadata[0]);
        uint256 offset = _traits + 1; //define first real data element
        // traits are provided in #traits, traitname
        uint8 index = 0;
        for (uint8 i = 1; i < _traits; i+=2 ) {
            _addTraitName(_metadata[i]); // read trait name
            uint256 elements = StringUtil.parseInt(_metadata[i+1]);
            for (uint256 j = offset; j < (offset + elements); j++) {
                _addMetadata(index, _metadata[j]);
            }
            offset = offset + elements;
            index++;
        }
    }

    /**
     * @notice Add colors to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external override onlyOwner {
        require(palettes[paletteIndex].length + newColors.length <= 256, 'Palettes can only hold 256 colors');
        for (uint256 i = 0; i < newColors.length; i++) {
            _addColorToPalette(paletteIndex, newColors[i]);
        }
    }

    /**
     * @notice Batch add Bitstray backgrounds.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyBackgrounds(string[] calldata _backgrounds) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _backgrounds.length; i++) {
            _addBackground(_backgrounds[i]);
        }
    }

    /**
     * @notice Batch add Bitstray arms.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyArms(bytes[] calldata _arms) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _arms.length; i++) {
            _addArms(_arms[i]);
        }
    }

    /**
     * @notice Batch add Bitstray shirts.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyShirts(bytes[] calldata _shirts) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _shirts.length; i++) {
            _addShirt(_shirts[i]);
        }
    }

    /**
     * @notice Batch add Bitstray motives.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyMotives(bytes[] calldata _motives) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _motives.length; i++) {
            _addMotive(_motives[i]);
        }
    }

    /**
     * @notice Batch add Bitstray heads.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyHeads(bytes[] calldata _heads) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _heads.length; i++) {
            _addHead(_heads[i]);
        }
    }

    /**
     * @notice Batch add Bitstray eyes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyEyes(bytes[] calldata _eyes) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _eyes.length; i++) {
            _addEyes(_eyes[i]);
        }
    }

    /**
     * @notice Batch add Bitstray eyes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyMouths(bytes[] calldata _mouths) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _mouths.length; i++) {
            _addMouth(_mouths[i]);
        }
    }

    /**
     * @notice Add a single color to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addColorToPalette(uint8 _paletteIndex, string calldata _color) external override onlyOwner {
        require(palettes[_paletteIndex].length <= 255, 'Palettes can only hold 256 colors');
        _addColorToPalette(_paletteIndex, _color);
    }

    /**
     * @notice Add a Bitstray background.
     * @dev This function can only be called by the owner when not locked.
     */
    function addBackground(string calldata _background) external override onlyOwner whenPartsNotLocked {
        _addBackground(_background);
    }

    /**
     * @notice Add a Bitstray arms.
     * @dev This function can only be called by the owner when not locked.
     */
    function addArms(bytes calldata _arms) external override onlyOwner whenPartsNotLocked {
        _addArms(_arms);
    }

    /**
     * @notice Add a Bitstray shirt.
     * @dev This function can only be called by the owner when not locked.
     */
    function addShirt(bytes calldata _shirt) external override onlyOwner whenPartsNotLocked {
        _addShirt(_shirt);
    }

    /**
     * @notice Add a Bitstray motive.
     * @dev This function can only be called by the owner when not locked.
     */
    function addMotive(bytes calldata _motive) external override onlyOwner whenPartsNotLocked {
        _addMotive(_motive);
    }

    /**
     * @notice Add a Bitstray head.
     * @dev This function can only be called by the owner when not locked.
     */
    function addHead(bytes calldata _head) external override onlyOwner whenPartsNotLocked {
        _addHead(_head);
    }

    /**
     * @notice Add Bitstray eyes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addEyes(bytes calldata _eyes) external override onlyOwner whenPartsNotLocked {
        _addEyes(_eyes);
    }

    /**
     * @notice Add Bitstray mouth.
     * @dev This function can only be called by the owner when not locked.
     */
    function addMouth(bytes calldata _mouth) external override onlyOwner whenPartsNotLocked {
        _addMouth(_mouth);
    }

    /**
     * @notice Lock all Bitstray parts.
     * @dev This cannot be reversed and can only be called by the owner when not locked.
     */
    function lockParts() external override onlyOwner whenPartsNotLocked {
        arePartsLocked = true;

        emit PartsLocked();
    }


    /**
     * @notice Toggle a boolean value which determines if `tokenURI` returns a data URI
     * or an HTTP URL.
     * @dev This can only be called by the owner.
     */
    function toggleAttributesEnabled() external override onlyOwner {
        bool enabled = !areAttributesEnabled;

        areAttributesEnabled = enabled;
        emit AttributesToggled(enabled);
    }

    /**
     * @notice Toggle a boolean value which determines if `tokenURI` returns a data URI
     * or an HTTP URL.
     * @dev This can only be called by the owner.
     */
    function toggleDataURIEnabled() external override onlyOwner {
        bool enabled = !isDataURIEnabled;

        isDataURIEnabled = enabled;
        emit DataURIToggled(enabled);
    }

    /**
     * @notice Set the base URI for all token IDs. It is automatically
     * added as a prefix to the value returned in {tokenURI}, or to the
     * token ID if {tokenURI} is empty.
     * @dev This can only be called by the owner.
     */
    function setBaseURI(string calldata _baseURI) external override onlyOwner {
        baseURI = _baseURI;

        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @notice Given a token ID and seed, construct a token URI for an official Bitstrays DAO bitstray.
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 tokenId, IBitstraysSeeder.Seed memory seed) external view override returns (string memory) {
        if (isDataURIEnabled) {
            return dataURI(tokenId, seed);
        }
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI for an official Bitstrays DAO bitstray.
     */
    function dataURI(uint256 tokenId, IBitstraysSeeder.Seed memory seed) public view override returns (string memory) {
        string memory bitstrayId = tokenId.toString();
        string memory name = string(abi.encodePacked('Bitstray #', bitstrayId));
        string memory description = string(abi.encodePacked('Bitstray #', bitstrayId, ' is a member of the Bitstrays DAO and on-chain citizen'));
        return genericDataURI(name, description,  seed);
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(
        string memory name,
        string memory description,
        IBitstraysSeeder.Seed memory seed
    ) public view override returns (string memory) {
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
            name: name,
            description: description,
            attributes : _getAttributesForSeed(seed),
            parts: _getPartsForSeed(seed),
            background: backgrounds[seed.background]
        });
        return NFTDescriptor.constructTokenURI(params, palettes);
    }

    /**
     * @notice Given a seed, construct a base64 encoded SVG image.
     */
    function generateSVGImage(IBitstraysSeeder.Seed memory seed) external view override returns (string memory) {
        MultiPartRLEToSVG.SVGParams memory params = MultiPartRLEToSVG.SVGParams({
            parts: _getPartsForSeed(seed),
            background: backgrounds[seed.background]
        });
        return NFTDescriptor.generateSVGImage(params, palettes);
    }

    /**
     * @notice Add a single attribute to metadata.
     */
    function _addTraitName(string calldata _traitName) internal {
        traitNames.push(_traitName);
    }

    /**
     * @notice Add a single attribute to metadata.
     */
    function _addMetadata(uint8 _index, string calldata _metadata) internal {
        metadata[_index].push(_metadata);
    }

    /**
     * @notice Add a single color to a color palette.
     */
    function _addColorToPalette(uint8 _paletteIndex, string calldata _color) internal {
        palettes[_paletteIndex].push(_color);
    }

    /**
     * @notice Add a Bitstray background.
     */
    function _addBackground(string calldata _background) internal {
        backgrounds.push(_background);
    }

    /**
     * @notice Add a Bitstray arm.
     */
    function _addArms(bytes calldata _arms) internal {
        arms.push(_arms);
    }

    /**
     * @notice Add a Bitstray shirt.
     */
    function _addShirt(bytes calldata _shirt) internal {
        shirts.push(_shirt);
    }

    /**
     * @notice Add a Bitstray motive.
     */
    function _addMotive(bytes calldata _motive) internal {
        motives.push(_motive);
    }

    /**
     * @notice Add a Bitstray head.
     */
    function _addHead(bytes calldata _head) internal {
        heads.push(_head);
    }

    /**
     * @notice Add Bitstray eyes.
     */
    function _addEyes(bytes calldata _eyes) internal {
        eyes.push(_eyes);
    }
    
    /**
     * @notice Add Bitstray mouths.
     */
    function _addMouth(bytes calldata _mouth) internal {
        mouths.push(_mouth);
    }



    /**
     * @notice Get all Bitstray attributes for the passed `seed`.
     */
    function _getAttributesForSeed(IBitstraysSeeder.Seed memory seed) internal view returns (string[] memory) {
        if (areAttributesEnabled) {
            string[] memory _attributes = new string[](14);
            _attributes[0] = traitNames[0];
            _attributes[1] = metadata[0][seed.head];
            _attributes[2] = traitNames[1];
            _attributes[3] = metadata[1][seed.head];
            _attributes[4] = traitNames[2];
            _attributes[5] = metadata[2][seed.arms];
            _attributes[6] = traitNames[3];
            _attributes[7] = metadata[3][seed.shirt];
            _attributes[8] = traitNames[4];
            _attributes[9] = metadata[4][seed.motive];
            _attributes[10] = traitNames[5];
            _attributes[11] = metadata[5][seed.eyes];
            _attributes[12] = traitNames[6];
            _attributes[13] = metadata[6][seed.mouth];
            return _attributes;
        }
        string[] memory _empty = new string[](0);
        return _empty;
    }

    /**
     * @notice Get all Bitstray parts for the passed `seed`.
     */
    function _getPartsForSeed(IBitstraysSeeder.Seed memory seed) internal view returns (bytes[] memory) {
        bytes[] memory _parts = new bytes[](6);
        _parts[0] = arms[seed.arms];
        _parts[1] = shirts[seed.shirt];
        _parts[2] = motives[seed.motive];
        _parts[3] = heads[seed.head];
        _parts[4] = eyes[seed.eyes];
        _parts[5] = mouths[seed.mouth];
        return _parts;
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

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for BitstraysDescriptor

/***********************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@%[email protected]@@@@@@@@@@@@
[email protected]@@@@@@..............................
./@@@@@@@@@[email protected]@@....*@@@@.......*@@@@@@@@@.
./@@@@@@@[email protected]@@@@[email protected]@@[email protected]@@@@[email protected]@@@@.
@%[email protected]@[email protected]@[email protected]@@[email protected]
@%**.........,**.........................................**@
@@@@##.....##(**#######   .........  ,#######  .......###@@@
@@@@@@[email protected]@@@#  @@   @@   .........  ,@@  @@@  [email protected]@@@@@
@@@@@@[email protected]@#  @@@@@@@   .........  ,@@@@@@@  [email protected]@@@@@
@@@@@@[email protected]@@@@       @@%............       [email protected]@@@@@
@@@@@@@@@..../@@@@@@@@@[email protected]@@@@@@@
@@@@@@@@@............                   [email protected]@@@@@@@
@@@@@@@@@@@..........  @@@@@@@@@@@@@@%  .........*@@@@@@@@@@
@@@@@@@@@@@@@%....   @@//////////////#@@  [email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  @@@///////////////////@@   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  ************************   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
************************************************************/

pragma solidity ^0.8.6;

import { IBitstraysSeeder } from './IBitstraysSeeder.sol';

interface IBitstraysDescriptor {
    
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event AttributesToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function areAttributesEnabled() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);
    
    function metadata(uint8 index, uint256 traitIndex) external view returns (string memory);

    function traitNames(uint256 index) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function arms(uint256 index) external view returns (bytes memory);

    function shirts(uint256 index) external view returns (bytes memory);

    function motives(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function eyes(uint256 index) external view returns (bytes memory);

    function mouths(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function armsCount() external view returns (uint256);

    function shirtsCount() external view returns (uint256);

    function motivesCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function eyesCount() external view returns (uint256);

    function mouthsCount() external view returns (uint256);

    function addManyMetadata(string[] calldata _metadata) external;

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addManyArms(bytes[] calldata _arms) external;

    function addManyShirts(bytes[] calldata _shirts) external;

    function addManyMotives(bytes[] calldata _motives) external;

    function addManyHeads(bytes[] calldata _heads) external;

    function addManyEyes(bytes[] calldata _eyes) external;

    function addManyMouths(bytes[] calldata _mouths) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function addArms(bytes calldata body) external;

    function addShirt(bytes calldata shirt) external;

    function addMotive(bytes calldata motive) external;

    function addHead(bytes calldata head) external;

    function addEyes(bytes calldata eyes) external;

    function addMouth(bytes calldata mouth) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function toggleAttributesEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, IBitstraysSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, IBitstraysSeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        IBitstraysSeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(IBitstraysSeeder.Seed memory seed) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for BitstraysSeeder

/***********************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@%[email protected]@@@@@@@@@@@@
[email protected]@@@@@@..............................
./@@@@@@@@@[email protected]@@....*@@@@.......*@@@@@@@@@.
./@@@@@@@[email protected]@@@@[email protected]@@[email protected]@@@@[email protected]@@@@.
@%[email protected]@[email protected]@[email protected]@@[email protected]
@%**.........,**.........................................**@
@@@@##.....##(**#######   .........  ,#######  .......###@@@
@@@@@@[email protected]@@@#  @@   @@   .........  ,@@  @@@  [email protected]@@@@@
@@@@@@[email protected]@#  @@@@@@@   .........  ,@@@@@@@  [email protected]@@@@@
@@@@@@[email protected]@@@@       @@%............       [email protected]@@@@@
@@@@@@@@@..../@@@@@@@@@[email protected]@@@@@@@
@@@@@@@@@............                   [email protected]@@@@@@@
@@@@@@@@@@@..........  @@@@@@@@@@@@@@%  .........*@@@@@@@@@@
@@@@@@@@@@@@@%....   @@//////////////#@@  [email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  @@@///////////////////@@   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  ************************   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
************************************************************/

pragma solidity ^0.8.6;

import { IBitstraysDescriptor } from './IBitstraysDescriptor.sol';

interface IBitstraysSeeder {
    struct Seed {
        uint48 background;
        uint48 arms;
        uint48 shirt;
        uint48 motive;
        uint48 head;
        uint48 eyes;
        uint48 mouth;
    }

    function generateSeed(uint256 bitstrayId, IBitstraysDescriptor descriptor) external view returns (Seed memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title A library used to construct ERC721 token URIs and SVG images

/***********************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@%[email protected]@@@@@@@@@@@@
[email protected]@@@@@@..............................
./@@@@@@@@@[email protected]@@....*@@@@.......*@@@@@@@@@.
./@@@@@@@[email protected]@@@@[email protected]@@[email protected]@@@@[email protected]@@@@.
@%[email protected]@[email protected]@[email protected]@@[email protected]
@%**.........,**.........................................**@
@@@@##.....##(**#######   .........  ,#######  .......###@@@
@@@@@@[email protected]@@@#  @@   @@   .........  ,@@  @@@  [email protected]@@@@@
@@@@@@[email protected]@#  @@@@@@@   .........  ,@@@@@@@  [email protected]@@@@@
@@@@@@[email protected]@@@@       @@%............       [email protected]@@@@@
@@@@@@@@@..../@@@@@@@@@[email protected]@@@@@@@
@@@@@@@@@............                   [email protected]@@@@@@@
@@@@@@@@@@@..........  @@@@@@@@@@@@@@%  .........*@@@@@@@@@@
@@@@@@@@@@@@@%....   @@//////////////#@@  [email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  @@@///////////////////@@   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  ************************   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
************************************************************/

pragma solidity ^0.8.6;

import { Base64 } from 'base64-sol/base64.sol';
import { MultiPartRLEToSVG } from './MultiPartRLEToSVG.sol';

library NFTDescriptor {
    struct TokenURIParams {
        string name;
        string description;
        string[] attributes;
        bytes[] parts;
        string background;
    }
    /**
     * @notice Construct an ERC721 token attributes.
     */
    function _generateAttributes(TokenURIParams memory params) internal pure returns (string memory attributes)
    {
        string memory _attributes = "[";
        if (params.attributes.length >0) {
            string [] memory att = params.attributes;
            for (uint256 i = 0; i < att.length && i + 1 < att.length; i += 2) {
                if (i == 0) {
                    _attributes = string(abi.encodePacked(_attributes,'{"trait_type":"',att[i],'","value":"',att[i+1],'"}'));
                } else {
                    _attributes = string(abi.encodePacked(_attributes, ',{"trait_type":"',att[i],'","value":"',att[i+1],'"}'));
                }
            }
            _attributes = string(abi.encodePacked(_attributes, "]"));
            return _attributes;
        }
        // empty array

        return string(abi.encodePacked(_attributes, "]"));
    }

    /**
     * @notice Construct an ERC721 token URI.
     */
    function constructTokenURI(TokenURIParams memory params, mapping(uint8 => string[]) storage palettes)
        public
        view
        returns (string memory)
    {
        string memory image = generateSVGImage(
            MultiPartRLEToSVG.SVGParams({ parts: params.parts, background: params.background }),
            palettes
        );
        string memory attributes = _generateAttributes(params);
        // prettier-ignore
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                        '{"name":"', params.name, '","description":"', params.description, '","attributes":',attributes,',"image": "', 'data:image/svg+xml;base64,', image, '"}')
                    )
                )
            )
        );
    }

    /**
     * @notice Generate an SVG image for use in the ERC721 token URI.
     */
    function generateSVGImage(MultiPartRLEToSVG.SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        public
        view
        returns (string memory svg)
    {
        return Base64.encode(bytes(MultiPartRLEToSVG.generateSVG(params, palettes)));
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title A library used to convert multi-part RLE compressed images to SVG

/***********************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@%[email protected]@@@@@@@@@@@@
[email protected]@@@@@@..............................
./@@@@@@@@@[email protected]@@....*@@@@.......*@@@@@@@@@.
./@@@@@@@[email protected]@@@@[email protected]@@[email protected]@@@@[email protected]@@@@.
@%[email protected]@[email protected]@[email protected]@@[email protected]
@%**.........,**.........................................**@
@@@@##.....##(**#######   .........  ,#######  .......###@@@
@@@@@@[email protected]@@@#  @@   @@   .........  ,@@  @@@  [email protected]@@@@@
@@@@@@[email protected]@#  @@@@@@@   .........  ,@@@@@@@  [email protected]@@@@@
@@@@@@[email protected]@@@@       @@%............       [email protected]@@@@@
@@@@@@@@@..../@@@@@@@@@[email protected]@@@@@@@
@@@@@@@@@............                   [email protected]@@@@@@@
@@@@@@@@@@@..........  @@@@@@@@@@@@@@%  .........*@@@@@@@@@@
@@@@@@@@@@@@@%....   @@//////////////#@@  [email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  @@@///////////////////@@   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  ************************   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
************************************************************/

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
        Rect[] rects;
    }

    /**
     * @notice Given RLE image parts and color palettes, merge to generate a single SVG image.
     */
    function generateSVG(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        internal
        view
        returns (string memory svg)
    {
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
    function _generateSVGRects(SVGParams memory params, mapping(uint8 => string[]) storage palettes)
        private
        view
        returns (string memory svg)
    {
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
            uint256 currentX = image.bounds.left;
            uint256 currentY = image.bounds.top;
            uint256 cursor;
            string[16] memory buffer;

            string memory part;
            for (uint256 i = 0; i < image.rects.length; i++) {
                Rect memory rect = image.rects[i];
                if (rect.colorIndex != 0) {
                    buffer[cursor] = lookup[rect.length];          // width
                    buffer[cursor + 1] = lookup[currentX];         // x
                    buffer[cursor + 2] = lookup[currentY];         // y
                    buffer[cursor + 3] = palette[rect.colorIndex]; // color

                    cursor += 4;

                    if (cursor >= 16) {
                        part = string(abi.encodePacked(part, _getChunk(cursor, buffer)));
                        cursor = 0;
                    }
                }

                currentX += rect.length;
                if (currentX == image.bounds.right) {
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
     * @notice Return a string that consists of all rects in the provided `buffer`.
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
            top: uint8(image[1]),
            right: uint8(image[2]),
            bottom: uint8(image[3]),
            left: uint8(image[4])
        });

        uint256 cursor;
        Rect[] memory rects = new Rect[]((image.length - 5) / 2);
        for (uint256 i = 5; i < image.length; i += 2) {
            rects[cursor] = Rect({ length: uint8(image[i]), colorIndex: uint8(image[i + 1]) });
            cursor++;
        }
        return DecodedImage({ paletteIndex: paletteIndex, bounds: bounds, rects: rects });
    }
}

// SPDX-License-Identifier: GPL-3.0

/// @title A library used to convert string to int

/***********************************************************
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@
@@@@@@@@@@@@@%[email protected]@@@@@@@@@@@@
[email protected]@@@@@@..............................
./@@@@@@@@@[email protected]@@....*@@@@.......*@@@@@@@@@.
./@@@@@@@[email protected]@@@@[email protected]@@[email protected]@@@@[email protected]@@@@.
@%[email protected]@[email protected]@[email protected]@@[email protected]
@%**.........,**.........................................**@
@@@@##.....##(**#######   .........  ,#######  .......###@@@
@@@@@@[email protected]@@@#  @@   @@   .........  ,@@  @@@  [email protected]@@@@@
@@@@@@[email protected]@#  @@@@@@@   .........  ,@@@@@@@  [email protected]@@@@@
@@@@@@[email protected]@@@@       @@%............       [email protected]@@@@@
@@@@@@@@@..../@@@@@@@@@[email protected]@@@@@@@
@@@@@@@@@............                   [email protected]@@@@@@@
@@@@@@@@@@@..........  @@@@@@@@@@@@@@%  .........*@@@@@@@@@@
@@@@@@@@@@@@@%....   @@//////////////#@@  [email protected]@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  @@@///////////////////@@   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@  ************************   @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@                             @@@@@@@@@@@@@@@
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
************************************************************/

pragma solidity ^0.8.6;

 library StringUtil {


    function parseInt(string memory _a) internal pure returns (uint _parsedInt) {
        return parseInt(_a, 0);
    }

    /**
     * @notice parse string to uint
     */
    function parseInt(string memory _a, uint _b) internal pure returns (uint _parsedInt) {
        bytes memory bresult = bytes(_a);
        uint mint = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((uint(uint8(bresult[i])) >= 48) && (uint(uint8(bresult[i])) <= 57)) {
                if (decimals) {
                   if (_b == 0) {
                       break;
                   } else {
                       _b--;
                   }
                }
                mint *= 10;
                mint += uint(uint8(bresult[i])) - 48;
            } else if (uint(uint8(bresult[i])) == 46) {
                decimals = true;
            }
        }
        if (_b > 0) {
            mint *= 10 ** _b;
        }
        return mint;
    }

 }

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

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
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}