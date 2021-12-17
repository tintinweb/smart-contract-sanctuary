// SPDX-License-Identifier: GPL-3.0

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

import {IFootySeeder} from "./IFootySeeder.sol";
import {IFootyDescriptor} from "./IFootyDescriptor.sol";

import "./Base64.sol";

pragma solidity ^0.8.0;

contract FootyDescriptor is IFootyDescriptor, Ownable {
    using Strings for uint256;
    using Strings for uint32;

    string[] public palette;

    string[] public backgrounds;

    bytes[] public kits;

    bytes[] public commonHeads;

    bytes[] public rareHeads;

    bytes[] public legendaryHeads;

    bytes[] public glasses;

    function colorCount() external view override returns (uint256) {
        return palette.length;
    }

    function backgroundCount() external view override returns (uint256) {
        return backgrounds.length;
    }

    function kitCount() external view override returns (uint256) {
        return kits.length;
    }

    function commonHeadCount() external view override returns (uint256) {
        return commonHeads.length;
    }

    function rareHeadCount() external view override returns (uint256) {
        return rareHeads.length;
    }

    function legendaryHeadCount() external view override returns (uint256) {
        return legendaryHeads.length;
    }

    function glassesCount() external view override returns (uint256) {
        return glasses.length;
    }

    function headCount() external view override returns (uint256) {
        return commonHeads.length + rareHeads.length + legendaryHeads.length;
    }

    function getCommonHead(uint256 index)
        external
        pure
        override
        returns (uint256)
    {
        return index;
    }

    function getRareHead(uint256 index)
        external
        view
        override
        returns (uint256)
    {
        return index + this.commonHeadCount();
    }

    function getLegendaryHead(uint256 index)
        external
        view
        override
        returns (uint256)
    {
        return index + this.commonHeadCount() + this.rareHeadCount();
    }

    // colors
    function addManyColorsToPalette(string[] calldata manyColors)
        external
        override
        onlyOwner
    {
        require(
            palette.length + manyColors.length <= 256,
            "Palettes can only hold 256 colors"
        );
        for (uint256 i = 0; i < manyColors.length; i++) {
            _addColorToPalette(manyColors[i]);
        }
    }

    function _addColorToPalette(string calldata _color) internal {
        palette.push(_color);
    }

    // backgrounds
    function addManyBackgrounds(string[] calldata manyBackgrounds)
        external
        override
        onlyOwner
    {
        for (uint256 i = 0; i < manyBackgrounds.length; i++) {
            _addBackground(manyBackgrounds[i]);
        }
    }

    function _addBackground(string calldata _background) internal {
        backgrounds.push(_background);
    }

    // kits
    function addManyKits(bytes[] calldata manyKits)
        external
        override
        onlyOwner
    {
        for (uint256 i = 0; i < manyKits.length; i++) {
            _addKit(manyKits[i]);
        }
    }

    function _addKit(bytes calldata _kit) internal {
        kits.push(_kit);
    }

    function swapKitAtIndex(uint32 index, bytes calldata _kit)
        external
        onlyOwner
    {
        kits[index] = _kit;
    }

    // heads
    function addManyCommonHeads(bytes[] calldata manyHeads)
        external
        override
        onlyOwner
    {
        for (uint256 i = 0; i < manyHeads.length; i++) {
            _addCommonHead(manyHeads[i]);
        }
    }

    function _addCommonHead(bytes calldata _head) internal {
        commonHeads.push(_head);
    }

    function swapCommonHeadAtIndex(uint32 index, bytes calldata _head)
        external
        onlyOwner
    {
        commonHeads[index] = _head;
    }

    function addManyRareHeads(bytes[] calldata manyHeads)
        external
        override
        onlyOwner
    {
        for (uint256 i = 0; i < manyHeads.length; i++) {
            _addRareHead(manyHeads[i]);
        }
    }

    function _addRareHead(bytes calldata _head) internal {
        rareHeads.push(_head);
    }

    function swapRareHeadAtIndex(uint32 index, bytes calldata _head)
        external
        onlyOwner
    {
        rareHeads[index] = _head;
    }

    function addManyLegendaryHeads(bytes[] calldata manyHeads)
        external
        override
        onlyOwner
    {
        for (uint256 i = 0; i < manyHeads.length; i++) {
            _addLegendaryHead(manyHeads[i]);
        }
    }

    function _addLegendaryHead(bytes calldata _head) internal {
        legendaryHeads.push(_head);
    }

    function swapLegendaryHeadAtIndex(uint32 index, bytes calldata _head)
        external
        onlyOwner
    {
        legendaryHeads[index] = _head;
    }

    function heads(uint256 index)
        external
        view
        override
        returns (bytes memory)
    {
        if (index < commonHeads.length) {
            return commonHeads[index];
        }

        if (index < rareHeads.length + commonHeads.length) {
            return rareHeads[index - commonHeads.length];
        }

        return legendaryHeads[index - commonHeads.length - rareHeads.length];
    }

    // glasses
    function addManyGlasses(bytes[] calldata manyGlasses)
        external
        override
        onlyOwner
    {
        for (uint256 i = 0; i < manyGlasses.length; i++) {
            _addGlasses(manyGlasses[i]);
        }
    }

    function _addGlasses(bytes calldata _glasses) internal {
        glasses.push(_glasses);
    }

    function _render(uint256 tokenId, IFootySeeder.FootySeed memory seed)
        internal
        view
        returns (string memory)
    {
        string memory image = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32" shape-rendering="crispEdges" width="256" height="256">'
                '<rect width="100%" height="100%" fill="',
                backgrounds[seed.background],
                '" />',
                _renderRects(this.heads(seed.head)),
                _renderRects(kits[seed.kit]),
                _renderRects(glasses[seed.glasses]),
                "</svg>"
            )
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"image": "data:image/svg+xml;base64,',
                                Base64.encode(bytes(image)),
                                '", "name": "Footy Noun #',
                                tokenId.toString(),
                                '", "number":"',
                                seed.number.toString(),
                                '", "kit":"',
                                seed.kit.toString(),
                                '", "head":"',
                                seed.head.toString(),
                                '", "glasses":"',
                                seed.glasses.toString(),
                                '"}'
                            )
                        )
                    )
                )
            );
    }

    function _renderRects(bytes memory data)
        private
        view
        returns (string memory)
    {
        string[32] memory lookup = [
            "0",
            "1",
            "2",
            "3",
            "4",
            "5",
            "6",
            "7",
            "8",
            "9",
            "10",
            "11",
            "12",
            "13",
            "14",
            "15",
            "16",
            "17",
            "18",
            "19",
            "20",
            "21",
            "22",
            "23",
            "24",
            "25",
            "26",
            "27",
            "28",
            "29",
            "30",
            "31"
        ];

        string memory rects;
        uint256 drawIndex = 0;
        for (uint256 i = 0; i < data.length; i = i + 2) {
            uint8 runLength = uint8(data[i]); // we assume runLength of any non-transparent segment cannot exceed image width (32px)
            uint8 colorIndex = uint8(data[i + 1]);
            if (colorIndex != 0 && colorIndex != 1) {
                // transparent
                uint8 x = uint8(drawIndex % 32);
                uint8 y = uint8(drawIndex / 32);
                string memory color = "#000000";
                if (colorIndex > 1) {
                    color = palette[colorIndex - 1];
                }
                rects = string(
                    abi.encodePacked(
                        rects,
                        '<rect width="',
                        lookup[runLength],
                        '" height="1" x="',
                        lookup[x],
                        '" y="',
                        lookup[y],
                        '" fill="',
                        color,
                        '" />'
                    )
                );
            }
            drawIndex += runLength;
        }

        return rects;
    }

    function tokenURI(uint256 tokenId, IFootySeeder.FootySeed memory seed)
        public
        view
        override
        returns (string memory)
    {
        string memory data = _render(tokenId, seed);
        return data;
    }

    function renderFooty(uint256 tokenId, IFootySeeder.FootySeed memory seed)
        public
        view
        override
        returns (string memory)
    {
        string memory data = _render(tokenId, seed);
        return data;
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

pragma solidity ^0.8.0;

import {IFootyDescriptor} from "./IFootyDescriptor.sol";

interface IFootySeeder {
    struct FootySeed {
        uint32 background;
        uint32 kit;
        uint32 head;
        uint32 glasses;
        uint32 number;
    }

    function generateFootySeed(uint256 tokenId, IFootyDescriptor descriptor)
        external
        view
        returns (FootySeed memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import {IFootySeeder} from "./IFootySeeder.sol";

interface IFootyDescriptor {
    function heads(uint256 index) external view returns (bytes memory);

    function colorCount() external view returns (uint256);

    function backgroundCount() external view returns (uint256);

    function kitCount() external view returns (uint256);

    function commonHeadCount() external view returns (uint256);

    function rareHeadCount() external view returns (uint256);

    function legendaryHeadCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function getCommonHead(uint256 index) external view returns (uint256);

    function getRareHead(uint256 index) external view returns (uint256);

    function getLegendaryHead(uint256 index) external view returns (uint256);

    function glassesCount() external view returns (uint256);

    function addManyColorsToPalette(string[] calldata manyColors) external;

    function addManyBackgrounds(string[] calldata manyBackgrounds) external;

    function addManyKits(bytes[] calldata manyKits) external;

    function addManyCommonHeads(bytes[] calldata manyHeads) external;

    function addManyRareHeads(bytes[] calldata manyHeads) external;

    function addManyLegendaryHeads(bytes[] calldata manyHeads) external;

    function addManyGlasses(bytes[] calldata manyGlasses) external;

    function tokenURI(uint256 tokenId, IFootySeeder.FootySeed memory seed)
        external
        view
        returns (string memory);

    function renderFooty(uint256 tokenId, IFootySeeder.FootySeed memory seed)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64

pragma solidity ^0.8.0;

library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
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