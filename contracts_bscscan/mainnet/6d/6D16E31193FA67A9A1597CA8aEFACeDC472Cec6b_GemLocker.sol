// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/EnumerableSetUpgradeable.sol";

import "./IGemLocker.sol";
import "../libs/IBEP20.sol";
import "../libs/SafeBEP20.sol";

/// @title GemLocker
/// @notice Contract for locking and unlocking gem rewards. Gem rewards are locked during the first month after launch
/// @dev Called by Bank
contract GemLocker is Initializable, AccessControlUpgradeable, IGemLocker, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    /// @notice Locked farming rewards info
    /// `amount` Amount locked
    /// `lockedUntilDay` Amount locked until day specified, 100% available from lockedUntilDay
    struct LockedFarmingRewards {
        uint256 amount;
        uint256 lockedUntilDay;
    }

    /// @notice Locked bonus rewards from staking clam or burning pearl
    /// `bonusRemaining` Remaining bonus rewards of the account
    /// `bonusRemainingCorrected` Remaining pearl bonus rewards, accounts for stake deposited/withdrawn in farm
    /// `startDay` Day when bonus was added
    /// `endDay` Bonus will be linearly available between startDay and endDay. After endDay bonus rewards will be 100% available
    /// `lastRewardDay` last day user claimed reward
    struct LockedNftBonus {
        uint256 bonusRemaining;
        uint256 bonusRemainingCorrected;
        uint256 startDay;
        uint256 endDay;
        uint256 lastRewardDay;
    }

    /// @notice Data of stake withdrawn/deposited
    /// `totalBalance` Total balance of farm at beginning of day. Gets assigned once, is not updated
    /// `withdrawn` Withdrawn stake
    /// `deposited` Deposited stake
    struct StakeData {
        uint256 totalBalance;
        uint256 withdrawn;
        uint256 deposited;
    }

    bytes32 public constant UPDATER_ROLE = keccak256("UPDATER_ROLE");
    uint256 public constant secondsPerDay = 86400;
    /// @notice 100% in basis points
    uint256 public constant bps = 10000;
    IBEP20 public gem;
    /// @notice timestamp of deployment. Used for calculating day
    uint256 public startTimestamp;
    /// @notice duration of farming rewards lock in days
    uint256 public farmingRewardsLockDuration;
    /// @notice duration of nft rewards lock in days
    uint256 public nftRewardsLockDuration;
    /// @notice max times rewards can be locked per reward type.
    /// @notice if max is reached, user should wait until rewards are unlocked and harvest to make space
    uint256 public maxRewardsLock;

    /// @notice array of structs per address
    mapping(address => LockedFarmingRewards[]) public lockedFarmingRewards;
    /// @notice array of structs per address, per id
    mapping(address => mapping(uint256 => LockedNftBonus)) public lockedClamRewards;
    /// @notice array of structs per address, per id
    mapping(address => mapping(uint256 => LockedNftBonus)) public lockedPearlRewards;

    mapping(address => uint256) public totalFarmingRewardsLocked;
    mapping(address => uint256) public totalClamRewardsLocked;
    mapping(address => uint256) public totalPearlRewardsLocked;

    /// @dev Array of ids of clams staked per user
    mapping(address => EnumerableSetUpgradeable.UintSet) private clamIdsStakedPerUser;
    /// @dev Array of ids of pearls burned per user
    mapping(address => EnumerableSetUpgradeable.UintSet) private pearlIdsBurnedPerUser;

    /// @notice data of withdrawn and/or deposited stake, per address, per day. Withdrawn stake cut pearl rewards
    mapping(address => mapping(uint256 => StakeData)) public stakeData;

    /// @notice Total Gem locked
    uint256 public totalLocked;

    event GemLocked(address indexed account, uint256 value);
    event GemUnlocked(address indexed account, uint256 value);
    event ForceUnlocked(address indexed account, uint256 value);
    event DepositStake(address indexed account, uint256 deposited);
    event WithdrawStake(address indexed account, uint256 withdrawn);

    function initialize(IBEP20 _gem) external initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

        gem = _gem;
        startTimestamp = block.timestamp;
        /// @notice unlock happens on the 7th day after current day
        farmingRewardsLockDuration = 7;
        /// @notice nft rewards are linearly available during 30 days. 100% available after
        nftRewardsLockDuration = 30;
        maxRewardsLock = 7;
    }

    /* View functions */

    /// @notice get current day, where startTimestamp is day 0
    /// @return day
    function getDay() public view override returns (uint256) {
        return block.timestamp.sub(startTimestamp).div(secondsPerDay);
    }

    function lockedFarmingRewardsLength(address _account) external view override returns (uint256) {
        return lockedFarmingRewards[_account].length;
    }

    /// @notice Amount of clams staked per user at current record
    function clamsStakedPerUserLength(address user) external view override returns (uint256) {
        return clamIdsStakedPerUser[user].length();
    }

    /// @notice return staked clam id of user at index of set
    function clamIdsStakedPerUserAt(address _account, uint256 _index) external view override returns (uint256) {
        return clamIdsStakedPerUser[_account].at(_index);
    }

    /// @notice Amount of pearls burned per user at current record
    function pearlsBurnedPerUserLength(address _account) external view override returns (uint256) {
        return pearlIdsBurnedPerUser[_account].length();
    }

    /// @notice return burned pearl id of user at index of set
    function pearlIdsBurnedPerUserAt(address _account, uint256 _index) external view override returns (uint256) {
        return pearlIdsBurnedPerUser[_account].at(_index);
    }

    function totalLockedRewards(address _account) public view override returns (uint256 total) {
        total = totalFarmingRewardsLocked[_account].add(totalClamRewardsLocked[_account]).add(
            totalPearlRewardsLocked[_account]
        );
    }

    /// @notice currently locked farming rewards that can be unlocked
    function pendingFarmingRewards(address _account) public view override returns (uint256 amount) {
        LockedFarmingRewards[] memory lockedFarmingRewardsArray = lockedFarmingRewards[_account];
        if (lockedFarmingRewardsArray.length == 0 || totalFarmingRewardsLocked[_account] == 0) return 0;

        uint256 currentDay = getDay();
        if (lockedFarmingRewardsArray[lockedFarmingRewardsArray.length.sub(1)].lockedUntilDay < currentDay) {
            amount = totalFarmingRewardsLocked[_account];
        } else {
            for (uint256 i = 0; i < lockedFarmingRewardsArray.length; i++) {
                if (lockedFarmingRewardsArray[i].lockedUntilDay <= currentDay) {
                    amount = amount.add(lockedFarmingRewardsArray[i].amount);
                } else break;
            }
        }
    }

    function pendingClamRewards(address _user) public view override returns (uint256 totalBonusPending) {
        for (uint256 i = 0; i < clamIdsStakedPerUser[_user].length(); i++) {
            uint256 clamId = clamIdsStakedPerUser[_user].at(i);
            LockedNftBonus memory bonusInfo = lockedClamRewards[_user][clamId];
            totalBonusPending = totalBonusPending.add(
                calculateRewards(bonusInfo.startDay, bonusInfo.endDay, bonusInfo.bonusRemaining)
            );
        }
    }

    function pendingPearlRewards(address _user) public view override returns (uint256 totalBonusPending) {
        for (uint256 i = 0; i < pearlIdsBurnedPerUser[_user].length(); i++) {
            uint256 clamId = pearlIdsBurnedPerUser[_user].at(i);
            LockedNftBonus memory bonusInfo = lockedPearlRewards[_user][clamId];
            totalBonusPending = totalBonusPending.add(
                calculateRewards(bonusInfo.startDay, bonusInfo.endDay, bonusInfo.bonusRemainingCorrected)
            );
        }
    }

    function calculateRewards(
        uint256 _startDay,
        uint256 _endDay,
        uint256 _bonusRemaining
    ) private view returns (uint256) {
        uint256 passedDays = getDay().sub(_startDay);

        return _bonusRemaining.mul(passedDays).div(_endDay);
    }

    /// @notice total unlockable amount
    /// @param _account Owner of tokens
    /// @return amount Amount that can be unlocked
    function canUnlockAmount(address _account) external view override returns (uint256 amount) {
        uint256 farmingRewards = pendingFarmingRewards(_account);
        uint256 clamRewards = pendingClamRewards(_account);
        uint256 pearlRewards = pendingPearlRewards(_account);

        amount = farmingRewards.add(clamRewards).add(pearlRewards);
    }

    /* Mutative functions */

    /// @notice Lock farming rewards for a certain account. Will stay locked until lockedUntilDay
    /// @param _account Owner of tokens
    /// @param _amount Amount of tokens
    function lockFarmingRewards(address _account, uint256 _amount) external override nonReentrant {
        require(_account != address(0), "lockFarmingRewards: Can't lock to address(0)");
        require(_amount > 0, "lockFarmingRewards: Lock amount must be greater than 0");
        require(
            lockedFarmingRewards[_account].length < maxRewardsLock,
            "lockFarmingRewards: Max reached, harvest rewards to make space"
        );

        totalLocked = totalLocked.add(_amount);
        totalFarmingRewardsLocked[_account] = totalFarmingRewardsLocked[_account].add(_amount);

        uint256 unlockDay = getDay().add(farmingRewardsLockDuration);
        LockedFarmingRewards[] storage lockedRewards = lockedFarmingRewards[_account];
        uint256 arrayLength = lockedRewards.length;
        if (arrayLength == 0 || lockedRewards[arrayLength.sub(1)].lockedUntilDay < unlockDay) {
            lockedRewards.push(LockedFarmingRewards({lockedUntilDay: unlockDay, amount: _amount}));
        } else {
            lockedRewards[arrayLength.sub(1)].amount = lockedRewards[arrayLength.sub(1)].amount.add(_amount);
        }

        gem.safeTransferFrom(msg.sender, address(this), _amount);

        emit GemLocked(_account, _amount);
    }

    /// @notice Lock clam rewards for a certain account. Will stay locked until lockedUntilDay
    /// @param _account Owner of tokens
    /// @param _amount Amount of tokens
    function lockClamRewards(
        address _account,
        uint256 _amount,
        uint256 _clamId
    ) external override nonReentrant {
        require(_account != address(0), "lockClamRewards: Can't lock to address(0)");
        require(_amount > 0, "lockClamRewards: Lock amount must be greater than 0");

        totalLocked = totalLocked.add(_amount);
        totalClamRewardsLocked[_account] = totalClamRewardsLocked[_account].add(_amount);

        clamIdsStakedPerUser[_account].add(_clamId);
        lockedClamRewards[_account][_clamId] = LockedNftBonus({
            bonusRemaining: _amount,
            bonusRemainingCorrected: _amount,
            startDay: getDay(), // rewards available from next day
            endDay: getDay().add(nftRewardsLockDuration),
            lastRewardDay: getDay()
        });

        gem.safeTransferFrom(msg.sender, address(this), _amount);

        emit GemLocked(_account, _amount);
    }

    /// @notice Lock pearl rewards for a certain account. Will stay locked until lockedUntilDay
    /// @param _account Owner of tokens
    /// @param _amount Amount of tokens
    function lockPearlRewards(
        address _account,
        uint256 _amount,
        uint256 _pearlId
    ) external override nonReentrant {
        require(_account != address(0), "lockPearlRewards: Can't lock to address(0)");
        require(_amount > 0, "lockPearlRewards: Lock amount must be greater than 0");

        totalLocked = totalLocked.add(_amount);
        totalPearlRewardsLocked[_account] = totalPearlRewardsLocked[_account].add(_amount);

        pearlIdsBurnedPerUser[_account].add(_pearlId);
        lockedPearlRewards[_account][_pearlId] = LockedNftBonus({
            bonusRemaining: _amount,
            bonusRemainingCorrected: _amount,
            startDay: getDay(), // rewards available from next day
            endDay: getDay().add(nftRewardsLockDuration),
            lastRewardDay: getDay()
        });

        gem.safeTransferFrom(msg.sender, address(this), _amount);

        emit GemLocked(_account, _amount);
    }

    /// @notice unlock and transfer available farming rewards
    /// @return unlockAmount amount to be unlocked from farming rewards
    /// @dev returns same amount as unlockableFarmingRewards, but this function mutates state
    function unlockFarmingRewards(address _account) private returns (uint256 unlockAmount) {
        if (lockedFarmingRewards[_account].length == 0 || totalFarmingRewardsLocked[_account] == 0) return 0;

        LockedFarmingRewards[] memory lockedFarmingRewardsArray = lockedFarmingRewards[_account];
        // Solidity can't delete a struct from an array.
        // Instead we delete the whole array and make a new one without the value we want to delete, if needed.
        delete lockedFarmingRewards[_account];

        uint256 currentDay = getDay();
        if (lockedFarmingRewardsArray[lockedFarmingRewardsArray.length.sub(1)].lockedUntilDay < currentDay) {
            unlockAmount = totalFarmingRewardsLocked[_account];
            delete totalFarmingRewardsLocked[_account];
        } else {
            LockedFarmingRewards[] storage lockedRewards = lockedFarmingRewards[_account];
            for (uint256 i = 0; i < lockedFarmingRewardsArray.length; i++) {
                if (lockedFarmingRewardsArray[i].lockedUntilDay <= currentDay) {
                    unlockAmount = unlockAmount.add(lockedFarmingRewardsArray[i].amount);
                } else {
                    lockedRewards.push(lockedFarmingRewardsArray[i]);
                }
            }
            totalFarmingRewardsLocked[_account] = totalFarmingRewardsLocked[_account].sub(unlockAmount);
        }
    }

    /// @notice unlock and transfer available clam rewards
    /// @return unlockAmount amount to be unlocked from clam rewards
    /// @dev returns same amount as unlockableClamRewards, but this function mutates state
    function unlockClamRewards(address _account) private returns (uint256 unlockAmount) {
        if (clamIdsStakedPerUser[_account].length() == 0 || totalClamRewardsLocked[_account] == 0) {
            unlockAmount = 0;
        } else {
            for (uint256 i = 0; i < clamIdsStakedPerUser[_account].length(); i++) {
                uint256 clamId = clamIdsStakedPerUser[_account].at(i);
                LockedNftBonus storage bonusInfo = lockedClamRewards[_account][clamId];

                if (bonusInfo.lastRewardDay < getDay()) {
                    uint256 rewards = calculateRewards(
                        bonusInfo.lastRewardDay,
                        bonusInfo.endDay,
                        bonusInfo.bonusRemaining
                    );
                    unlockAmount = unlockAmount.add(rewards);

                    if (bonusInfo.bonusRemaining <= rewards) {
                        delete lockedClamRewards[_account][clamId];
                        clamIdsStakedPerUser[_account].remove(clamId);
                    } else {
                        bonusInfo.bonusRemaining = bonusInfo.bonusRemaining.sub(rewards);
                    }

                    bonusInfo.lastRewardDay = getDay();
                }
            }

            totalClamRewardsLocked[_account] = totalClamRewardsLocked[_account].sub(unlockAmount);
        }
    }

    /// @notice unlock and transfer available pearl rewards
    /// @return unlockAmount amount to be unlocked from pearl rewards
    /// @dev returns same amount as unlockablePearlRewards, but this function mutates state
    function unlockPearlRewards(address _account) private returns (uint256 unlockAmount) {
        if (pearlIdsBurnedPerUser[_account].length() == 0 || totalPearlRewardsLocked[_account] == 0) {
            unlockAmount = 0;
        } else {
            for (uint256 i = 0; i < pearlIdsBurnedPerUser[_account].length(); i++) {
                uint256 pearlId = pearlIdsBurnedPerUser[_account].at(i);
                LockedNftBonus storage bonusInfo = lockedPearlRewards[_account][pearlId];

                if (bonusInfo.lastRewardDay < getDay()) {
                    uint256 rewards = calculateRewards(
                        bonusInfo.lastRewardDay,
                        bonusInfo.endDay,
                        bonusInfo.bonusRemainingCorrected
                    );
                    unlockAmount = unlockAmount.add(rewards);

                    if (bonusInfo.bonusRemainingCorrected <= rewards) {
                        delete lockedPearlRewards[_account][pearlId];
                        pearlIdsBurnedPerUser[_account].remove(pearlId);
                    } else {
                        bonusInfo.bonusRemainingCorrected = bonusInfo.bonusRemainingCorrected.sub(rewards);
                    }

                    bonusInfo.lastRewardDay = getDay();
                }
            }
        }
    }

    /// @notice unlock the unlockable rewards
    /// @param _account address
    /// @dev calls unlock functions (mutative) separately, gets the amount and transfers
    function unlockRewards(address _account) external override nonReentrant {
        uint256 farmingUnlock = unlockFarmingRewards(_account);
        uint256 clamUnlock = unlockClamRewards(_account);
        uint256 pearlUnlock = unlockPearlRewards(_account);
        uint256 unlockAmount = farmingUnlock.add(clamUnlock).add(pearlUnlock);

        totalLocked = totalLocked.sub(unlockAmount);
        gem.safeTransfer(_account, unlockAmount);
        emit GemUnlocked(_account, unlockAmount);
    }

    /// @notice register deposited stake
    /// @param _account address
    /// @param _deposited amount deposited
    function depositStake(address _account, uint256 _deposited) external override {
        StakeData storage userStakeInfo = stakeData[_account][getDay()];

        if (userStakeInfo.withdrawn > 0) {
            userStakeInfo.deposited = userStakeInfo.deposited.add(_deposited);

            updatePearlRewards(_account);
        }

        emit DepositStake(_account, _deposited);
    }

    /// @notice register withdrawn stake
    /// @param _account address
    /// @param _totalBalance total stake in farm, used to calculate percentage withdrawn
    /// @param _withdrawn amount withdrawn
    function withdrawStake(
        address _account,
        uint256 _totalBalance,
        uint256 _withdrawn
    ) external override {
        StakeData storage userStakeInfo = stakeData[_account][getDay()];

        if (userStakeInfo.totalBalance == 0) {
            stakeData[_account][getDay()] = StakeData({
                totalBalance: _totalBalance,
                withdrawn: _withdrawn,
                deposited: 0
            });
        } else {
            userStakeInfo.withdrawn = userStakeInfo.withdrawn.add(_withdrawn);
        }

        if (userStakeInfo.withdrawn > 0) updatePearlRewards(_account);

        emit WithdrawStake(_account, _withdrawn);
    }

    function updatePearlRewards(address _account) private {
        StakeData memory userStakeInfo = stakeData[_account][getDay()];
        if (userStakeInfo.withdrawn > 0) {
            uint256 newTotal;
            for (uint256 i = 0; i < pearlIdsBurnedPerUser[_account].length(); i++) {
                uint256 pearlId = pearlIdsBurnedPerUser[_account].at(i);
                LockedNftBonus storage bonusInfo = lockedPearlRewards[_account][pearlId];
                uint256 stakeDiff = userStakeInfo.withdrawn.sub(userStakeInfo.deposited);
                if (stakeDiff > 0) {
                    uint256 percentageCutBP = stakeDiff.mul(bps).div(userStakeInfo.totalBalance);
                    bonusInfo.bonusRemainingCorrected = bonusInfo.bonusRemaining.mul(percentageCutBP).div(bps);
                } else {
                    bonusInfo.bonusRemainingCorrected = bonusInfo.bonusRemaining;
                }
                newTotal = newTotal.add(bonusInfo.bonusRemainingCorrected);
            }
            totalPearlRewardsLocked[_account] = newTotal;
        }
    }

    /// @notice unlock tokens (even if not unlockable yet) to buy clams, only callable by ClamShop
    /// @param _account address of user
    /// @param _amount amount needed to be unlocked
    function forceUnlock(address _account, uint256 _amount) external override {
        require(hasRole(UPDATER_ROLE, msg.sender), "GemLocker: must have updater role");
        uint256 transferAmount = _amount;
        // if _amount is bigger than total locked, delete all user reward data, as everything is going to be transferred out
        if (_amount >= totalLockedRewards(_account)) {
            transferAmount = totalLockedRewards(_account);
            delete lockedFarmingRewards[_account];
            delete totalFarmingRewardsLocked[_account];
            delete totalClamRewardsLocked[_account];
            delete totalPearlRewardsLocked[_account];
        } else {
            // reduce vested tokens with amount, from farming first, then clam, then pearl
            // oldest locked rewards are reduced first
            // conditions are in place to make sure that values are only read and looped through if needed

            uint256 amountRemaining = _amount;

            if (totalFarmingRewardsLocked[_account] <= amountRemaining) {
                amountRemaining = amountRemaining.sub(totalFarmingRewardsLocked[_account]);
                delete totalFarmingRewardsLocked[_account];
                delete lockedFarmingRewards[_account];
            } else {
                LockedFarmingRewards[] memory farmingLocked = lockedFarmingRewards[_account];
                delete lockedFarmingRewards[_account];
                for (uint256 i = 0; i < farmingLocked.length; i++) {
                    if (farmingLocked[i].amount <= amountRemaining) {
                        amountRemaining = amountRemaining.sub(farmingLocked[i].amount);
                        totalFarmingRewardsLocked[_account] = totalFarmingRewardsLocked[_account].sub(
                            farmingLocked[i].amount
                        );
                    } else {
                        lockedFarmingRewards[_account].push(
                            LockedFarmingRewards({
                                lockedUntilDay: farmingLocked[i].lockedUntilDay,
                                amount: farmingLocked[i].amount.sub(amountRemaining)
                            })
                        );
                        totalFarmingRewardsLocked[_account] = totalFarmingRewardsLocked[_account].sub(amountRemaining);
                        amountRemaining = 0;
                    }
                }
            }

            if (amountRemaining > 0) {
                if (totalClamRewardsLocked[_account] <= amountRemaining) {
                    amountRemaining = amountRemaining.sub(totalClamRewardsLocked[_account]);
                    delete totalClamRewardsLocked[_account];
                    for (uint256 i = 0; i < clamIdsStakedPerUser[_account].length(); i++) {
                        uint256 clamId = clamIdsStakedPerUser[_account].at(i);
                        LockedNftBonus storage bonusInfo = lockedClamRewards[_account][clamId];
                        bonusInfo.bonusRemaining = 0;
                    }
                } else {
                    for (uint256 i = 0; i < clamIdsStakedPerUser[_account].length(); i++) {
                        uint256 clamId = clamIdsStakedPerUser[_account].at(i);
                        LockedNftBonus storage bonusInfo = lockedClamRewards[_account][clamId];
                        if (bonusInfo.bonusRemaining <= amountRemaining) {
                            amountRemaining = amountRemaining.sub(bonusInfo.bonusRemaining);
                            bonusInfo.bonusRemaining = 0;
                            totalClamRewardsLocked[_account] = totalClamRewardsLocked[_account].sub(
                                bonusInfo.bonusRemaining
                            );
                        } else {
                            bonusInfo.bonusRemaining = bonusInfo.bonusRemaining.sub(amountRemaining);
                            totalClamRewardsLocked[_account] = totalClamRewardsLocked[_account].sub(amountRemaining);
                            amountRemaining = 0;
                        }
                    }
                }
            }

            if (amountRemaining > 0) {
                if (totalPearlRewardsLocked[_account] <= amountRemaining) {
                    amountRemaining = amountRemaining.sub(totalPearlRewardsLocked[_account]);
                    delete totalPearlRewardsLocked[_account];
                    for (uint256 i = 0; i < clamIdsStakedPerUser[_account].length(); i++) {
                        uint256 pearlId = pearlIdsBurnedPerUser[_account].at(i);
                        LockedNftBonus storage bonusInfo = lockedPearlRewards[_account][pearlId];
                        bonusInfo.bonusRemaining = 0;
                        bonusInfo.bonusRemainingCorrected = 0;
                    }
                } else {
                    for (uint256 i = 0; i < clamIdsStakedPerUser[_account].length(); i++) {
                        uint256 pearlId = pearlIdsBurnedPerUser[_account].at(i);
                        LockedNftBonus storage bonusInfo = lockedPearlRewards[_account][pearlId];
                        if (bonusInfo.bonusRemainingCorrected <= amountRemaining) {
                            amountRemaining = amountRemaining.sub(bonusInfo.bonusRemainingCorrected);
                            bonusInfo.bonusRemaining = 0;
                            bonusInfo.bonusRemainingCorrected = 0;
                            totalPearlRewardsLocked[_account] = totalPearlRewardsLocked[_account].sub(
                                bonusInfo.bonusRemainingCorrected
                            );
                        } else {
                            bonusInfo.bonusRemaining = bonusInfo.bonusRemaining.sub(amountRemaining);
                            bonusInfo.bonusRemainingCorrected = bonusInfo.bonusRemainingCorrected.sub(amountRemaining);
                            totalPearlRewardsLocked[_account] = totalPearlRewardsLocked[_account].sub(amountRemaining);
                            amountRemaining = 0;
                        }
                    }
                }
            }
        }

        totalLocked = totalLocked.sub(transferAmount);
        gem.safeTransfer(msg.sender, transferAmount);
        emit ForceUnlocked(msg.sender, transferAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/EnumerableSetUpgradeable.sol";
import "../utils/AddressUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using AddressUpgradeable for address;

    struct RoleData {
        EnumerableSetUpgradeable.AddressSet members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view returns (address) {
        return _roles[role].members.at(index);
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual {
        require(hasRole(_roles[role].adminRole, _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, _roles[role].adminRole, adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

interface IGemLocker {
    /* View funcitons */
    function getDay() external view returns (uint256);

    function lockedFarmingRewardsLength(address _account) external view returns (uint256);

    function clamsStakedPerUserLength(address user) external view returns (uint256);

    function clamIdsStakedPerUserAt(address _account, uint256 _index) external view returns (uint256);

    function pearlsBurnedPerUserLength(address _account) external view returns (uint256);

    function pearlIdsBurnedPerUserAt(address _account, uint256 _index) external view returns (uint256);

    function totalLockedRewards(address _account) external view returns (uint256);

    function pendingFarmingRewards(address _account) external view returns (uint256);

    function pendingClamRewards(address _account) external view returns (uint256);

    function pendingPearlRewards(address _account) external view returns (uint256);

    function canUnlockAmount(address _account) external view returns (uint256);

    /* Mutative funcitons */
    function lockFarmingRewards(address _account, uint256 _amount) external;

    function lockClamRewards(
        address _account,
        uint256 _amount,
        uint256 _clamId
    ) external;

    function lockPearlRewards(
        address _account,
        uint256 _amount,
        uint256 _pearlId
    ) external;

    function unlockRewards(address _account) external;

    function depositStake(address _account, uint256 _deposited) external;

    function withdrawStake(
        address _account,
        uint256 _totalBalance,
        uint256 _withdrawn
    ) external;

    function forceUnlock(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     */
    function mint(address beneficiary, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address, uint256) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IBEP20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IBEP20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IBEP20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IBEP20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeBEP20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeBEP20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeBEP20: BEP20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

