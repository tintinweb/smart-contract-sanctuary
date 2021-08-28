/**
 *Submitted for verification at polygonscan.com on 2021-08-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/GSN/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/interfaces/IAssetManager.sol

interface IAssetManager {
    function getCategoryLength() external view returns(uint8);
    function getAssetLength() external view returns(uint256);
    function getAssetToken(uint16 index_) external view returns(address);
    function getAssetCategory(uint16 index_) external view returns(uint8);
    function getIndexesByCategory(uint8 category_, uint256 categoryIndex_) external view returns(uint16);
    function getIndexesByCategoryLength(uint8 category_) external view returns(uint256);
}

// File: contracts/AssetManager.sol

// This contract is owned by Timelock.
contract AssetManager is IAssetManager, Ownable {

    struct Asset {
        address token;
        uint8 category;  // 0 - low, 1 - medium, 2 - high
    }

    uint8 public categoryLength;

    Asset[] public assets;  // Every asset have a unique index.

    mapping(uint8 => uint16[]) private indexesByCategory;

    function setCategoryLength(uint8 length_) external onlyOwner {
        categoryLength = length_;
    }

    function setAsset(uint16 index_, address token_, uint8 category_) external onlyOwner {
        if (index_ < assets.length) {
            assets[index_].token = token_;
            assets[index_].category = category_;
        } else {
            Asset memory asset;
            asset.token = token_;
            asset.category = category_;
            assets.push(asset);
        }
    }

    // Anyone can call this function, but it doesn't matter.
    function resetIndexesByCategory(uint8 category_) external {
        delete indexesByCategory[category_];

        for (uint16 i = 0; i < uint16(assets.length); ++i) {
            if (assets[i].category == category_) {
                indexesByCategory[category_].push(i);
            }
        }
    }

    function getCategoryLength() external override view returns(uint8) {
        return categoryLength;
    }

    function getAssetLength() external override view returns(uint256) {
        return assets.length;
    }

    function getAssetToken(uint16 index_) external override view returns(address) {
        return assets[index_].token;
    }

    function getAssetCategory(uint16 index_) external override view returns(uint8) {
        return assets[index_].category;
    }

    function getIndexesByCategory(uint8 category_, uint256 categoryIndex_) external override view returns(uint16) {
        return indexesByCategory[category_][categoryIndex_];
    }

    function getIndexesByCategoryLength(uint8 category_) external override view returns(uint256) {
        return indexesByCategory[category_].length;
    }
}