// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./ICryptoBees.sol";
import "./IHoney.sol";
import "./IHive.sol";
import "./IAttack.sol";

contract Attack is IAttack, Ownable, Pausable {
    event BearsAttackPrepared(address indexed owner, uint256 indexed nonce, uint256 indexed tokenId, uint256 hiveId);
    event BearsAttackResolved(address indexed owner, uint256 indexed nonce, uint256 tokenId, uint256 successes, uint256 value, uint256 err);
    event BeekeeperAttackPrepared(address indexed owner, uint256 indexed nonce, uint256 indexed tokenId, uint256 hiveId);
    event BeekeeperAttackResolved(address indexed owner, uint256 indexed nonce, uint256 tokenId, uint256 value, uint256 err);

    Settings settings;

    ICryptoBees beesContract;
    IHive hiveContract;

    mapping(uint256 => UnresolvedAttack) public unresolvedAttacks;
    mapping(uint256 => UnresolvedAttack) public unresolvedCollections;

    constructor() {
        settings.bearChance = 40;
        settings.hiveProtectionBear = 4 * 60 * 60; // per success
        settings.beekeeperMultiplier = 4;
        settings.bearCooldownBase = 16 * 60 * 60;
        settings.bearCooldownPerHiveDay = 4 * 60 * 60;
        settings.beekeeperCooldownBase = 16 * 60 * 60;
        settings.beekeeperCooldownPerHiveDay = 4 * 60 * 60;
        settings.attacksToRestart = 7;
    }

    function setContracts(address _BEES, address _HIVE) external onlyOwner {
        beesContract = ICryptoBees(_BEES);
        hiveContract = IHive(_HIVE);
    }

    function setSettings(
        uint8 chance,
        uint24 protectionBear,
        uint8 multiplier,
        uint24 bearCooldown,
        uint24 bearPerHive,
        uint24 keeperCooldown,
        uint24 keeperPerHive,
        uint8 attacksToRestart
    ) external onlyOwner {
        settings.bearChance = chance;
        settings.beekeeperMultiplier = multiplier;
        settings.hiveProtectionBear = protectionBear;
        settings.bearCooldownBase = bearCooldown;
        settings.bearCooldownPerHiveDay = bearPerHive;
        settings.beekeeperCooldownBase = keeperCooldown;
        settings.beekeeperCooldownPerHiveDay = keeperPerHive;
        settings.attacksToRestart = attacksToRestart;
    }

    /** ATTACKS */
    function checkCanAttack(uint16[] calldata hiveIds, uint16[] calldata tokenIds) internal view {
        require(tokenIds.length == hiveIds.length, "ATTACK: THE ARGUMENTS LENGTHS DO NOT MATCH");
        bool duplicates;
        for (uint256 i = 0; i < hiveIds.length; i++) {
            require(beesContract.getTokenData(tokenIds[i])._type == 2, "ATTACK: MUST BE BEAR");
            require(beesContract.getOwnerOf(tokenIds[i]) == _msgSender() || hiveContract.getWaitingRoomOwner(tokenIds[i]) == _msgSender(), "ATTACK: YOU ARE NOT THE OWNER");
            for (uint256 y = 0; y < hiveIds.length; y++) {
                if (i != y && hiveIds[i] == hiveIds[y]) {
                    duplicates = true;
                    break;
                }
            }
        }
        require(!duplicates, "CANNOT ATTACK SAME HIVE WITH TWO BEARS");
    }

    function _resolveAttack(uint256 hiveId) private {
        UnresolvedAttack memory a = unresolvedAttacks[hiveId];
        // there is no unresolved attack for this hive
        if (a.block == 0) return;
        ICryptoBees.Token memory t = beesContract.getTokenData(a.tokenId);
        uint256 owed = 0;
        uint256 successes = 0;
        uint256 err = 0;

        // check if hive is attackable
        if ((hiveContract.getHiveProtectionBears(hiveId) > block.timestamp)) {
            err = 1;
        }

        if (err == 0) {
            uint256 seed = random(a.block);

            (owed, successes) = _attack(t.strength, hiveId, seed);

            // attack was successful let's update some stats
            if (successes >= 1) {
                hiveContract.incSuccessfulAttacks(hiveId);
                hiveContract.setBearAttackData(hiveId, uint32(block.timestamp), uint32(block.timestamp + (settings.hiveProtectionBear * successes)));

                // blow up the hive
                if (hiveContract.getHiveSuccessfulAttacks(hiveId) >= settings.attacksToRestart) {
                    hiveContract.resetHive(hiveId);
                }
                // get the rightful owner (the token might possibly be in the waiting room/staked)
                address _owner;
                if (beesContract.getOwnerOf(a.tokenId) != address(hiveContract)) _owner = beesContract.getOwnerOf(a.tokenId);
                else _owner = hiveContract.getWaitingRoomOwner(a.tokenId);
                beesContract.increaseTokensPot(_owner, owed);
            }
            hiveContract.incTotalAttacks(hiveId);
        }
        emit BearsAttackResolved(_msgSender(), a.nonce, a.tokenId, successes, owed, err);
    }

    function _attack(
        uint256 strength,
        uint256 hiveId,
        uint256 seed
    ) private returns (uint256, uint256) {
        uint256 owed = 0;
        uint256 successes = 0;
        // 5% of the hive
        uint256 beesAffected = hiveContract.getHiveOccupancy(hiveId) / 20;
        if (beesAffected < 5) beesAffected++;

        for (uint256 y = 0; y < beesAffected; y++) {
            if (((seed & 0xFFFF) % 100) < settings.bearChance + (strength * 3)) {
                uint256 beeId = hiveContract.getBeeTokenId(hiveId, y);
                owed += hiveContract.calculateBeeOwed(hiveId, beeId);
                // reset bee's honey
                hiveContract.setBeeSince(hiveId, beeId, uint48(block.timestamp));
                successes += 1;
            }
            if (beesAffected > 1) seed >>= 16;
        }
        return (owed, successes);
    }

    function resolveAttacks(uint16[] calldata hiveIds) public whenNotPaused {
        for (uint256 i = 0; i < hiveIds.length; i++) {
            _resolveAttack(hiveIds[i]);
            delete unresolvedAttacks[hiveIds[i]];
        }
    }

    function manyBearsAttack(
        uint256 nonce,
        uint16[] calldata tokenIds,
        uint16[] calldata hiveIds
    ) external whenNotPaused {
        checkCanAttack(hiveIds, tokenIds);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            _resolveAttack(hiveIds[i]);
            // check if bear can attack
            if (beesContract.getTokenData(tokenIds[i]).cooldownTillTimestamp < block.timestamp && (hiveContract.getHiveProtectionBears(hiveIds[i]) < block.timestamp)) {
                unresolvedAttacks[hiveIds[i]] = UnresolvedAttack({tokenId: tokenIds[i], block: uint64(block.number), nonce: uint48(nonce), howMuch: 0});

                uint48 hiveAge = uint48(block.timestamp) - hiveContract.getHiveAge(hiveIds[i]);
                uint256 cooldown = (((hiveAge / 86400) * settings.bearCooldownPerHiveDay) + settings.bearCooldownBase);
                beesContract.updateTokensLastAttack(tokenIds[i], uint48(block.timestamp), uint48(block.timestamp + cooldown));
                emit BearsAttackPrepared(_msgSender(), nonce, tokenIds[i], hiveIds[i]);
            } else {
                delete unresolvedAttacks[hiveIds[i]];
            }
        }
    }

    /** COLLECTION */
    function checkCanCollect(
        uint16[] calldata hiveIds,
        uint16[] calldata tokenIds,
        uint16[] calldata howMuch
    ) internal view {
        require(tokenIds.length == hiveIds.length && howMuch.length == hiveIds.length, "ATTACK: THE ARGUMENTS LENGTHS DO NOT MATCH");
        bool duplicates;
        for (uint256 i = 0; i < hiveIds.length; i++) {
            require(beesContract.getTokenData(tokenIds[i])._type == 3, "ATTACK: MUST BE BEEKEEPER");
            require(beesContract.getOwnerOf(tokenIds[i]) == _msgSender() || hiveContract.getWaitingRoomOwner(tokenIds[i]) == _msgSender(), "ATTACK: YOU ARE NOT THE OWNER");
            for (uint256 y = 0; y < hiveIds.length; y++) {
                if (i != y && hiveIds[i] == hiveIds[y]) {
                    duplicates = true;
                    break;
                }
            }
        }
        require(!duplicates, "CANNOT ATTACK SAME HIVE WITH TWO BEEKEEPERS");
    }

    function _resolveCollection(uint256 hiveId) private {
        UnresolvedAttack memory a = unresolvedCollections[hiveId];
        // there is no unresolved attack for this hive
        if (a.block == 0) return;
        ICryptoBees.Token memory t = beesContract.getTokenData(a.tokenId);
        uint256 owed = 0;
        uint256 owedPerBee = 0;
        uint256 err = 0;

        // check if hive is attackable
        if (hiveContract.isHiveProtectedFromKeepers(hiveId) == true) {
            err = 1;
        }

        if (err == 0) {
            uint256 seed = random(a.block);

            (owed, owedPerBee) = _collect(t.strength, hiveId, seed, a.howMuch);

            if (owed > 0) {
                hiveContract.setKeeperAttackData(hiveId, uint32(block.timestamp), uint32(owed), uint32(owedPerBee));
                address _owner;
                if (beesContract.getOwnerOf(a.tokenId) != address(hiveContract)) _owner = beesContract.getOwnerOf(a.tokenId);
                else _owner = hiveContract.getWaitingRoomOwner(a.tokenId);
                beesContract.increaseTokensPot(_owner, owed);
            }
        }
        emit BeekeeperAttackResolved(_msgSender(), a.nonce, a.tokenId, owed, err);
    }

    function _collect(
        uint256 strength,
        uint256 hiveId,
        uint256 seed,
        uint256 howMuch
    ) private view returns (uint256, uint256) {
        uint256 owed = 0;
        uint256 owedPerBee = 0;

        if (((seed & 0xFFFF) % 100) < 100 - (howMuch * settings.beekeeperMultiplier) + (strength * 3)) {
            uint256 beesTotal = hiveContract.getHiveOccupancy(hiveId);

            uint256 beeFirst = hiveContract.getBeeTokenId(hiveId, 0);
            uint256 beeLast = hiveContract.getBeeTokenId(hiveId, beesTotal - 1);
            uint256 avg = (hiveContract.calculateBeeOwed(hiveId, beeFirst) + hiveContract.calculateBeeOwed(hiveId, beeLast)) / 2;
            owed = (avg * beesTotal * howMuch) / 100;
            owedPerBee = (avg * howMuch) / 100;
        }
        return (owed, owedPerBee);
    }

    function resolveCollections(uint16[] calldata hiveIds) public whenNotPaused {
        for (uint256 i = 0; i < hiveIds.length; i++) {
            _resolveCollection(hiveIds[i]);
            delete unresolvedCollections[hiveIds[i]];
        }
    }

    function manyBeekeepersCollect(
        uint256 nonce,
        uint16[] calldata tokenIds,
        uint16[] calldata hiveIds,
        uint16[] calldata howMuch
    ) external whenNotPaused {
        checkCanCollect(hiveIds, tokenIds, howMuch);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _resolveCollection(hiveIds[i]);
            // check if keeper can attack
            if (beesContract.getTokenData(tokenIds[i]).cooldownTillTimestamp < block.timestamp && hiveContract.isHiveProtectedFromKeepers(hiveIds[i]) == false) {
                unresolvedCollections[hiveIds[i]] = UnresolvedAttack({tokenId: tokenIds[i], block: uint64(block.number), nonce: uint48(nonce), howMuch: uint8(howMuch[i])});
                uint48 hiveAge = uint48(block.timestamp) - hiveContract.getHiveAge(hiveIds[i]);
                uint256 cooldown = (((hiveAge / 1 days) * settings.beekeeperCooldownPerHiveDay) + settings.beekeeperCooldownBase);
                beesContract.updateTokensLastAttack(tokenIds[i], uint48(block.timestamp), uint48(block.timestamp + cooldown));
                emit BeekeeperAttackPrepared(_msgSender(), nonce, tokenIds[i], hiveIds[i]);
            } else {
                delete unresolvedCollections[hiveIds[i]];
            }
        }
    }

    /**
     * generates a pseudorandom number
     * @param blockNumber value ensure an attacker doesn't know
     * @return a pseudorandom value
     */
    function random(uint256 blockNumber) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(tx.origin, blockhash(blockNumber))));
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

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface ICryptoBees {
    struct Token {
        uint8 _type;
        uint8 color;
        uint8 eyes;
        uint8 mouth;
        uint8 nose;
        uint8 hair;
        uint8 accessory;
        uint8 feelers;
        uint8 strength;
        uint48 lastAttackTimestamp;
        uint48 cooldownTillTimestamp;
    }

    function getMinted() external view returns (uint256 m);

    function increaseTokensPot(address _owner, uint256 amount) external;

    function updateTokensLastAttack(
        uint256 tokenId,
        uint48 timestamp,
        uint48 till
    ) external;

    function mint(
        address addr,
        uint256 tokenId,
        bool stake
    ) external;

    function setPaused(bool _paused) external;

    function getTokenData(uint256 tokenId) external view returns (Token memory token);

    function getOwnerOf(uint256 tokenId) external view returns (address);

    function doesExist(uint256 tokenId) external view returns (bool exists);

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
        uint32 startedTimestamp;
        uint32 lastCollectedHoneyTimestamp;
        uint32 hiveProtectionBears;
        uint32 lastStolenHoneyTimestamp;
        uint32 collectionAmount;
        uint32 collectionAmountPerBee;
        uint8 successfulAttacks;
        uint8 totalAttacks;
        mapping(uint256 => Bee) bees;
        uint16[] beesArray;
    }

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

    function addToWaitingRoom(address account, uint256 tokenId) external;

    function removeFromWaitingRoom(uint256 tokenId, uint256 hiveId) external;

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

    function setBearAttackData(
        uint256 hiveId,
        uint32 timestamp,
        uint32 protection
    ) external;

    function setKeeperAttackData(
        uint256 hiveId,
        uint32 timestamp,
        uint32 collected,
        uint32 collectedPerBee
    ) external;

    function getLastStolenHoneyTimestamp(uint256 hiveId) external view returns (uint256 lastStolenHoneyTimestamp);

    function getHiveProtectionBears(uint256 hiveId) external view returns (uint256 hiveProtectionBears);

    function isHiveProtectedFromKeepers(uint256 hiveId) external view returns (bool);

    function getHiveOccupancy(uint256 hiveId) external view returns (uint256 occupancy);

    function getBeeSinceTimestamp(uint256 hiveId, uint256 tokenId) external view returns (uint256 since);

    function getBeeTokenId(uint256 hiveId, uint256 index) external view returns (uint256 tokenId);

    function getHiveAge(uint256 hiveId) external view returns (uint32);

    function getHiveSuccessfulAttacks(uint256 hiveId) external view returns (uint8);

    function getWaitingRoomOwner(uint256 tokenId) external view returns (address);

    function resetHive(uint256 hiveId) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

interface IAttack {
    struct Settings {
        uint8 bearChance;
        uint8 beekeeperMultiplier;
        uint24 hiveProtectionBear;
        uint24 hiveProtectionKeeper;
        uint24 bearCooldownBase;
        uint24 bearCooldownPerHiveDay;
        uint24 beekeeperCooldownBase;
        uint24 beekeeperCooldownPerHiveDay;
        uint8 attacksToRestart;
    }
    struct UnresolvedAttack {
        uint24 tokenId;
        uint48 nonce;
        uint64 block;
        uint32 howMuch;
    }
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