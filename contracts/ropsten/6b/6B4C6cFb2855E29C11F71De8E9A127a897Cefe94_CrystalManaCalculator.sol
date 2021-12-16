// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./Interfaces.sol";

contract CrystalManaCalculator is Ownable, ICrystalManaCalculator {
    ICrystals public iCrystals;

    constructor(address crystalsAddress) Ownable() { 
        iCrystals = ICrystals(crystalsAddress);
    }

    function ownerSetCrystalsAddress(address addr) public onlyOwner {
        iCrystals = ICrystals(addr);
    }

    function claimableMana(uint256 crystalId) override public view returns (uint32) {
        uint256 daysSinceClaim = diffDays(
            iCrystals.crystalsMap(crystalId).lastClaim,
            block.timestamp
        );

        if (block.timestamp - iCrystals.crystalsMap(crystalId).lastClaim < 1 days) {
            return 0;
        }

        uint32 manaToProduce = uint32(daysSinceClaim) * iCrystals.getResonance(crystalId);

        // if capacity is reached, limit mana to capacity, ie Spin
        if (manaToProduce > iCrystals.getSpin(crystalId)) {
            manaToProduce = iCrystals.getSpin(crystalId);
        }

        return manaToProduce;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp)
        internal
        pure
        returns (uint256)
    {
        require(fromTimestamp <= toTimestamp);
        return (toTimestamp - fromTimestamp) / (24 * 60 * 60);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

struct Bag {
    uint64 totalManaProduced;
    uint64 mintCount;
}

struct Crystal {
    uint16 attunement;
    uint64 lastClaim;
    uint8 focus;
    uint32 levelManaProduced;
    uint32 regNum;
    uint16 lvlClaims;
}

interface ICrystalManaCalculator {
    function claimableMana(uint256 tokenId) external view returns (uint32);
}

interface ICrystalsMetadata {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface ICrystals {
    function crystalsMap(uint256 tokenID) external view returns (Crystal memory);
    function bags(uint256 tokenID) external view returns (Bag memory);
    function getResonance(uint256 tokenId) external view returns (uint32);
    function getSpin(uint256 tokenId) external view returns (uint32);
    function claimableMana(uint256 tokenID) external view returns (uint32);
    function availableClaims(uint256 tokenId) external view returns (uint8);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
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