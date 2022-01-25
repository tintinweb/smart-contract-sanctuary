// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@0xsequence/sstore2/contracts/SSTORE2.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

import {Integers} from "../lib/Integers.sol";
import "./ChainRunnersConstants.sol";

import "../interfaces/IChainRunners.sol";
import "../interfaces/IDreamersRenderer.sol";

/*  @title Dreamers Renderer
    @author Clement Walter
    @dev Leverage the d attributes of svg <path> to encode a palette of base traits. Each runner trait
         is encoded as a combination of these base traits. More precisely, the Dreamers encoding scheme works as follows:
         - each one of the 330 traits is encoded as a list of <path />
         - each path combines a `d` and a `fill`
         - the storage contains the all the possible `d` and all the possible `fill`
         - each trait is then an ordered list of tuples (index of d, index of fill)
         - each dreamer is a list a trait and consequently still an ordered list of (index of d, index of fill)
*/
contract DreamersRenderer is
    IDreamersRenderer,
    Ownable,
    ReentrancyGuard,
    ChainRunnersConstants
{
    using Integers for uint8;
    using Strings for uint256;

    // We have a total of 3 bytes = 24 bits per Path
    uint8 public constant BITS_PER_D_INDEX = 12;
    uint8 public constant BITS_PER_FILL_INDEX = 12;

    // Each D is encoded with a sequence of 2 bits for each letter (M, L, Q, C) and 1 byte per attribute. Since each
    // letter does not have the same number of attributes, this number if stored as constant below as well.
    uint8 public constant BITS_PER_D_ATTRIBUTE = 3;
    bytes8 public constant D_ATTRIBUTE_PALETTE = hex"4d4c51434148565a"; // M L Q C A H V Z
    bytes8 public constant D_ATTRIBUTE_PARAMETERS_COUNT = hex"0202040607010100"; // 2 2 4 6 7 1 1 0
    bytes3 public constant NONE_COLOR = hex"000001";
    bytes public constant PATH_TAG_START = bytes("%3cpath%20d='");
    bytes public constant FILL_TAG = bytes("'%20fill='");
    bytes public constant STROKE_TAG = bytes("'%20stroke='%23000");
    bytes public constant PATH_TAG_END = bytes("'/%3e");
    bytes public constant HASHTAG = bytes("%23");
    bytes public constant SVG_TAG_START =
        bytes(
            "%3csvg%20xmlns='http://www.w3.org/2000/svg'%20viewBox='0%200%20255%20255'%20width='500px'%20height='500px'%3e"
        );
    bytes public constant SVG_TAG_END =
        bytes("%3cstyle%3epath{stroke-width:0.71}%3c/style%3e%3c/svg%3e");

    struct Trait {
        uint16 dIndex;
        uint16 fillIndex;
        bool stroke;
    }

    address public fillPalette;
    address[] public dPalette;
    address public dPaletteIndexes;
    address public traitPalette;
    address public traitPaletteIndexes;
    bytes layerIndexes;
    IChainRunners runnersToken;

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////  Rendering mechanics  /////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////
    /// @dev Colors are concatenated and stored in a single 'bytes' with SSTORE2 to save gas.
    function setFillPalette(bytes calldata _fillPalette) external onlyOwner {
        fillPalette = SSTORE2.write(_fillPalette);
    }

    /// @dev Only the d parameter is encoded for each path. All the paths are concatenated together to save gas.
    ///      The dPaletteIndexes is used to retrieve the path from the dPalette.
    function setDPalette(bytes[] calldata _pathPalette) external onlyOwner {
        for (uint8 i = 0; i < _pathPalette.length; i++) {
            dPalette.push(SSTORE2.write(_pathPalette[i]));
        }
    }

    /// @dev Since each SSTORE2 slots can contain up to 24kb, indexes need to be uint16, ie. two bytes per index.
    function setDPaletteIndex(bytes calldata _pathPaletteIndex)
        external
        onlyOwner
    {
        dPaletteIndexes = SSTORE2.write(_pathPaletteIndex);
    }

    /// @dev The traits are stored as a list of tuples (d index, fill index). For our case, 12 bits per index is
    ///      enough as 2^12 = 4096 is greater than total number of d and total number of fill to date.
    ///      This could be changed if needed.
    ///      Hence a trait is a sequence of several 3 bytes long (d index, fill index).
    function setTraitPalette(bytes calldata _traitPalette) external onlyOwner {
        traitPalette = SSTORE2.write(_traitPalette);
    }

    /// @dev Since each SSTORE2 slots can contain up to 24kb, indexes need to be uint16, ie. two bytes per index.
    ///      A trait can then be retrieved with traitPalette[traitPaletteIndexes[i]: traitPaletteIndexes[i+1]]
    function setTraitPaletteIndex(bytes calldata _traitPaletteIndex)
        external
        onlyOwner
    {
        traitPaletteIndexes = SSTORE2.write(_traitPaletteIndex);
    }

    /// @dev The trait indexes allow to map from the Chain Runners 2D indexation (trait index, layer index) to the
    ///      current 1D indexation (trait index).
    function setLayerIndexes(bytes calldata _layerIndexes) external onlyOwner {
        layerIndexes = _layerIndexes;
    }

    /// @dev This function will be the pendant of the ChainRunnersBaseRenderer.getLayer ones.
    function getTraitIndex(uint16 _layerIndex, uint16 _itemIndex)
        public
        view
        returns (uint16)
    {
        uint16 traitIndex = BytesLib.toUint16(layerIndexes, _layerIndex * 2);
        uint16 nextTraitIndex = BytesLib.toUint16(
            layerIndexes,
            (_layerIndex + 1) * 2
        );
        if (traitIndex + _itemIndex >= nextTraitIndex) {
            return type(uint16).max;
        }

        return traitIndex + _itemIndex;
    }

    /// @dev 3 bytes per color because svg does not handle alpha.
    function getFill(uint16 _index) public view returns (string memory) {
        // TODO: use assembly instead
        bytes memory palette = SSTORE2.read(fillPalette);
        if (
            palette[(_index * 3)] == NONE_COLOR[0] &&
            palette[(_index * 3) + 1] == NONE_COLOR[1] &&
            palette[(_index * 3) + 2] == NONE_COLOR[2]
        ) {
            return "none";
        }

        return
            string(
                bytes.concat(
                    HASHTAG,
                    bytes(uint8(palette[3 * _index]).toString(16, 2)),
                    bytes(uint8(palette[3 * _index + 1]).toString(16, 2)),
                    bytes(uint8(palette[3 * _index + 2]).toString(16, 2))
                )
            );
    }

    /// @dev Get the start and end indexes of the bytes concerning the given d in the dPalette storage.
    function getDIndex(uint16 _index) public view returns (uint32, uint32) {
        // TODO: use assembly instead
        bytes memory _indexes = SSTORE2.read(dPaletteIndexes);
        uint32 start = uint32(BytesLib.toUint16(_indexes, _index * 2));
        uint32 next = uint32(BytesLib.toUint16(_indexes, _index * 2 + 2));
        // Magic reasonable number to deal with overflow
        if (uint32(_index) > 1000 && start < 20000) {
            start = uint32(type(uint16).max) + 1 + start;
        }
        if (uint32(_index) > 2000 && start < 40000) {
            start = uint32(type(uint16).max) + 1 + start;
        }
        if (uint32(_index) > 1000 && next < 20000) {
            next = uint32(type(uint16).max) + 1 + next;
        }
        if (uint32(_index) > 2000 && next < 40000) {
            next = uint32(type(uint16).max) + 1 + next;
        }
        return (start, next);
    }

    /// @dev Retrieve the bytes for the given d from the dPalette storage. The bytes may be split into several SSTORE2
    ///      slots.
    function getDBytes(uint16 _index) public view returns (bytes memory) {
        // TODO: use assembly instead
        (uint32 dIndex, uint32 dIndexNext) = getDIndex(_index);
        uint256 storageIndex = 0;
        bytes memory _dPalette = SSTORE2.read(dPalette[storageIndex]);
        uint256 cumSumBytes = _dPalette.length;
        uint256 pos = dIndex;
        while (dIndex >= cumSumBytes) {
            pos -= _dPalette.length;
            storageIndex++;
            _dPalette = SSTORE2.read(dPalette[storageIndex]);
            cumSumBytes += _dPalette.length;
        }
        bytes memory _d = new bytes(dIndexNext - dIndex);
        for (uint256 i = 0; i < _d.length; i++) {
            if (pos >= _dPalette.length) {
                storageIndex++;
                _dPalette = SSTORE2.read(dPalette[storageIndex]);
                pos = 0;
            }
            _d[i] = _dPalette[pos];
            pos++;
        }
        return _d;
    }

    /// @dev Decodes the path and returns it as a plain string to be used in the svg path attribute.
    function getD(bytes memory dEncodedBytes)
        public
        pure
        returns (string memory)
    {
        bytes memory d;
        bytes memory bytesBuffer;
        uint32 bitsShift = 0;
        uint16 byteIndex = 0;
        uint8 bitShiftRemainder = 0;
        uint8 dAttributeIndex;
        uint8 dAttributeParameterCount;
        while (
            bitsShift <= dEncodedBytes.length * 8 - (BITS_PER_D_ATTRIBUTE + 8) // at least BITS_PER_D_ATTRIBUTE bits for the d attribute index and 1 byte for the d attribute parameter count
        ) {
            byteIndex = uint16(bitsShift / 8);
            bitShiftRemainder = uint8(bitsShift % 8);

            dAttributeIndex =
                uint8(
                    (dEncodedBytes[byteIndex] << bitShiftRemainder) |
                        (dEncodedBytes[byteIndex + 1] >>
                            (8 - bitShiftRemainder))
                ) >>
                (8 - BITS_PER_D_ATTRIBUTE);

            dAttributeParameterCount = uint8(
                D_ATTRIBUTE_PARAMETERS_COUNT[dAttributeIndex]
            );

            bitsShift += BITS_PER_D_ATTRIBUTE;
            byteIndex = uint16(bitsShift / 8);
            bitShiftRemainder = uint8(bitsShift % 8);
            bytesBuffer = new bytes(dAttributeParameterCount);
            // TODO: use assembly instead
            for (uint8 i = 0; i < dAttributeParameterCount; i++) {
                bytesBuffer[i] =
                    dEncodedBytes[byteIndex + i] <<
                    bitShiftRemainder;
                if (byteIndex + i + 1 < dEncodedBytes.length) {
                    bytesBuffer[i] |=
                        dEncodedBytes[byteIndex + i + 1] >>
                        (8 - bitShiftRemainder);
                }
            }

            d = bytes.concat(
                d,
                D_ATTRIBUTE_PALETTE[dAttributeIndex],
                bytes(uint8(bytesBuffer[0]).toString())
            );
            for (uint8 i = 1; i < dAttributeParameterCount; i++) {
                d = bytes.concat(
                    d,
                    hex"2c", // comma
                    bytes(uint8(bytesBuffer[i]).toString())
                );
            }
            bitsShift += 8 * dAttributeParameterCount;
        }
        return string(d);
    }

    /// @dev Used to concat all the traits of a given dreamers given the array of trait indexes.
    function getTraits(uint16[NUM_LAYERS] memory _index)
        public
        view
        returns (Trait[] memory)
    {
        // First: retrieve all bytes indexes
        bytes memory _traitPaletteIndexes = SSTORE2.read(traitPaletteIndexes);
        bytes memory _traitPalette = SSTORE2.read(traitPalette);

        bytes memory traitsBytes;
        uint16 start;
        uint16 next;
        for (uint16 i = 0; i < NUM_LAYERS; i++) {
            if (_index[i] == type(uint16).max) {
                continue;
            }
            start = BytesLib.toUint16(_traitPaletteIndexes, _index[i] * 2);
            next = BytesLib.toUint16(_traitPaletteIndexes, _index[i] * 2 + 2);
            traitsBytes = bytes.concat(
                traitsBytes,
                BytesLib.slice(_traitPalette, start, next - start)
            );
        }

        // Second: retrieve all traits
        bool stroke;
        Trait[] memory traits = new Trait[](traitsBytes.length / 3);
        for (uint256 i = 0; i < traitsBytes.length; i += 3) {
            (uint16 dIndex, uint16 fillIndex) = Integers.load12x2(
                traitsBytes[i],
                traitsBytes[i + 1],
                traitsBytes[i + 2]
            );
            stroke = fillIndex % 2 > 0;
            fillIndex = fillIndex >> 1;
            traits[i / 3] = Trait(dIndex, fillIndex, stroke);
        }
        return traits;
    }

    /// @notice Useful for returning a single Traits in the Runner's meaning
    function getTrait(uint16 _index) public view returns (Trait[] memory) {
        uint16[NUM_LAYERS] memory _indexes;
        _indexes[0] = _index;
        for (uint256 i = 1; i < NUM_LAYERS; i++) {
            _indexes[i] = type(uint16).max;
        }
        return getTraits(_indexes);
    }

    ////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////  Dreamers  ///////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    /// @dev Each trait is the bytes representation of the final svg string concatenating several <path> elements.
    function getSvg(Trait[] memory traits) public view returns (string memory) {
        bytes memory svg = SVG_TAG_START;
        for (uint16 i = 0; i < traits.length; i++) {
            svg = bytes.concat(
                svg,
                PATH_TAG_START,
                bytes(getD(getDBytes(traits[i].dIndex))),
                FILL_TAG,
                bytes(getFill(traits[i].fillIndex))
            );
            if (traits[i].stroke) {
                svg = bytes.concat(svg, STROKE_TAG);
            }
            svg = bytes.concat(svg, PATH_TAG_END);
        }
        return string(bytes.concat(svg, SVG_TAG_END));
    }

    constructor(address _rendererAddress, address _runnersTokenAddress)
        ChainRunnersConstants(_rendererAddress)
    {
        runnersToken = IChainRunners(_runnersTokenAddress);
    }

    /// @notice The Dreamer's full DNA is an alteration of its corresponding Runner's DNA with it's consumed candy.
    ///      The candy ids are hardcoded while it should be better to retrieve their effects from the CandyShop
    ///      contract.
    /// @dev Somehow copied from the original code but returns an array of trait indexes instead of Layer structs.
    ///      Flags for no layer is also updated from empty `Layer` to index = type(uint16).max.
    function getTokenData(uint256 runnerDna, uint8 dreamerDna)
        public
        view
        returns (uint16[NUM_LAYERS] memory traitIndexes)
    {
        uint16[NUM_LAYERS] memory dna = splitNumber(runnerDna);
        uint16[NUM_LAYERS] memory candyEffect = splitNumber(
            uint256(keccak256(abi.encodePacked(dreamerDna)))
        );

        if (dreamerDna % 4 == 0) {
            // CHAIN_METH
            dna[0] = candyEffect[0];
            dna[6] = candyEffect[6];
            dna[7] = candyEffect[7];
            dna[8] = candyEffect[8];
            dna[10] = candyEffect[10];
            dna[11] = candyEffect[11];
            dna[12] = candyEffect[12];
        } else if (dreamerDna % 4 == 1) {
            // SOMNUS_TEARS
            dna[1] = candyEffect[1];
            dna[2] = candyEffect[2];
            dna[3] = candyEffect[3];
            dna[4] = candyEffect[4];
            dna[5] = candyEffect[5];
            dna[9] = candyEffect[9];
        }

        uint16 raceIndex = chainRunnersBaseRenderer.getRaceIndex(dna[1]);
        bool hasFaceAcc = dna[7] < (NUM_RUNNERS - WEIGHTS[raceIndex][7][7]);
        bool hasMask = dna[8] < (NUM_RUNNERS - WEIGHTS[raceIndex][8][7]);
        bool hasHeadBelow = dna[9] < (NUM_RUNNERS - WEIGHTS[raceIndex][9][36]);
        bool hasHeadAbove = dna[11] <
            (NUM_RUNNERS - WEIGHTS[raceIndex][11][48]);
        bool useHeadAbove = (dna[0] % 2) > 0;
        for (uint8 i = 0; i < NUM_LAYERS; i++) {
            uint8 layerTraitIndex = chainRunnersBaseRenderer.getLayerIndex(
                dna[i],
                i,
                raceIndex
            );
            if (dreamerDna % 4 == 2) {
                // HELIUM_SPICE
                if (candyEffect[0] % 10 == 0) {
                    layerTraitIndex = 44;
                }
            }
            uint16 traitIndex = getTraitIndex(i, layerTraitIndex);
            /*
            These conditions help make sure layer selection meshes well visually.
            1. If mask, no face/eye acc/mouth acc
            2. If face acc, no mask/mouth acc/face
            3. If both head above & head below, randomly choose one
            */
            bool consistencyCheck = (((i == 2 || i == 12) &&
                !hasMask &&
                !hasFaceAcc) ||
                (i == 7 && !hasMask) ||
                (i == 10 && !hasMask) ||
                (i < 2 || (i > 2 && i < 7) || i == 8 || i == 9 || i == 11));
            bool noHeadCheck = ((hasHeadBelow &&
                hasHeadAbove &&
                (i == 9 && useHeadAbove)) || (i == 11 && !useHeadAbove));
            bool isRealTrait = traitIndex < type(uint16).max;
            if (!isRealTrait || !consistencyCheck || noHeadCheck) {
                traitIndex = type(uint16).max;
            }
            traitIndexes[i] = traitIndex;
        }
        return traitIndexes;
    }

    function tokenURI(uint256 tokenId, uint8 dreamerDna)
        external
        view
        override
        returns (string memory)
    {
        uint256 runnerDna = runnersToken.getDna(tokenId);
        uint16[NUM_LAYERS] memory traitIndexes = getTokenData(
            runnerDna,
            dreamerDna
        );
        Trait[] memory traits = getTraits(traitIndexes);
        return
            string(
                abi.encodePacked(
                    "{",
                    '"image_data": "',
                    getSvg(traits),
                    '", ',
                    '"name": "Dreamer%20',
                    HASHTAG,
                    tokenId.toString(),
                    '", ',
                    '"description": "Runners%20run,%20but%20sometimes%20they%20dream.%20This%20is%20one%20of%20their%20dreams.",',
                    '"attributes": ""}'
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Integers Library updated from https://github.com/willitscale/solidity-util
 *
 * In summary this is a simple library of integer functions which allow a simple
 * conversion to and from strings
 *
 * @author Clement Walter <[email protected]>
 */
library Integers {
    /**
     * To String
     *
     * Converts an unsigned integer to the string equivalent value, returned as bytes
     * Equivalent to javascript's toString(base)
     *
     * @param _number The unsigned integer to be converted to a string
     * @param _base The base to convert the number to
     * @param  _padding The target length of the string; result will be padded with 0 to reach this length while padding
     *         of 0 means no padding
     * @return bytes The resulting ASCII string value
     */
    function toString(
        uint256 _number,
        uint8 _base,
        uint8 _padding
    ) public pure returns (string memory) {
        uint256 count = 0;
        uint256 b = _number;
        while (b != 0) {
            count++;
            b /= _base;
        }
        if (_number == 0) {
            count++;
        }
        bytes memory res;
        if (_padding == 0) {
            res = new bytes(count);
        } else {
            res = new bytes(_padding);
        }
        for (uint256 i = 0; i < count; ++i) {
            b = _number % _base;
            if (b < 10) {
                res[res.length - i - 1] = bytes1(uint8(b + 48)); // 0-9
            } else {
                res[res.length - i - 1] = bytes1(uint8((b % 10) + 65)); // A-F
            }
            _number /= _base;
        }

        for (uint256 i = count; i < _padding; ++i) {
            res[res.length - i - 1] = hex"30"; // 0
        }

        return string(res);
    }

    function toString(uint256 _number) public pure returns (string memory) {
        return toString(_number, 10, 0);
    }

    function toString(uint256 _number, uint8 _base)
        public
        pure
        returns (string memory)
    {
        return toString(_number, _base, 0);
    }

    /**
     * Load 16
     *
     * Converts two bytes to a 16 bit unsigned integer
     *
     * @param _leadingBytes the first byte of the unsigned integer in [256, 65536]
     * @param _endingBytes the second byte of the unsigned integer in [0, 255]
     * @return uint16 The resulting integer value
     */
    function load16(bytes1 _leadingBytes, bytes1 _endingBytes)
        public
        pure
        returns (uint16)
    {
        return
            (uint16(uint8(_leadingBytes)) << 8) + uint16(uint8(_endingBytes));
    }

    /**
     * Load 12
     *
     * Converts three bytes into two uint12 integers
     *
     * @return (uint16, uint16) The two uint16 values up to 2^12 each
     */
    function load12x2(
        bytes1 first,
        bytes1 second,
        bytes1 third
    ) public pure returns (uint16, uint16) {
        return (
            (uint16(uint8(first)) << 4) + (uint16(uint8(second)) >> 4),
            (uint16(uint8(second & hex"0f")) << 8) + uint16(uint8(third))
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../interfaces/IChainRunnersBaseRenderer.sol";

/*  @title Chain Runners constants
    @author Clement Walter
    @notice This contracts is used to retrieve constants used by the Chain Runners that are not exposed
            by the Chain Runners contracts.
*/
contract ChainRunnersConstants {
    uint16[][13][3] public WEIGHTS;
    uint8 public constant NUM_LAYERS = 13;
    uint16 public constant NUM_RUNNERS = 10_000;
    IChainRunnersBaseRenderer chainRunnersBaseRenderer;

    constructor(address _rendererAddress) {
        chainRunnersBaseRenderer = IChainRunnersBaseRenderer(_rendererAddress);

        WEIGHTS[0][0] = [
            36,
            225,
            225,
            225,
            360,
            135,
            27,
            360,
            315,
            315,
            315,
            315,
            225,
            180,
            225,
            180,
            360,
            180,
            45,
            360,
            360,
            360,
            27,
            36,
            360,
            45,
            180,
            360,
            225,
            360,
            225,
            225,
            360,
            180,
            45,
            360,
            18,
            225,
            225,
            225,
            225,
            180,
            225,
            361
        ];
        WEIGHTS[0][1] = [
            875,
            1269,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            17,
            8,
            41
        ];
        WEIGHTS[0][2] = [
            303,
            303,
            303,
            303,
            151,
            30,
            0,
            0,
            151,
            151,
            151,
            151,
            30,
            303,
            151,
            30,
            303,
            303,
            303,
            303,
            303,
            303,
            30,
            151,
            303,
            303,
            303,
            303,
            303,
            303,
            303,
            303,
            3066
        ];
        WEIGHTS[0][3] = [
            645,
            0,
            1290,
            322,
            645,
            645,
            645,
            967,
            322,
            967,
            645,
            967,
            967,
            973
        ];
        WEIGHTS[0][4] = [
            0,
            0,
            0,
            1250,
            1250,
            1250,
            1250,
            1250,
            1250,
            1250,
            1250
        ];
        WEIGHTS[0][5] = [
            121,
            121,
            121,
            121,
            121,
            121,
            243,
            0,
            0,
            0,
            0,
            121,
            121,
            243,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            121,
            121,
            243,
            121,
            121,
            243,
            0,
            0,
            0,
            121,
            121,
            243,
            121,
            121,
            306
        ];
        WEIGHTS[0][6] = [
            925,
            555,
            185,
            555,
            925,
            925,
            185,
            1296,
            1296,
            1296,
            1857
        ];
        WEIGHTS[0][7] = [88, 88, 88, 88, 88, 265, 442, 8853];
        WEIGHTS[0][8] = [189, 189, 47, 18, 9, 28, 37, 9483];
        WEIGHTS[0][9] = [
            340,
            340,
            340,
            340,
            340,
            340,
            34,
            340,
            340,
            340,
            340,
            170,
            170,
            170,
            102,
            238,
            238,
            238,
            272,
            340,
            340,
            340,
            272,
            238,
            238,
            238,
            238,
            170,
            34,
            340,
            340,
            136,
            340,
            340,
            340,
            340,
            344
        ];
        WEIGHTS[0][10] = [
            159,
            212,
            106,
            53,
            26,
            159,
            53,
            265,
            53,
            212,
            159,
            265,
            53,
            265,
            265,
            212,
            53,
            159,
            239,
            53,
            106,
            5,
            106,
            53,
            212,
            212,
            106,
            159,
            212,
            265,
            212,
            265,
            5066
        ];
        WEIGHTS[0][11] = [
            139,
            278,
            278,
            250,
            250,
            194,
            222,
            278,
            278,
            194,
            222,
            83,
            222,
            278,
            139,
            139,
            27,
            278,
            278,
            278,
            278,
            27,
            278,
            139,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            27,
            139,
            139,
            139,
            139,
            0,
            278,
            194,
            83,
            83,
            278,
            83,
            27,
            306
        ];
        WEIGHTS[0][12] = [981, 2945, 654, 16, 981, 327, 654, 163, 3279];

        // Skull
        WEIGHTS[1][0] = [
            36,
            225,
            225,
            225,
            360,
            135,
            27,
            360,
            315,
            315,
            315,
            315,
            225,
            180,
            225,
            180,
            360,
            180,
            45,
            360,
            360,
            360,
            27,
            36,
            360,
            45,
            180,
            360,
            225,
            360,
            225,
            225,
            360,
            180,
            45,
            360,
            18,
            225,
            225,
            225,
            225,
            180,
            225,
            361
        ];
        WEIGHTS[1][1] = [
            875,
            1269,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            17,
            8,
            41
        ];
        WEIGHTS[1][2] = [
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            10000
        ];
        WEIGHTS[1][3] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        WEIGHTS[1][4] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        WEIGHTS[1][5] = [
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            384,
            7692,
            1923,
            0,
            0,
            0,
            0,
            0,
            1
        ];
        WEIGHTS[1][6] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 10000];
        WEIGHTS[1][7] = [0, 0, 0, 0, 0, 909, 0, 9091];
        WEIGHTS[1][8] = [0, 0, 0, 0, 0, 0, 0, 10000];
        WEIGHTS[1][9] = [
            526,
            526,
            526,
            0,
            0,
            0,
            0,
            0,
            526,
            0,
            0,
            0,
            526,
            0,
            526,
            0,
            0,
            0,
            526,
            526,
            526,
            526,
            526,
            526,
            526,
            526,
            526,
            526,
            526,
            0,
            0,
            526,
            0,
            0,
            0,
            0,
            532
        ];
        WEIGHTS[1][10] = [
            80,
            0,
            400,
            240,
            80,
            0,
            240,
            0,
            0,
            80,
            80,
            80,
            0,
            0,
            0,
            0,
            80,
            80,
            0,
            0,
            80,
            80,
            0,
            80,
            80,
            80,
            80,
            80,
            0,
            0,
            0,
            0,
            8000
        ];
        WEIGHTS[1][11] = [
            289,
            0,
            0,
            0,
            0,
            404,
            462,
            578,
            578,
            0,
            462,
            173,
            462,
            578,
            0,
            0,
            57,
            0,
            57,
            0,
            57,
            57,
            578,
            289,
            578,
            57,
            0,
            57,
            57,
            57,
            578,
            578,
            0,
            0,
            0,
            0,
            0,
            0,
            57,
            289,
            578,
            0,
            0,
            0,
            231,
            57,
            0,
            0,
            1745
        ];
        WEIGHTS[1][12] = [714, 714, 714, 0, 714, 0, 0, 0, 7144];

        // Bot
        WEIGHTS[2][0] = [
            36,
            225,
            225,
            225,
            360,
            135,
            27,
            360,
            315,
            315,
            315,
            315,
            225,
            180,
            225,
            180,
            360,
            180,
            45,
            360,
            360,
            360,
            27,
            36,
            360,
            45,
            180,
            360,
            225,
            360,
            225,
            225,
            360,
            180,
            45,
            360,
            18,
            225,
            225,
            225,
            225,
            180,
            225,
            361
        ];
        WEIGHTS[2][1] = [
            875,
            1269,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            779,
            17,
            8,
            41
        ];
        WEIGHTS[2][2] = [
            303,
            303,
            303,
            303,
            151,
            30,
            0,
            0,
            151,
            151,
            151,
            151,
            30,
            303,
            151,
            30,
            303,
            303,
            303,
            303,
            303,
            303,
            30,
            151,
            303,
            303,
            303,
            303,
            303,
            303,
            303,
            303,
            3066
        ];
        WEIGHTS[2][3] = [
            645,
            0,
            1290,
            322,
            645,
            645,
            645,
            967,
            322,
            967,
            645,
            967,
            967,
            973
        ];
        WEIGHTS[2][4] = [2500, 2500, 2500, 0, 0, 0, 0, 0, 0, 2500, 0];
        WEIGHTS[2][5] = [
            0,
            0,
            0,
            0,
            0,
            0,
            588,
            588,
            588,
            588,
            588,
            0,
            0,
            588,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            588,
            588,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            588,
            0,
            0,
            4
        ];
        WEIGHTS[2][6] = [
            925,
            555,
            185,
            555,
            925,
            925,
            185,
            1296,
            1296,
            1296,
            1857
        ];
        WEIGHTS[2][7] = [88, 88, 88, 88, 88, 265, 442, 8853];
        WEIGHTS[2][8] = [183, 274, 274, 18, 18, 27, 36, 9170];
        WEIGHTS[2][9] = [
            340,
            340,
            340,
            340,
            340,
            340,
            34,
            340,
            340,
            340,
            340,
            170,
            170,
            170,
            102,
            238,
            238,
            238,
            272,
            340,
            340,
            340,
            272,
            238,
            238,
            238,
            238,
            170,
            34,
            340,
            340,
            136,
            340,
            340,
            340,
            340,
            344
        ];
        WEIGHTS[2][10] = [
            217,
            362,
            217,
            144,
            72,
            289,
            144,
            362,
            72,
            289,
            217,
            362,
            72,
            362,
            362,
            289,
            0,
            217,
            0,
            72,
            144,
            7,
            217,
            72,
            217,
            217,
            289,
            217,
            289,
            362,
            217,
            362,
            3269
        ];
        WEIGHTS[2][11] = [
            139,
            278,
            278,
            250,
            250,
            194,
            222,
            278,
            278,
            194,
            222,
            83,
            222,
            278,
            139,
            139,
            27,
            278,
            278,
            278,
            278,
            27,
            278,
            139,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            278,
            27,
            139,
            139,
            139,
            139,
            0,
            278,
            194,
            83,
            83,
            278,
            83,
            27,
            306
        ];
        WEIGHTS[2][12] = [981, 2945, 654, 16, 981, 327, 654, 163, 3279];
    }

    function splitNumber(uint256 _number)
        public
        pure
        returns (uint16[NUM_LAYERS] memory numbers)
    {
        for (uint256 i = 0; i < numbers.length; i++) {
            numbers[i] = uint16(_number % NUM_RUNNERS);
            _number >>= 14;
        }
        return numbers;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IChainRunners {
    function getDna(uint256 _tokenId) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IDreamersRenderer {
    function tokenURI(uint256 tokenId, uint8 dreamerDna)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end); 

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }
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
pragma solidity 0.8.4;

interface IChainRunnersBaseRenderer {
    function getRaceIndex(uint16 _dna) external view returns (uint8);

    function getLayerIndex(
        uint16 _dna,
        uint8 _index,
        uint16 _raceIndex
    ) external view returns (uint8);
}