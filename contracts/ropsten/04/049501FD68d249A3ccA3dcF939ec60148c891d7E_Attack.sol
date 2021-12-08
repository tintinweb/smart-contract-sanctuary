// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./ICryptoBees.sol";
import "./IHoney.sol";
import "./IHive.sol";
import "./IAttack.sol";

contract Attack is IAttack, Ownable, Pausable {
    event BearsAttacked(address indexed owner, uint256 indexed nonce, uint256 successes, uint256 value, uint256 errors);

    // reference to the contracts
    IHoney honeyContract = IHoney(0x3E63Aa06691bc9Fd34637f8324D851e51df823D4);
    ICryptoBees beesContract;
    IHive hiveContract;

    uint32[] private unrevealedAttacks;
    uint256 private unrevealedAttackIndex;

    uint256 public hiveCooldown = 60;
    uint256 public bearChance = 50;
    uint256 public bearCooldownBase = 16;
    uint256 public bearCooldownPerHiveDay = 4;

    /**
     */
    constructor() {}

    function setContracts(
        address _HONEY,
        address _BEES,
        address _HIVE
    ) external onlyOwner {
        honeyContract = IHoney(_HONEY);
        beesContract = ICryptoBees(_BEES);
        hiveContract = IHive(_HIVE);
    }

    function setHiveCooldown(uint256 cooldown) external onlyOwner {
        hiveCooldown = cooldown;
    }

    function setBearCooldownBase(uint256 cooldown) external onlyOwner {
        bearCooldownBase = cooldown;
    }

    function setBearCooldownPerHiveDay(uint256 cooldown) external onlyOwner {
        bearCooldownPerHiveDay = cooldown;
    }

    function setBearChance(uint256 chance) external onlyOwner {
        hiveCooldown = chance;
    }

    /** ATTACKS */
    function checkForDuplicates(uint16[] calldata hiveIds) internal pure {
        bool duplicates;
        for (uint256 i = 0; i < hiveIds.length; i++) {
            for (uint256 y = 0; y < hiveIds.length; y++) {
                if (i != y && hiveIds[i] == hiveIds[y]) duplicates = true;
            }
        }
        require(!duplicates, "CANNOT ATTACK SAME HIVE WITH TWO BEARS");
    }

    function manyBearsAttack(
        uint256 nonce,
        uint16[] calldata tokenIds,
        uint16[] calldata hiveIds,
        bool transfer
    ) external whenNotPaused _updateEarnings {
        require(tokenIds.length == hiveIds.length, "THE ARGUMENTS LENGTHS DO NOT MATCH");
        uint256 owed = 0;
        uint256 successes = 0;
        uint256 errors = 0;
        checkForDuplicates(hiveIds);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            require(beesContract.getOwnerOf(tokenIds[i]) == _msgSender(), "YOU ARE NOT THE OWNER");
            require(beesContract.getTokenData(tokenIds[i])._type == 2, "TOKEN NOT A BEAR");

            // check if hive is attackable
            if (hiveContract.getLastStolenHoneyTimestamp(hiveIds[i]) + hiveCooldown > block.timestamp) {
                errors += 1;
                continue;
            }
            // check if bear can attack
            if (beesContract.getTokenData(tokenIds[i]).cooldownTillTimestamp < block.timestamp) {
                errors += 1;
                continue;
            }
            uint256 beesAffected = hiveContract.getHiveOccupancy(hiveIds[i]) / 10;
            if (beesAffected == 0) beesAffected = 1;

            for (uint256 y = 0; y < beesAffected; y++) {
                if (((random(tokenIds[i] + y) & 0xFFFF) % hiveContract.getHiveOccupancy(hiveIds[i])) < 50) {
                    uint256 tokenId = hiveContract.getBeeTokenId(hiveIds[i], y);
                    owed += hiveContract.calculateBeeOwed(hiveIds[i], tokenId);
                    hiveContract.setBeeSince(hiveIds[i], tokenId, uint48(block.timestamp));
                    hiveContract.incSuccessfulAttacks(hiveIds[i]);
                    successes += 1;
                }
            }
            hiveContract.incTotalAttacks(hiveIds[i]);

            if (!transfer) beesContract.increaseTokensPot(tokenIds[i], uint32(owed));
            hiveContract.setLastStolenHoneyTimestamp(hiveIds[i], uint48(block.timestamp));
            beesContract.updateTokensLastAttack(tokenIds[i], uint48(block.timestamp), uint48(block.timestamp + 120));
        }
        emit BearsAttacked(_msgSender(), nonce, successes, owed, errors);
        if (transfer && owed > 0) honeyContract.mint(_msgSender(), owed);
    }

    /**
     * tracks $HONEY earnings to ensure it stops once 2.4 billion is eclipsed
     */
    modifier _updateEarnings() {
        // if (totalHoneyEarned < MAXIMUM_GLOBAL_HONEY) {
        //     totalHoneyEarned += ((block.timestamp - lastClaimTimestamp) * totalBeesStaked * DAILY_HONEY_RATE) / 1 days;
        //     lastClaimTimestamp = block.timestamp;
        // }
        _;
    }

    /**
     * generates a pseudorandom number
     * @param seed a value ensure different outcomes for different sources in the same block
     * @return a pseudorandom value
     */
    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(tx.origin, block.timestamp, seed))); //blockhash(block.number - 1),
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICryptoBees {
    struct Token {
        uint8 _type;
        uint32 pot;
        uint48 lastAttackTimestamp;
        uint48 cooldownTillTimestamp;
    }

    function getMinted() external view returns (uint256 m);

    function increaseTokensPot(uint256 tokenId, uint32 amount) external;

    function updateTokensLastAttack(
        uint256 tokenId,
        uint48 timestamp,
        uint48 till
    ) external;

    // function mintForEth(uint256 amount, bool presale) external payable;

    // function mintForHoney(uint256 amount) external;

    // function mintForWool(uint256 amount) external;

    function withdrawERC20(
        address erc20TokenAddress,
        address recipient,
        uint256 amount
    ) external;

    function getUnrevealed() external view returns (uint256);

    function getUnrevealedIndex() external view returns (uint256);

    function setUnrevealedIndex(uint256 index) external;

    function pushToUnrevealedToken(uint256 blockNumber) external;

    function mint(address owner, uint256 tokenId) external;

    function isWhitelisted(address who) external view returns (bool);

    function setPaused(bool _paused) external;

    function getTokenData(uint256 tokenId) external view returns (Token memory token);

    function getOwnerOf(uint256 tokenId) external view returns (address);

    function doesExist(uint256 tokenId) external view returns (bool exists);

    function setTokenType(uint256 tokenId, uint8 _type) external;

    function performTransferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function performSafeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IHoney {
    function mint(address to, uint256 amount) external;

    function mintGiveaway(address[] calldata addresses, uint256 amount) external;

    function burn(address from, uint256 amount) external;

    function disableGiveaway() external;

    function addController(address controller) external;

    function removeController(address controller) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IHive {
    struct Bee {
        address owner;
        uint32 tokenId;
        uint48 since;
        uint8 index;
    }

    struct BeeHive {
        uint48 startedTimestamp;
        uint48 lastCollectedHoneyTimestamp;
        uint48 lastStolenHoneyTimestamp;
        uint32 subtract;
        uint8 successfulAttacks;
        uint8 totalAttacks;
        uint8 successfulCollections;
        uint8 totalCollections;
        mapping(uint256 => Bee) bees;
        uint16[] beesArray;
    }

    function setHoneyContract(address _HONEY_CONTRACT) external;

    function setBeesContract(address _BEES_CONTRACT) external;

    function addManyToHive(
        address account,
        uint16[] calldata tokenIds,
        uint16[] calldata hiveIds
    ) external;

    function claimManyFromHive(
        uint16[] calldata tokenIds,
        uint16[] calldata hiveIds,
        uint16[] calldata newHiveIds
    ) external;

    // function manyBearsAttack(
    //     uint256 nonce,
    //     uint16[] calldata tokenIds,
    //     uint16[] calldata hiveIds,
    //     bool transfer
    // ) external;

    function setRescueEnabled(bool _enabled) external;

    function setPaused(bool _paused) external;

    function setBeeSince(
        uint256 hiveId,
        uint256 tokenId,
        uint48 since
    ) external;

    function calculateBeeOwed(uint256 hiveId, uint256 tokenId) external view returns (uint256 owed);

    function incSuccessfulAttacks(uint256 hiveId) external;

    function incTotalAttacks(uint256 hiveId) external;

    function setLastStolenHoneyTimestamp(uint256 hiveId, uint48 timestamp) external;

    function getLastStolenHoneyTimestamp(uint256 hiveId) external view returns (uint256 lastStolenHoneyTimestamp);

    function getHiveOccupancy(uint256 hiveId) external view returns (uint256 occupancy);

    function getBeeSinceTimestamp(uint256 hiveId, uint256 tokenId) external view returns (uint256 since);

    function getBeeTokenId(uint256 hiveId, uint256 index) external view returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IAttack {
    function setHiveCooldown(uint256 cooldown) external;

    function manyBearsAttack(
        uint256 nonce,
        uint16[] calldata tokenIds,
        uint16[] calldata hiveIds,
        bool transfer
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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