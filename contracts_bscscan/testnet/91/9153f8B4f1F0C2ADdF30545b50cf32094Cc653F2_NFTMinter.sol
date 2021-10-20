// SPDX-License-Identifier: UNLICENSED

// contracts/NFT.sol
// Author: Thanh Le (lythanh.xyz)
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface INFT {
    function createTokenForUser(uint256 tokenId, string memory uriOfToken, address ownerAddress) external;
}

contract NFTMinter is Ownable {

    address public nftContract;
    string public baseURI;

    mapping(address => bool) private _whitelistedMinters;
    uint256[] private _tokenIdList;
    mapping(uint256 => bool) private _tokenIdMark;

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

    constructor(address nftAddress) {
        nftContract = nftAddress;
        _whitelistedMinters[msg.sender] = true;
    }

    function preloadTokenIds(uint256[] memory ids) external onlyOwner {
        for (uint i = 0; i < ids.length; ++i) {
            require(_tokenIdMark[ids[i]] == false, "Token ID already added to server");
            _tokenIdMark[ids[i]] = true;
            _tokenIdList.push(ids[i]);
        }
    }

    function popTokenIds() external onlyOwner {
        uint256 tokenId = _tokenIdList[_tokenIdList.length - 1];
        _tokenIdList.pop();
        _tokenIdMark[tokenId] = false;
    }

    function countPreloadTokenIds() external view returns (uint256) {
        return _tokenIdList.length;
    }

    // mint a new token for owner
    function mintToken(address owner) public onlyWhitelistedMinter {
        require(_tokenIdList.length > 0, "No preload token ID left");
        uint256 tokenId = _tokenIdList[_tokenIdList.length - 1];
        _tokenIdList.pop();
        INFT(nftContract).createTokenForUser(tokenId, string(abi.encodePacked(baseURI, Strings.toString(tokenId))), owner);
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