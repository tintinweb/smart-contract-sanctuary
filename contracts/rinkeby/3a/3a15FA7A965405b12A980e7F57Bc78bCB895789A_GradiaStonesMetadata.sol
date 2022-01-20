// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IGradiaStonesMetadata.sol";
import "./IGradiaStones.sol";

contract GradiaStonesMetadata is IGradiaStonesMetadata, Ownable {
    using Strings for uint256;

    event NewBatch(uint256 batchNumber, string BaseURI, uint256 LastStone);

    uint256[] public lastTokenOfBatch;
    uint256 public lastId;
    mapping(uint256 => string) public batchURI;
    address public mainContract;

    modifier onlyWhitelisted() {
        require(mainContract != address(0x0), "Main contract not set");
        require(IGradiaStones(mainContract).isWhitelisted(msg.sender), "You're not permitted to perform this action.");
        _;
    }

    constructor() {
        lastTokenOfBatch.push(0);
    }

    function getMetadata(uint256 tokenId) external view override returns (string memory) {
        for (uint256 i = 0; i < lastTokenOfBatch.length; i++) {
            if (lastTokenOfBatch[i] >= tokenId) {
                string memory base = batchURI[lastTokenOfBatch[i]];
                return string(abi.encodePacked(base, tokenId.toString()));
            }
        }
    }

    function setMainContract(address _address) external onlyOwner {
        mainContract = _address;
    }

    function getSingleBatchURI(uint256 batchNumber) external view returns (string memory) {
        require(batchNumber < lastTokenOfBatch.length && batchNumber > 0, "Batch number does not exist");
        return batchURI[lastTokenOfBatch[batchNumber]];
    }

    function setSingleBatchURI(uint256 batchNumber, string memory uri) external onlyWhitelisted {
        require(batchNumber > 0);
        require(batchNumber < lastTokenOfBatch.length);
        batchURI[lastTokenOfBatch[batchNumber]] = uri;
    }
    
    function getAllBatchURI() external view returns (string[] memory) {
        // batchNumber : batchURI : firstToken-lastToken
        string [] memory allBatches = new string [] (lastTokenOfBatch.length - 1);
        for (uint256 i = 1; i < lastTokenOfBatch.length; i++) {
            allBatches[i - 1] = string(abi.encodePacked(i.toString(), ":", batchURI[lastTokenOfBatch[i]],":",(lastTokenOfBatch[i - 1]+1).toString(),"-",lastTokenOfBatch[i].toString()));
        }
        return allBatches;
    }

    function setAllBatchURI(string [] calldata batchBaseURI) external onlyWhitelisted {
        require(batchBaseURI.length == lastTokenOfBatch.length - 1);
        for (uint256 i = 1; i < lastTokenOfBatch.length; i++) {
            batchURI[lastTokenOfBatch[i]] = batchBaseURI[i - 1];
        }
    }

    function createBatch(uint256 amount, string calldata batchBaseURI) external onlyWhitelisted {
        lastId += amount;
        lastTokenOfBatch.push(lastId);
        batchURI[lastId] = batchBaseURI;
        emit NewBatch(lastTokenOfBatch.length, batchBaseURI, lastId);
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

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IGradiaStonesMetadata {
  function getMetadata(
    uint256 tokenId
  ) external view returns (string memory);
}

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

abstract contract IGradiaStones {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual;
    function transferFrom(address from, address to, uint256 tokenId) external virtual;
    function isWhitelisted(address user) public view virtual returns (bool);
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