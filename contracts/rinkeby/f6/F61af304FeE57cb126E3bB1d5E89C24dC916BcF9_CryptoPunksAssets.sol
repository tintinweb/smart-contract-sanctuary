// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/[email protected]/access/Ownable.sol";

contract CryptoPunksAssets is Ownable {

    enum Type { Kind, Face, Ear, Neck, Beard, Hair, Eyes, Mouth, Smoke, Nose }
    
    bytes private palette;
    mapping(uint64 => uint32) private composites;

    mapping(uint8 => bytes) private assets;
    mapping(uint8 => string) private assetNames;
    mapping(uint8 => Type) private assetTypes;
    mapping(string => uint8) private maleAssets;
    mapping(string => uint8) private femaleAssets;
    
    function destroy() external onlyOwner {
        selfdestruct(payable(owner()));
    }
    
    function composite(bytes1 index, bytes1 yr, bytes1 yg, bytes1 yb, bytes1 ya) external view returns (bytes4 rgba) {
        uint x = uint(uint8(index)) * 4;
        uint8 xAlpha = uint8(palette[x + 3]);
        if (xAlpha == 0xFF) {
            rgba = bytes4(
                    (uint32(uint8(palette[x])) << 24) |
                    (uint32(uint8(palette[x+1])) << 16) |
                    (uint32(uint8(palette[x+2])) << 8) |
                    uint32(xAlpha)
                );
        } else {
            uint64 key =
                (uint64(uint8(palette[x])) << 56) |
                (uint64(uint8(palette[x + 1])) << 48) |
                (uint64(uint8(palette[x + 2])) << 40) |
                (uint64(xAlpha) << 32) |
                (uint64(uint8(yr)) << 24) |
                (uint64(uint8(yg)) << 16) |
                (uint64(uint8(yb)) << 8) |
                (uint64(uint8(ya)));
            rgba = bytes4(composites[key]);
        }
    }
    
    function getAsset(uint8 index) external view returns (bytes memory encoding) {
        encoding = assets[index];
    }
    
    function getAssetName(uint8 index) external view returns (string memory text) {
        text = assetNames[index];        
    }

    function getAssetType(uint8 index) external view returns (uint8) {
        return uint8(assetTypes[index]);
    }

    function getAssetIndex(string calldata text, bool isMale) external view returns (uint8) {
        return isMale ? maleAssets[text] : femaleAssets[text];        
    }

    function getMappedAsset(uint8 index, bool toMale) external view returns (uint8) {
        return toMale ? maleAssets[assetNames[index]] : femaleAssets[assetNames[index]];
    }
    
    function setPalette(bytes memory encoding) external onlyOwner {
        palette = encoding;
    }

    function addComposites(uint64 key1, uint32 value1, uint64 key2, uint32 value2, uint64 key3, uint32 value3, uint64 key4, uint32 value4) external onlyOwner {
        composites[key1] = value1;
        composites[key2] = value2;
        composites[key3] = value3;
        composites[key4] = value4;
    }
    
    function addAsset(uint8 index, Type assetType, bool isMale, string memory name, bytes memory encoding) external onlyOwner {
        assets[index] = encoding;
        assetNames[index] = name;
        assetTypes[index] = assetType;
        if (isMale) {
            maleAssets[name] = index;
        } else {
            femaleAssets[name] = index;
        }
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

