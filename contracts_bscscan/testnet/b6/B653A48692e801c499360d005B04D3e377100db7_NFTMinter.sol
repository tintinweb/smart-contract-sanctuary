// SPDX-License-Identifier: UNLICENSED

// contracts/NFT.sol
// Author: Thanh Le (lythanh.xyz)
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface INFT {
    function createTokenForUser(uint256 tokenId, string memory uriOfToken, address ownerAddress) external;
}

contract NFTMinter is Ownable {

    using Counters for Counters.Counter;
    Counters.Counter[] private tokenCounters;

    address public nftContract;
    uint256 public totalGroup = 5; // total group of treasure box
    uint256[] public maxTokenCount = [900, 900, 900, 900, 899];
    uint256[] public baseTokenIndex = [100, 1100, 2100, 3100, 4100];
    uint256 public baseIndex;
    string public baseURI;

    mapping(address => bool) private _whitelistedMinters;

    event NFTMintersWhitelistChanged(address indexed minterAddress, bool allowance);

    /* Minter whitelisting */
    modifier onlyWhitelistedMinter() {
        require(_whitelistedMinters[msg.sender], "Minter not allowed.");
        _;
    }

    function setWhitelistedMinter(address minterAddress, bool allowance) external onlyOwner {
        _whitelistedMinters[minterAddress] = allowance;
        emit NFTMintersWhitelistChanged(minterAddress, allowance);
    }

    function whitelistedMinter(address minterAddress) external view returns (bool) {
        return (_whitelistedMinters[minterAddress]);
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI = uri;
    }

    constructor(address nftAddress, uint256 index) {
        _whitelistedMinters[msg.sender] = true;
        nftContract = nftAddress;
        for (uint i = 0; i < totalGroup; ++i) tokenCounters.push(Counters.Counter({_value : 0}));
        baseIndex = index;
    }

    // mint a new token to owner
    function mintToken(address owner, uint group) public onlyWhitelistedMinter {
        require(group < totalGroup, "Wrong group value");
        require(tokenCounters[group].current() < maxTokenCount[group], "Not enough token");
        // we can calculate using this equation because the first 4 groups have the same size
        tokenCounters[group].increment();
        uint256 tokenId = tokenCounters[group].current() + baseTokenIndex[group] + baseIndex;
        INFT(nftContract).createTokenForUser(tokenId, string(abi.encodePacked(baseURI, Strings.toString(tokenId))), owner);
    }

    // mint multiple tokens to owner
    function mintTokens(address owner, uint count, uint group) public onlyWhitelistedMinter {
        require(group < totalGroup, "Wrong group value");
        require(tokenCounters[group].current() + count <= maxTokenCount[group], "Not enough token");
        // we can calculate using this equation because the first 4 groups have the same size
        for (uint i = 0; i < count; ++i) {
            tokenCounters[group].increment();
            uint256 tokenId = tokenCounters[group].current() + baseTokenIndex[group] + baseIndex;
            INFT(nftContract).createTokenForUser(tokenId, string(abi.encodePacked(baseURI, Strings.toString(tokenId))), owner);
        }
    }

    function countMintedToken() external view returns (uint256[] memory){
        uint256[] memory counts = new uint256[](totalGroup);
        for (uint i = 0; i < totalGroup; ++i) {
            counts[i] = tokenCounters[i].current();
        }
        return counts;
    }

    function countAvailableToken() external view returns (uint256[] memory) {
        uint256[] memory counts = new uint256[](totalGroup);
        for (uint i = 0; i < totalGroup; ++i) {
            counts[i] = maxTokenCount[i] - tokenCounters[i].current();
        }
        return counts;
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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