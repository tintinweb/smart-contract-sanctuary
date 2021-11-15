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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ILevelManager {
    struct Tier {
        string id;
        uint8 multiplier;
        uint256 lockingPeriod; // in seconds
        uint256 minAmount; // tier is applied when userAmount >= minAmount
        bool random;
        uint8 odds; // divider: 2 = 50%, 4 = 25%, 10 = 10%
    }

    function isLocked(address account) external view returns(bool);
    function getTierById(string calldata id) external view returns (Tier memory);
    function getUserTier(address account) external view returns (Tier memory);
    function getUserUnlockTime(address account) external view returns (uint256);
    function getTierIds() external view returns (string[] memory);
    function lock(address account, uint idoStart) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStakingLockable {
    function isLocked(address account) external view returns(bool);
    function getLockedAmount(address account) external view returns(uint256);
}

interface IStakingLockableExternal {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 pendingRewards;
    }
    function userInfo(address account) external view returns (UserInfo memory);
    function isLocked(address account) external view returns(bool);
    function getLockedAmount(address account) external view returns(uint256);
    function lock(address account) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStakingLockable.sol";
import "./ILevelManager.sol";
import "./WithLevels.sol";
import "./WithPools.sol";

contract LevelManager is Ownable, ILevelManager, WithLevels, WithPools {
    bool public lockEnabled = true;

    mapping(address => bool) isIDO;
    mapping(address => uint) public userUnlocksAt;

    event Lock(address indexed account, uint256 unlockTime, address locker);
    event LockEnabled(bool status);

    modifier onlyIDO() {
        require(isIDO[_msgSender()], "Only IDOs can lock");
        _;
    }

    function isLocked(address account) external view override returns (bool) {
        return lockEnabled && userUnlocksAt[account] > block.timestamp;
    }

    function getUserTier(address account) public view override returns (Tier memory) {
        return getTierForAmount(getUserAmount(account));
    }

    function getUserUnlockTime(address account) external view override returns (uint256) {
        return userUnlocksAt[account];
    }

    function getUserAmount(address account) public view returns (uint) {
        uint totalAmount = 0;

        for (uint256 i = 0; i < pools.length; i++) {
            IStakingLockableExternal pool = pools[i];
            address poolAddr = address(pool);
            uint multiplier = poolMultiplier[poolAddr];
            if (poolEnabled[poolAddr]) {
                try pool.getLockedAmount(account) returns (uint amount) {
                    totalAmount += amount * multiplier / 1_000_000_000;
                    continue;
                } catch {}

                try pool.userInfo(account) returns (IStakingLockableExternal.UserInfo memory userInfo) {
                    totalAmount += userInfo.amount * multiplier / 1_000_000_000;
                    continue;
                } catch {}
            }
        }

        return totalAmount;
    }

    function toggleLocking(bool status) external onlyOwner {
        lockEnabled = status;
        emit LockEnabled(status);
    }

    function addIDO(address account) external onlyOwner {
        require(account != address(0), "IDO cannot be zero address");
        isIDO[account] = true;
    }

    function lock(address account, uint idoStart) external override onlyIDO {
        internalLock(account, idoStart);
    }

    function internalLock(address account, uint idoStart) internal {
        require(idoStart >= block.timestamp, "LevelManager: IDO start must be in future");

        Tier memory tier = getUserTier(account);
        if (tier.lockingPeriod == 0) {
            return;
        }

        uint unlockTime = idoStart + tier.lockingPeriod;
        if (userUnlocksAt[account] < unlockTime) {
            userUnlocksAt[account] = unlockTime;
            emit Lock(account, unlockTime, _msgSender());

            // Support for old stakers
            for (uint256 i = 0; i < pools.length; i++) {
                IStakingLockableExternal pool = pools[i];
                address poolAddr = address(pool);
                if (poolEnabled[poolAddr]) {
                    try pool.lock(account) {} catch {}
                }
            }
        }
    }

    function unlock(address account) external onlyOwner {
        userUnlocksAt[account] = block.timestamp;
    }

    function batchLock(address[] calldata addresses) external onlyOwner {
        for (uint i = 0; i < addresses.length; i++) {
            internalLock(addresses[i], block.timestamp);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStakingLockable.sol";
import "./ILevelManager.sol";

abstract contract WithLevels is Ownable, ILevelManager {
    string constant noneTierId = "none";

    Tier[] public tiers;

    event TierCreate(string indexed id, uint8 multiplier, uint256 lockingPeriod, uint256 minAmount, bool random, uint8 odds);
    event TierUpdate(string indexed id, uint8 multiplier, uint256 lockingPeriod, uint256 minAmount, bool random, uint8 odds);
    event TierRemove(string indexed id, uint256 idx);

    constructor() {
        // Init with none level
        tiers.push(Tier(noneTierId, 0, 0, 0, false, 0));
    }

    function getTierIds() external view override returns (string[] memory) {
        string[] memory ids = new string[](tiers.length);
        for (uint i = 0; i < tiers.length; i++) {
            ids[i] = tiers[i].id;
        }

        return ids;
    }

    function getTierById(string calldata id) public view override returns (Tier memory) {
        for (uint256 i = 0; i < tiers.length; i++) {
            if (stringsEqual(tiers[i].id, id)) {
                return tiers[i];
            }
        }
        revert('No such tier');
    }

    function getTierForAmount(uint amount) internal view returns (Tier memory) {
        return tiers[getTierIdxForAmount(amount)];
    }

    function getTierIdxForAmount(uint amount) internal view returns (uint) {
        if (amount == 0) {
            return 0;
        }
        uint maxTierK = 0;
        uint256 maxTierV;
        for (uint i = 1; i < tiers.length; i++) {
            Tier storage tier = tiers[i];
            if (amount >= tier.minAmount && tier.minAmount > maxTierV) {
                maxTierK = i;
                maxTierV = tier.minAmount;
            }
        }

        return maxTierK;
    }

    function setTier(string calldata id, uint8 multiplier, uint256 lockingPeriod, uint256 minAmount, bool random, uint8 odds) external onlyOwner returns (uint256) {
        require(!stringsEqual(id, noneTierId), "Can't change 'none' tier");

        for (uint256 i = 0; i < tiers.length; i++) {
            if (stringsEqual(tiers[i].id, id)) {
                tiers[i].multiplier = multiplier;
                tiers[i].lockingPeriod = lockingPeriod;
                tiers[i].minAmount = minAmount;
                tiers[i].random = random;
                tiers[i].odds = odds;

                emit TierUpdate(id, multiplier, lockingPeriod, minAmount, random, odds);

                return i;
            }
        }

        Tier memory newTier = Tier(id, multiplier, lockingPeriod, minAmount, random, odds);
        tiers.push(newTier);

        emit TierCreate(id, multiplier, lockingPeriod, minAmount, random, odds);

        return tiers.length - 1;
    }

    function deleteTier(string calldata id) external onlyOwner {
        require(!stringsEqual(id, noneTierId), "Can't delete 'none' tier");

        for (uint256 tierIdx = 0; tierIdx < tiers.length; tierIdx++) {
            if (stringsEqual(tiers[tierIdx].id, id)) {
                for (uint i = tierIdx; i < tiers.length - 1; i++) {
                    tiers[i] = tiers[i + 1];
                }
                tiers.pop();

                emit TierRemove(id, tierIdx);
                break;
            }
        }
    }

    function stringsEqual(string memory a, string memory b) private pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStakingLockable.sol";
import "./ILevelManager.sol";

abstract contract WithPools is Ownable, ILevelManager {
    IStakingLockableExternal[] public pools;
    mapping(address => bool) public poolEnabled;
    // 1x = 100, 0.5x = 50
    mapping(address => uint) public poolMultiplier;

    event PoolEnabled(address indexed pool, bool status);
    event PoolMultiplierSet(address indexed pool, uint multiplier);

    function addPool(address pool, uint multiplier) external onlyOwner {
        pools.push(IStakingLockableExternal(pool));
        togglePool(pool, true);

        if (multiplier == 0) {
            multiplier = 100;
        }
        setPoolMultiplier(pool, multiplier);
    }

    function togglePool(address pool, bool status) public onlyOwner {
        poolEnabled[pool] = status;
        emit PoolEnabled(pool, status);
    }

    function setPoolMultiplier(address pool, uint multiplier) public onlyOwner {
        require(multiplier > 0, "LevelManager: Multiplier must be > 0");
        poolMultiplier[pool] = multiplier;
        emit PoolMultiplierSet(pool, multiplier);
    }
}

