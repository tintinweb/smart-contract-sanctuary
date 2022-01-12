// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OneMillionPixel is Ownable {
    /**
     * @dev Emitted when `colors` value of the pixel block `id` are updated.
     */
    event PixelBlockColorsChanged(uint16 id, uint8[] colors);

    event PixelBlockTooltipChanged(uint16 id, string tooltip);

    event PixelBlockHrefChanged(uint16 id, string href);

    event PixelBlockOwnershipTransferred(uint16 id, address owner);

    /**
     * @dev Emitted when `pixelBlockPrice` value is updated.
     */
    event PixelBlockPriceChanged(uint pixelBlockPrice);

    // The pixel block price
    uint private _pixelBlockPrice = 50 ether; // Currently deployed on Polygon MATIC price ~$2.00

    // The color of each pixel in a pixel block
    mapping(uint16 => uint8[]) private _pixelBlocksColors;

    mapping(uint16 => string) private _pixelBlocksTooltip;

    mapping(uint16 => string) private _pixelBlocksHref;

    // The pixel blocks owners
    mapping(uint16 => address) private _pixelBlocksOwner;

    mapping(address => uint16[]) private _ownerPixelBlocks;

    constructor() {
    }

    /**
     * @dev Sets a new pixel block price
     *
     * Requirements:
     *
     * - `pixelBlockPrice` cannot be less than 0 and greater then the current pixel block price.
     */
    function setPixelBlockPrice(uint pixelBlockPrice) public onlyOwner {
        require(
            pixelBlockPrice > 0,
            "OneMillionPixel: the pixel block price should be greater than 0"
        );

        emit PixelBlockPriceChanged(pixelBlockPrice);

        _pixelBlockPrice = pixelBlockPrice;
    }

    /**
     * @dev Returns the current pixel block price.
     */
    function getPixelBlockPrice() public view returns (uint) {
        return _pixelBlockPrice;
    }

    /**
     * @dev Sets a new pixel block colors
     *
     * Requirements:
     *
     * - `id` should be a owned pixel block.
     * - `colors` should be an array with 100 values for each pixel.
     */
    function setPixelBlockColors(uint16 id, uint8[] memory colors) public {
        require(
            _pixelBlocksOwner[id] == msg.sender,
            "OneMillionPixel: caller is not the owner"
        );

        require(
            colors.length == 100,
            "OneMillionPixel: the colors should contains 100 values"
        );

        emit PixelBlockColorsChanged(id, colors);

        _pixelBlocksColors[id] = colors;
    }

    /**
     * @dev Sets a new pixel blocks colors
     *
     * Requirements:
     *
     * - `ids` should be the owned pixel blocks.
     * - `colors` should be an array for each pixel block that should be a sub array with 100 values for each pixel.
     */
    function setPixelBlocksColors(uint16[] memory ids, uint8[][] memory colors) public {
        require(
            ids.length == colors.length,
            "OneMillionPixel: the number of ids and colors is not the same"
        );

        for (uint16 i = 0; i < ids.length; i++) {
            setPixelBlockColors(ids[i], colors[i]);
        }
    }

    /**
     * @dev Returns the current pixel block colors.
     */
    function getPixelBlockColors(uint16 id) public view returns (uint8[] memory) {
        return _pixelBlocksColors[id];
    }

    function setPixelBlocksTooltips(uint16[] memory ids, string[] memory tooltips) public {
        require(
            ids.length == tooltips.length,
            "OneMillionPixel: the number of ids and tooltips is not the same"
        );

        for (uint16 i = 0; i < ids.length; i++) {
            setPixelBlockTooltip(ids[i], tooltips[i]);
        }
    }

    function setPixelBlockTooltip(uint16 id, string memory tooltip) public {
        require(
            _pixelBlocksOwner[id] == msg.sender,
            "OneMillionPixel: caller is not the owner"
        );

        emit PixelBlockTooltipChanged(id, tooltip);

        _pixelBlocksTooltip[id] = tooltip;
    }

    function getPixelBlockTooltip(uint16 id) public view returns (string memory) {
        return _pixelBlocksTooltip[id];
    }

    function setPixelBlocksHrefs(uint16[] memory ids, string[] memory hrefs) public {
        require(
            ids.length == hrefs.length,
            "OneMillionPixel: the number of ids and hrefs is not the same"
        );

        for (uint16 i = 0; i < ids.length; i++) {
            setPixelBlockHref(ids[i], hrefs[i]);
        }
    }

    function setPixelBlockHref(uint16 id, string memory href) public {
        require(
            _pixelBlocksOwner[id] == msg.sender,
            "OneMillionPixel: caller is not the owner"
        );

        emit PixelBlockHrefChanged(id, href);

        _pixelBlocksHref[id] = href;
    }

    function getPixelBlockHref(uint16 id) public view returns (string memory) {
        return _pixelBlocksHref[id];
    }

    function transferPixelBlocksOwnership(uint16[] memory ids, address to) public {
        for (uint16 i = 0; i < ids.length; i++) {
            transferPixelBlockOwnership(ids[i], to);
        }
    }

    function transferPixelBlockOwnership(uint16 id, address to) public {
        require(
            _pixelBlocksOwner[id] == msg.sender,
            "OneMillionPixel: caller is not the owner"
        );

        require(
            to != address(0),
            "OneMillionPixel: can not transfer to null address"
        );

        _setPixelBlockOwnership(id, to);
    }

    function _setPixelBlockOwnership(uint16 id, address newOwner) private {
        if (_pixelBlocksOwner[id] != address(0)) {
            uint16[] memory currentOwnerPixelBlocks = new uint16[](_ownerPixelBlocks[_pixelBlocksOwner[id]].length - 1);
            uint16 j = 0;
            for (uint16 i = 0; i < _ownerPixelBlocks[_pixelBlocksOwner[id]].length; i++) {
                if (_ownerPixelBlocks[_pixelBlocksOwner[id]][i] != id) {
                    currentOwnerPixelBlocks[j] = _ownerPixelBlocks[_pixelBlocksOwner[id]][i];
                    j++;
                }
            }
            _ownerPixelBlocks[_pixelBlocksOwner[id]] = currentOwnerPixelBlocks;
        }

        _pixelBlocksOwner[id] = newOwner;
        _ownerPixelBlocks[newOwner].push(id);

        emit PixelBlockOwnershipTransferred(id, newOwner);
    }

    /**
     * @dev Returns the current owner of a pixel block.
     */
    function getPixelBlockOwner(uint16 id) public view returns (address) {
        return _pixelBlocksOwner[id];
    }

    function getOwnerPixelBlocks(address owner) public view returns (uint16[] memory) {
        return _ownerPixelBlocks[owner];
    }

    /**
     * @dev Mints pixel blocks
     */
    function mint(uint16[] memory ids) public payable {
        require(
            msg.value >= _pixelBlockPrice * ids.length,
            "OneMillionPixel: not enough ether"
        );

        for (uint16 i = 0; i < ids.length; i++) {
            require(
                _pixelBlocksOwner[ids[i]] == address(0),
                string(abi.encodePacked(
                    "OneMillionPixel: the pixel block #",
                    Strings.toString(ids[i]),
                    " is already minted"
                ))
            );

            require(
                ids[i] > 0 && ids[i] <= 10000,
                "OneMillionPixel: the pixel block id should be greater than 0 and less or equal than 10000"
            );
        }

        for (uint16 i = 0; i < ids.length; i++) {
            emit PixelBlockOwnershipTransferred(ids[i], msg.sender);

            _setPixelBlockOwnership(ids[i], msg.sender);
        }
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
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