// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./libs/IBEP20.sol";
import "./libs/SafeBEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Cartographer.sol";
import "./ElevationHelper.sol";
import "./ICakeMasterChef.sol";
import "./SummitToken.sol";
import "./CartographerExpedition.sol";
import "hardhat/console.sol";

contract CartographerExpedition is Ownable, Initializable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    struct UserInfo {
        uint256 prevInteractedRound;                // Round the user last made a deposit / withdrawal / harvest
        uint256 staked;                             // The amount of token the user has in the pool
        uint256 roundDebt;                          // Used to calculate user's first interacted round reward
        uint256 roundRew;                           // Running sum of user's rewards earned in current round
    }
    
    struct RoundInfo {
        uint256 endAccRewPerShare;                  // The accRewPerShare at the end of the round, used for back calculations
        uint256 winningsMultiplier;                 // Rewards multiplier: TOTAL POOL STAKED / WINNING TOTEM STAKED
        uint256 precomputedFullRoundMult;           // Change in accRewPerShare over round multiplied by winnings multiplier
    }

    struct ExpeditionPoolInfo {
        uint8 pid;                                  // Running index, source of truth for pool
        bool enabled;                               // Whether the pool is active for deposit / rewards
        IBEP20 rewardToken;                         // Address of Reward token to be distributed.
        uint256 totalRoundsCount;                   // Number of rounds of this expedition to run.
        uint256 totalRewardAmount;                  // Total amount of reward token to be distributed over 7 days.
        uint256 rewardEmission;                     // How much reward is released per block
        uint256 summitSupply;                       // Could be overlapping LP pools, this allows that
        uint256 lastRewardBlock;                    // Last block number that reward distribution occurs.
        uint256 accRewPerShare;                     // Accumulated Reward Tokens per share, times 1e12. See below.

        uint256[] totemSummitSupplies;              // Running total of LP in each totem to calculate rewards
        uint256 roundRewards;                       // Rewards of entire pool accum over round
        uint256[] totemRoundRewards;                // Rewards of each totem accum over round
        uint256 startBlock;                         // When rewards begin emitting
        uint256 startRound;                         // The first round of the pool
    }

    // The SUMMIT TOKEN!
    SummitToken public summit;
    Cartographer cartographer;
    ElevationHelper elevationHelper;
    uint8 constant EXPEDITION = 4;

    // Info of each pool.
    uint8[] public expeditionPIDs;
    mapping(uint8 => bool) public pidExistence;
    mapping(uint8 => ExpeditionPoolInfo) public expeditionPoolInfo;
    mapping(uint8 => mapping(address => UserInfo)) public userInfo;
    mapping(address => uint8) public userTotem;
    mapping(uint8 => mapping(uint256 => RoundInfo)) public poolRoundInfo;
    
    event ExpeditionExtended(uint256 indexed pid, address rewardToken, uint256 _rewardAmount, uint256 _rounds);
    event ExpeditionRestarted(uint256 indexed pid, address rewardToken, uint256 _rewardAmount, uint256 _rounds);
    
    constructor(address _Cartographer) public onlyOwner {
        require(_Cartographer != address(0), "Cartographer required");
        cartographer = Cartographer(_Cartographer);
    }

    function initialize(address _ElevationHelper) external initializer onlyCartographer() {
        require(_ElevationHelper != address(0), "Contract is zero");
        elevationHelper = ElevationHelper(_ElevationHelper);
    }

    function expeditionsCount() public view returns (uint256) {
        return expeditionPIDs.length;
    }

    function enableSummit(SummitToken _summit) external onlyCartographer() {
        summit = _summit;
    }

    modifier onlyCartographer() {
        require(msg.sender == address(cartographer), "Only cartographer");
        _;
    }
    modifier validUserAdd(address _userAdd) {
        require(_userAdd != address(0), "User address is zero");
        _;
    }

    mapping(IBEP20 => bool) public poolExistence;
    modifier nonDuplicated(IBEP20 _rewardToken) {
        require(!poolExistence[_rewardToken], "Duplicated");
        _;
    }

    modifier poolExists(uint8 pid) {
        require(pidExistence[pid], "Pool doesnt exist");
        _;
    }
    modifier poolExistsAndEnabled(uint8 pid) {
        require(pidExistence[pid], "Pool doesnt exist");
        require(expeditionPoolInfo[pid].enabled, "Pool not available yet");
        _;
    }
    modifier validTotem(uint8 totem) {
        require(totem < elevationHelper.elevTotemCount(EXPEDITION), "Invalid totem");
        _;
    }
    modifier expeditionNotLockedUntilRollover() {
        require(!elevationHelper.getElevationLockedUntilRollover(EXPEDITION), "Elev locked until rollover");
        _;
    }
    
    // Add a new lp to the pool. Can only be called by the owner.
    function registerPool(uint8 _pid, IBEP20 _rewardToken) internal {
        poolExistence[_rewardToken] = true;
        pidExistence[_pid] = true;
        expeditionPIDs.push(_pid);
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint8 _pid, IBEP20 _rewardToken, uint256 _rewardAmount, uint256 _rounds, bool _withUpdate) external onlyCartographer() nonDuplicated(_rewardToken) {
        require(_rewardToken.balanceOf(address(this)) >= _rewardAmount, "Must have funds to cover expedition");
        if (_withUpdate) {
            cartographer.massUpdatePools();
        }
        uint256 roundDuration = elevationHelper.elevDurationSeconds(EXPEDITION);
        
        registerPool(_pid, _rewardToken);

        uint256 rewardEmission = _rewardAmount.div(roundDuration.mul(_rounds).div(3));
        uint8 totemCount = elevationHelper.elevTotemCount(EXPEDITION);

        expeditionPoolInfo[_pid] = ExpeditionPoolInfo({
            pid: _pid,
            enabled: false,
            rewardToken: _rewardToken,
            totalRoundsCount: _rounds,
            totalRewardAmount: _rewardAmount,
            rewardEmission: rewardEmission,
            summitSupply: 0,
            lastRewardBlock: block.number,
            accRewPerShare: 0,

            totemSummitSupplies: new uint256[](totemCount),
            roundRewards: 0,
            totemRoundRewards: new uint256[](totemCount),
            startBlock: 0,
            startRound: elevationHelper.getElevationStartRound(EXPEDITION)
        });
    }

    function extendExpeditionPool(uint8 _pid, uint256 _additionalRewardAmount, uint256 _additionalRounds, bool _withUpdate) public onlyOwner poolExistsAndEnabled(_pid) {
        ExpeditionPoolInfo storage pool = expeditionPoolInfo[_pid];
        uint256 blocksCompleted = block.number.sub(pool.startBlock);
        uint256 rewardRemaining = pool.totalRewardAmount.sub(blocksCompleted.mul(pool.rewardEmission));
        uint256 rewardsRemainingWithAdditional = rewardRemaining.add(_additionalRewardAmount);
        require(pool.rewardToken.balanceOf(address(this)) > rewardsRemainingWithAdditional, "Must have funds to cover expedition");
        
        if (_withUpdate) {
            cartographer.massUpdatePools();
        }

        uint256 roundDuration = elevationHelper.elevDurationSeconds(EXPEDITION);
        uint256 blocksRemainingWithAdditional = pool.totalRoundsCount.add(_additionalRounds).mul(roundDuration).div(3).sub(blocksCompleted);
        uint256 newRewardEmission = rewardsRemainingWithAdditional.div(blocksRemainingWithAdditional);

        pool.totalRewardAmount = pool.totalRewardAmount.add(_additionalRewardAmount);
        pool.totalRoundsCount = pool.totalRoundsCount.add(_additionalRounds);
        pool.rewardEmission = newRewardEmission;

        emit ExpeditionExtended(_pid, address(pool.rewardToken), pool.totalRewardAmount, pool.totalRoundsCount);
    }

    function restartExpeditionPool(uint8 _pid, uint256 _rewardAmount, uint256 _rounds, bool _withUpdate) public onlyOwner poolExists(_pid) {
        ExpeditionPoolInfo storage pool = expeditionPoolInfo[_pid];
        require(pool.rewardToken.balanceOf(address(this)) >= _rewardAmount, "Must have funds to cover expedition");
        require (!pool.enabled, "Expedition already running");
        
        if (_withUpdate) {
            cartographer.massUpdatePools();
        }

        uint256 roundDuration = elevationHelper.elevDurationSeconds(EXPEDITION);
        uint256 rewardEmission = _rewardAmount.div(roundDuration.mul(_rounds).div(3));

        pool.enabled = false;
        pool.totalRoundsCount = _rounds;
        pool.totalRewardAmount = _rewardAmount;
        pool.rewardEmission = rewardEmission;
        pool.lastRewardBlock = block.number;
        pool.accRewPerShare = 0;
        pool.startBlock = 0;
        pool.startRound = elevationHelper.getElevationStartRound(EXPEDITION);

        emit ExpeditionRestarted(_pid, address(pool.rewardToken), pool.totalRewardAmount, pool.totalRoundsCount);
    }

    ////////////////////////////////
    //       R O L L O V E R      //
    ////////////////////////////////
    
    function rolloverExpedition() external onlyCartographer() {
        uint256 currRound = elevationHelper.elevationRound(EXPEDITION);
        uint256 nextRound = currRound + 1;
        for (uint8 i = 0; i < expeditionPIDs.length; i++) {
            uint8 expeditionPID = expeditionPIDs[i];
            if (expeditionPoolInfo[expeditionPID].enabled) {
                endRoundAndStartNext(expeditionPID, currRound, nextRound);

            } else {
                startFirstRoundIfAvailable(expeditionPID, nextRound);
            }
        }
    }
    
    function endRoundAndStartNext(uint8 _pid, uint256 currRound, uint256 nextRound) internal poolExistsAndEnabled(_pid) {
        ExpeditionPoolInfo storage pool = expeditionPoolInfo[_pid];
        if (currRound == 0 || pool.startRound == nextRound) { return; } // Exit on pool starting round rollover
        updatePool(_pid);
        
        uint256 accRewPerShare = pool.accRewPerShare;
        uint256 deltaAccRewPerShare = accRewPerShare.sub(poolRoundInfo[_pid][currRound - 1].endAccRewPerShare);
        uint256 winningTotemRoundRewards = pool.totemRoundRewards[elevationHelper.roundWinningTotem(EXPEDITION, currRound)];
        uint256 winningsMultiplier = winningTotemRoundRewards == 0 ? 0 : pool.roundRewards.mul(1e12).div(winningTotemRoundRewards);
        poolRoundInfo[_pid][currRound] = RoundInfo({
            endAccRewPerShare: accRewPerShare,
            winningsMultiplier: winningsMultiplier,
            precomputedFullRoundMult: deltaAccRewPerShare.mul(winningsMultiplier).div(1e12)
        });

        if (nextRound >= pool.startRound + pool.totalRoundsCount) {
            pool.enabled = false;
        }
        
        pool.roundRewards = 0;
        pool.totemRoundRewards = new uint256[](elevationHelper.elevTotemCount(EXPEDITION));
    }

    function startFirstRoundIfAvailable(uint8 _pid, uint256 nextRound) internal poolExists(_pid) {
        ExpeditionPoolInfo storage pool = expeditionPoolInfo[_pid];
        if (nextRound < pool.startRound) { return; }
        expeditionPoolInfo[_pid].enabled = true;
        expeditionPoolInfo[_pid].startBlock = block.number;
    }

    ////////////////////////////////
    //        P E N D I N G       //
    ////////////////////////////////

    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    function getRoundTotemDivider(uint8 _pid) public view poolExists(_pid) returns (uint8) {
        return elevationHelper.getCurrentExpeditionRoundTotemDivider();
    }

    function getPendingReward(uint8 _pid, address _userAdd) external view onlyCartographer() poolExists(_pid) validUserAdd(_userAdd) returns (uint256) {
        ExpeditionPoolInfo storage pool = expeditionPoolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_userAdd];
        return getExpeditionPendingRewards(pool, user, _userAdd);
    }

    function getCurrentAccRewPerShare(ExpeditionPoolInfo memory pool) internal view returns (uint256, uint256) {
        if (block.number > pool.lastRewardBlock && pool.summitSupply > 0) {
            uint256 expeditionReward = getMultiplier(pool.lastRewardBlock, block.number).mul(pool.rewardEmission);
            return (pool.accRewPerShare.add(expeditionReward.mul(1e12).div(pool.summitSupply)), expeditionReward);
        }
        return (pool.accRewPerShare, 0);
    }

    function getUserHypotheticalReward(ExpeditionPoolInfo memory pool, UserInfo storage user, uint256 accRewPerShare) internal view returns (uint256) {
        uint256 currRound = elevationHelper.elevationRound(EXPEDITION);
        return user.prevInteractedRound == currRound ?
            user.staked.mul(accRewPerShare).div(1e12).sub(user.roundDebt).add(user.roundRew) :  // Change in accRewPerShare since debt point above
            user.staked.mul(accRewPerShare.sub(poolRoundInfo[pool.pid][currRound - 1].endAccRewPerShare)).div(1e12);
    }
    
    function getHypotheticalReward(uint8 _pid, address _userAdd) external view poolExists(_pid) validUserAdd(_userAdd) returns (uint256, uint256) {
        ExpeditionPoolInfo memory pool = expeditionPoolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_userAdd];
        
        (uint256 accRewPerShare, uint256 expeditionReward) = getCurrentAccRewPerShare(pool);
        (uint256 liveRoundRewards, uint256 liveTotemRoundRewards) = getLiveSummitRewards(_pid, userTotem[_userAdd], expeditionReward);
        uint256 rew = getUserHypotheticalReward(pool, user, accRewPerShare);    
        if (rew == 0 || liveTotemRoundRewards == 0) { return (0, 0); }
        return (
            // CURRENT: How much the user has farmed currently
            rew,
            // IF WIN: User rewards * (total round rewards / totem rewards)
            liveTotemRoundRewards > 0 ? rew.mul(liveRoundRewards).div(liveTotemRoundRewards) : rew
        );
    }

    function getUserFirstInteractedRoundReward(RoundInfo memory round, UserInfo storage user) internal view returns (uint256) {
        return user.staked
            .mul(round.endAccRewPerShare).div(1e12).sub(user.roundDebt)
            .add(user.roundRew)
            .mul(round.winningsMultiplier).div(1e12);
    }

    function getRoundWinnings(ExpeditionPoolInfo storage pool, UserInfo storage user, uint256 roundIndex, address userAdd) internal view returns (uint256) {
        if (userTotem[userAdd] != elevationHelper.roundWinningTotem(EXPEDITION, roundIndex)) { return 0; }
        
        RoundInfo memory round = poolRoundInfo[pool.pid][roundIndex];

        return user.prevInteractedRound == roundIndex ?
            getUserFirstInteractedRoundReward(round, user) :
            user.staked.mul(round.precomputedFullRoundMult).div(1e12);
    } 
    
    function getExpeditionPendingRewards(ExpeditionPoolInfo storage pool, UserInfo storage user, address userAdd) internal view poolExists(pool.pid) returns (uint256) {
        uint256 currRound = elevationHelper.elevationRound(EXPEDITION);
        if (currRound <= pool.startRound) { return 0; }

        if (user.prevInteractedRound == currRound) { return 0; }
        
        uint256 avail = 0;
        for (uint256 roundIndex = user.prevInteractedRound; roundIndex < currRound; roundIndex++) {
            avail += getRoundWinnings(
                pool,
                user,
                roundIndex,
                userAdd
            );
        }

        return avail;
    }

    function massUpdatePools() external onlyCartographer() {
        for (uint8 i = 0; i < expeditionPIDs.length; i++) {
            updatePool(expeditionPIDs[i]);
        }
    }

    function updatePool(uint8 _pid) public {
        ExpeditionPoolInfo storage pool = expeditionPoolInfo[_pid];
        if (pool.lastRewardBlock == block.number) { return; }
        if (!pool.enabled || pool.summitSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 expeditionReward = multiplier.mul(pool.rewardEmission);
        pool.accRewPerShare = pool.accRewPerShare.add(expeditionReward.mul(1e12).div(pool.summitSupply));
        
        pool.roundRewards = pool.roundRewards.add(expeditionReward);
        for (uint8 i = 0; i < pool.totemRoundRewards.length; i++) {
            pool.totemRoundRewards[i] = pool.totemRoundRewards[i].add(expeditionReward.mul(pool.totemSummitSupplies[i]).div(pool.summitSupply));
        }        
        pool.lastRewardBlock = block.number;
    }

    function harvestPending(ExpeditionPoolInfo storage pool, UserInfo storage user, address _userAdd) internal {
        uint256 pending = getExpeditionPendingRewards(pool, user, _userAdd);
        pool.rewardToken.safeTransfer(_userAdd, pending);
    }

    function updateUserRoundInteraction(ExpeditionPoolInfo storage pool, UserInfo storage user, uint256 amount, bool isDeposit) internal {
        uint256 currRound = elevationHelper.elevationRound(EXPEDITION);

        if (user.prevInteractedRound == currRound) {
            // If user already interacted this round, updating the users current mid round reward
            user.roundRew = user.roundRew.add(user.staked.mul(pool.accRewPerShare).div(1e12).sub(user.roundDebt));
        } else {
            // User interacted in some previous round, create new mid round reward based on that previous round's stats
            uint256 roundStartAccRewPerShare = poolRoundInfo[pool.pid][currRound - 1].endAccRewPerShare;
            user.roundRew = user.staked.mul(pool.accRewPerShare.sub(roundStartAccRewPerShare)).div(1e12);
        }
        
        if (isDeposit) { user.staked += amount; }
        else { user.staked -= amount; } // Already validated in require of withdraw functions

        user.roundDebt = user.staked.mul(pool.accRewPerShare).div(1e12);
        user.prevInteractedRound = currRound;
        return;
    }


    ///////////////////////////////////
    //    I N T E R A C T I O N S    //
    ///////////////////////////////////

    function getLpSupply(uint8 _pid) external view poolExists(_pid) returns (uint256) {
        return expeditionPoolInfo[_pid].summitSupply;
    }

    function switchAllTotems(uint8 _newTotem, address _userAdd) external nonReentrant onlyCartographer() validTotem(_newTotem) validUserAdd(_userAdd) expeditionNotLockedUntilRollover() {
        // Harvest rewards and switch all totems
        for (uint8 i = 0; i < expeditionPIDs.length; i++) {
            uint8 expeditionPid = expeditionPIDs[i];
            if (expeditionPoolInfo[expeditionPid].enabled && userInfo[expeditionPid][_userAdd].staked > 0) {
                switchTotem(expeditionPid, _newTotem, _userAdd);
            }
        }
        userTotem[_userAdd] = _newTotem;
    }
    function internalIsTotemInUse(address _userAdd) internal view returns (bool) {
        for (uint8 i = 0; i < expeditionPIDs.length; i++) {
            if (expeditionPoolInfo[expeditionPIDs[i]].enabled && userInfo[expeditionPIDs[i]][_userAdd].staked > 0) {
                return true;
            }
        }
        return false;
    }
    function getIsTotemInUse(address _userAdd) external view returns (bool) {
        return internalIsTotemInUse(_userAdd);
    }

    function switchTotem(uint8 _pid, uint8 _newTotem, address _userAdd) internal {
        UserInfo storage user = userInfo[_pid][_userAdd];
        if (user.staked == 0) { return; }

        ExpeditionPoolInfo storage pool = expeditionPoolInfo[_pid];

        harvestPending(pool, user, _userAdd);
        
        updateUserRoundInteraction(pool, user, 0, true);
        
        pool.totemSummitSupplies[userTotem[_userAdd]] -= user.staked;
        pool.totemSummitSupplies[_newTotem] += user.staked;
        pool.totemRoundRewards[userTotem[_userAdd]] -= user.roundRew;
        pool.totemRoundRewards[_newTotem] += user.roundRew;
        
        user.prevInteractedRound = elevationHelper.elevationRound(EXPEDITION);
    }


    // Deposit SUMMIT tokens in Expedition pool to earn rewardToken
    function deposit(uint8 _pid, uint256 _amount, uint8 _totem, address _userAdd) external nonReentrant onlyCartographer() poolExistsAndEnabled(_pid) validTotem(_totem) validUserAdd(_userAdd) expeditionNotLockedUntilRollover() returns (uint256) {
        UserInfo storage user = userInfo[_pid][_userAdd];
        require(!internalIsTotemInUse(_userAdd) || userTotem[_userAdd] == _totem, "Cant switch totem during deposit");
        ExpeditionPoolInfo storage pool = expeditionPoolInfo[_pid];
        updatePool(_pid);
        
        if (user.staked > 0) {
            harvestPending(pool, user, _userAdd);
        }
        
        if (_amount > 0) {
            summit.transferFrom(address(_userAdd), address(this), _amount);
            pool.totemSummitSupplies[_totem] += _amount;
            pool.summitSupply += _amount;
        }
        
        // Create or update currentRound's roundInteraction
        updateUserRoundInteraction(pool, user, _amount, true);
        userTotem[_userAdd] = _totem;
        user.prevInteractedRound = elevationHelper.elevationRound(EXPEDITION);
        
        return _amount;
    }

    function withdraw(uint8 _pid, uint256 _amount, address _userAdd) external nonReentrant onlyCartographer() poolExists(_pid) validUserAdd(_userAdd) expeditionNotLockedUntilRollover() returns (uint256) {
        UserInfo storage user = userInfo[_pid][_userAdd];
        require(_amount > 0 && user.staked > 0 && user.staked >= _amount, "Bad withdrawal");
        ExpeditionPoolInfo storage pool = expeditionPoolInfo[_pid];
        updatePool(_pid);
        
        harvestPending(pool, user, _userAdd);
        updateUserRoundInteraction(pool, user, _amount, false);
        
        summit.transfer(address(_userAdd), _amount);
        uint8 totem = userTotem[_userAdd];
        pool.totemSummitSupplies[totem] = pool.totemSummitSupplies[totem].sub(_amount);
        pool.summitSupply = pool.summitSupply.sub(_amount);
        
        user.prevInteractedRound = elevationHelper.elevationRound(EXPEDITION);
        return _amount;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint8 _pid, address _userAdd) external nonReentrant onlyCartographer() poolExistsAndEnabled(_pid) validUserAdd(_userAdd) expeditionNotLockedUntilRollover() returns (uint256) {
        UserInfo storage user = userInfo[_pid][_userAdd];
        require(user.staked > 0, "Nothing to emergency withdraw");
        ExpeditionPoolInfo storage pool = expeditionPoolInfo[_pid];
        updatePool(_pid);
        uint256 amount = user.staked;
        user.prevInteractedRound = 0;
        user.staked = 0;
        user.roundRew = 0;
        
        summit.transfer(address(_userAdd), amount);
        uint8 totem = userTotem[_userAdd];
        pool.totemSummitSupplies[totem] = pool.totemSummitSupplies[totem].sub(amount);
        pool.summitSupply = pool.summitSupply.sub(amount);

        return amount;
    }

    function totemLpSupplies(uint8 _pid) public view poolExists(_pid) returns (uint256[2] memory) {        
        return [
            expeditionPoolInfo[_pid].totemSummitSupplies[0],
            expeditionPoolInfo[_pid].totemSummitSupplies[1]
        ];
    }
    function totemRoundRewards(uint8 _pid) public view poolExists(_pid) returns (uint256[3] memory) {
        ExpeditionPoolInfo storage pool = expeditionPoolInfo[_pid];
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 expeditionReward = multiplier.mul(pool.rewardEmission);
        return [
            pool.roundRewards.add(expeditionReward),
            pool.summitSupply == 0 || pool.totemSummitSupplies[0] == 0 ?
                pool.totemRoundRewards[0] :
                pool.totemRoundRewards[0]
                    .add(expeditionReward
                        .mul(1e12)
                        .mul(pool.totemSummitSupplies[0])
                        .div(pool.summitSupply)
                        .div(1e12)
                    ),
            pool.summitSupply == 0 || pool.totemSummitSupplies[1] == 0 ?
                pool.totemRoundRewards[1] :
                pool.totemRoundRewards[1]
                    .add(expeditionReward
                        .mul(1e12)
                        .mul(pool.totemSummitSupplies[1])
                        .div(pool.summitSupply)
                        .div(1e12)
                    )
        ];
    }
    function getLiveSummitRewards(uint8 _pid, uint8 _totem, uint256 _expeditionReward) internal view poolExists(_pid) returns (uint256, uint256) {
        ExpeditionPoolInfo storage pool = expeditionPoolInfo[_pid];
        return (
            pool.roundRewards.add(_expeditionReward),
            pool.summitSupply == 0 || pool.totemSummitSupplies[_totem] == 0 ?
                pool.totemRoundRewards[_totem] :
                pool.totemRoundRewards[_totem]
                    .add(_expeditionReward
                        .mul(1e12)
                        .mul(pool.totemSummitSupplies[_totem])
                        .div(pool.summitSupply)
                        .div(1e12)
                    )
        );
    }
    function remainingRewards(uint8 _pid) public view poolExists(_pid) returns (uint256) {
        ExpeditionPoolInfo storage pool = expeditionPoolInfo[_pid];
        if (pool.startBlock == 0 || pool.startBlock >= block.number) { return pool.totalRewardAmount; }
        uint256 blocksCompleted = block.number.sub(pool.startBlock);
        return pool.totalRewardAmount.sub(blocksCompleted.mul(pool.rewardEmission));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/Address.sol";

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
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./libs/IBEP20.sol";
import "./libs/SafeBEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IRandomNumberGenerator.sol";
import "./ElevationHelper.sol";
import "./ISummitReferrals.sol";
import "./ISummitKeywords.sol";
import "./ICakeMasterChef.sol";
import "./CartographerOasis.sol";
import "./CartographerElevation.sol";
import "./CartographerExpedition.sol";

import "./SummitToken.sol";
import "hardhat/console.sol";

contract Cartographer is Ownable, Initializable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    
    uint8 constant OASIS = 0;
    uint8 constant TWOTHOUSAND = 1;
    uint8 constant FIVETHOUSAND = 2;
    uint8 constant TENTHOUSAND = 3;
    uint8 constant EXPEDITION = 4;
    uint256 stakedSummitRandAccum = 0;


    // The SUMMIT TOKEN!
    SummitToken public summit;
    bool public isTrueSummit = false;
    uint256 public summitGenesisTime = 1641028149; // 2022-1-1, will be updated when summit ecosystem switched on
    uint256 public summitPerBlock = 9e17;
    uint256 public devSummitPerBlock = 8e16;
    uint256 public referralsSummitPerBlock = 2e16;
    uint256 private constant sInH = 3600;
    address public devAdd;
    address public expedAdd;
    
    ICakeMasterChef cakeChef;
    IBEP20 cakeToken;
    ElevationHelper elevationHelper;
    IRandomNumberGenerator randomGenerator;
    ISummitReferrals summitReferrals;
    ISummitKeywords summitKeywords;
    CartographerOasis cartographerOasis;
    CartographerElevation cartographerElevation;
    CartographerExpedition cartographerExpedition;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    mapping(IBEP20 => uint256) public tokenBaseAllocPoint;
    mapping(IBEP20 => uint256) public tokenSharedAllocPoint;
    mapping(IBEP20 => mapping(uint8 => uint8)) public tokenElevationPid;
    mapping(IBEP20 => mapping(uint8 => bool)) public tokenElevationLive;

    // POOL INFO
    uint8[] public poolIds;
    mapping(uint8 => uint8) public poolElevation;

    event TokenAllocCreated(address indexed token, uint256 alloc);
    event TokenAllocUpdated(address indexed token, uint256 alloc);
    event PoolCreated(uint256 indexed pid, uint8 elevation, address token);
    event PoolUpdated(uint256 indexed pid, bool live, uint256 depositFee, uint256 elevation);
    event ExpeditionCreated(uint256 indexed pid, address rewardToken, uint256 _rewardAmount, uint256 _rounds);
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event RolloverElevation(address indexed user, uint256 elevation);
    event RolloverReferral(address indexed user);
    event SwitchTotem(address indexed user, uint8 indexed elevation, uint8 totem);
    event SwitchElevation(address indexed user, uint8 indexed currentPid, uint8 indexed newPid, uint8 totem, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event RedeemRewards(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event SetExpedAdd(address indexed user, address indexed newAddress);
    event SetFeeAddressSt(address indexed user, address indexed newAddress);
    event SetDevAddress(address indexed user, address indexed newAddress);

    constructor(
        address _devAdd,
        address _expedAdd,
        address _cakeMasterChef,
        address _cakeToken
    ) public {
        devAdd = _devAdd;
        expedAdd = _expedAdd;
        cakeChef = ICakeMasterChef(_cakeMasterChef);
        cakeToken = IBEP20(_cakeToken);
        cakeToken.approve(devAdd, 1e50);
        cakeToken.approve(expedAdd, 1e50);
        poolIds.push(0);
    }
    
    function initialize(
        SummitToken fakeSummit,
        address _ElevationHelper,
        address _IRandomNumberGenerator,
        address _ISummitReferrals,
        address _ISummitKeywords,
        address _CartographerOasis,
        address _CartographerElevation,
        address _CartographerExpedition)
    external initializer onlyOwner {
        require(
            _ElevationHelper != address(0) &&
            _IRandomNumberGenerator != address(0) &&
            _ISummitReferrals != address(0) &&
            _ISummitKeywords != address(0) &&
            _CartographerOasis != address(0) &&
            _CartographerElevation != address(0) &&
            _CartographerExpedition != address(0),
            "Contract is zero"
        );
        summit = fakeSummit;
        elevationHelper = ElevationHelper(_ElevationHelper);
        randomGenerator = IRandomNumberGenerator(_IRandomNumberGenerator);
        summitReferrals = ISummitReferrals(_ISummitReferrals);
        summitKeywords = ISummitKeywords(_ISummitKeywords);

        cartographerOasis = CartographerOasis(_CartographerOasis);
        cartographerElevation = CartographerElevation(_CartographerElevation);
        cartographerExpedition = CartographerExpedition(_CartographerExpedition);
        
        cartographerElevation.initialize(address(elevationHelper));
        cartographerExpedition.initialize(address(elevationHelper));
    }

    function enableSummit(SummitToken _trueSummit) external onlyOwner {
        require(!isTrueSummit, "Already enabled");
        summit = _trueSummit;
        isTrueSummit = true;
        summitGenesisTime = block.timestamp;
        elevationHelper.enableSummit(summitGenesisTime);
        summitReferrals.enableSummit(_trueSummit);
        cartographerOasis.enableSummit(summitGenesisTime);
        cartographerExpedition.enableSummit(_trueSummit);
    }
    
    function poolsCount() external view returns (uint256) {
        return poolIds.length;
    }

    function _onlySubCartographer(address add) internal view {
        require(add == address(cartographerOasis) || add == address(cartographerElevation) || add == address(cartographerExpedition), "Only subCarts");
    }
    modifier onlySubCartographer() {
        _onlySubCartographer(msg.sender);
        _;
    }

    mapping(IBEP20 => mapping(uint8 => bool)) public poolExistence;
    modifier nonDuplicated(IBEP20 token, uint8 elevation) {
        require(poolExistence[token][elevation] == false, "Duplicated");
        _;
    }

    mapping(IBEP20 => bool) public tokenAllocExistence;
    modifier nonDuplicatedTokenAlloc(IBEP20 token) {
        require(tokenAllocExistence[token] == false, "Duplicated token alloc");
        _;
    }
    modifier tokenAllocExists(IBEP20 token) {
        require(tokenAllocExistence[token] == true, "Invalid token alloc");
        _;
    }
    
    function _poolExists(uint8 pid) internal view {
        require(pid > 0 && pid < poolIds.length, "Pool doesnt exist");

    }
    modifier poolExists(uint8 pid) {
        _poolExists(pid);
        _;
    }
    
    modifier oasisOrElevation(uint8 elevation) {
        require(elevation >= 0 && elevation <= 3, "Not oasis or elev");
        _;
    }
    modifier elevationOrExpedition(uint8 elevation) {
        require(elevation >= 1 && elevation <= 4, "Not elev or exped");
        _;
    }

    function _validElevation(uint8 pid) internal view {
        require(poolElevation[pid] >= 0 && poolElevation[pid] <= 4, "Invalid elev");
    }
    modifier validElevation(uint8 pid) {
        _validElevation(pid);
        _;
    }

    // LP TOKEN ALLOC
    function createTokenSharedAlloc(IBEP20 _lpToken, uint256 _allocPoint) public onlyOwner nonDuplicatedTokenAlloc(_lpToken) {
        tokenAllocExistence[_lpToken] = true;
        tokenBaseAllocPoint[_lpToken] = _allocPoint;
        tokenSharedAllocPoint[_lpToken] = 0;
        _lpToken.approve(address(cakeChef), 1e50);
        emit TokenAllocCreated(address(_lpToken), _allocPoint);
    }
    function setTokenSharedAlloc(IBEP20 _lpToken, uint256 _allocPoint) public onlyOwner tokenAllocExists(_lpToken) {
        uint256 newSharedAllocPoint = _allocPoint.mul(
            (tokenElevationLive[_lpToken][OASIS] ? 100 : 0) +
            (tokenElevationLive[_lpToken][TWOTHOUSAND] ? 110 : 0) +
            (tokenElevationLive[_lpToken][FIVETHOUSAND] ? 125 : 0) +
            (tokenElevationLive[_lpToken][TENTHOUSAND] ? 150 : 0)
        ).div(100);
        totalAllocPoint = totalAllocPoint.sub(tokenSharedAllocPoint[_lpToken]).add(newSharedAllocPoint);
        tokenSharedAllocPoint[_lpToken] = newSharedAllocPoint;
        tokenBaseAllocPoint[_lpToken] = _allocPoint;
        emit TokenAllocUpdated(address(_lpToken), _allocPoint);
    }
    function getIsLive(uint8 _pid) public view returns (bool) {
        return poolElevation[_pid] == OASIS ? cartographerOasis.getIsLive(_pid) : cartographerElevation.getIsLive(_pid);
    }
    function getEffectiveAllocPoint(uint8 _pid) public view returns (uint256) {
        if (!getIsLive(_pid)) { return 0; }
        return elevationHelper.getElevationModifiedAllocPoint(tokenBaseAllocPoint[getLpToken(_pid)], poolElevation[_pid]);
    }
    

    // Add a new lp to the pool. Can only be called by the owner.
    function add(IBEP20 _lpToken, bool _live, uint16 _depositFeeBP, bool _withUpdate, uint8 _elevation, uint256 _cakeChefPid) public onlyOwner tokenAllocExists(_lpToken) oasisOrElevation(_elevation) nonDuplicated(_lpToken, _elevation) {
        require(_depositFeeBP <= 400, "Invalid deposit fee");
        uint8 pid = uint8(poolIds.length);
        poolIds.push(pid);
        poolExistence[_lpToken][_elevation] = true;
        poolElevation[pid] = _elevation;
        tokenElevationPid[_lpToken][_elevation] = pid;
        if (_elevation == OASIS) {
            cartographerOasis.add(pid, _live, _lpToken, _depositFeeBP, _withUpdate, _cakeChefPid);
        } else {
            cartographerElevation.add(pid, _live, _lpToken, _depositFeeBP, _withUpdate, _elevation, _cakeChefPid);
        }

        emit PoolCreated(pid, _elevation, address(_lpToken));
    }
    function addExpedition(IBEP20 _rewardToken, uint256 _rewardAmount, uint256 _rounds, bool _withUpdate) public onlyOwner nonDuplicated(_rewardToken, EXPEDITION) {
        uint8 pid = uint8(poolIds.length);
        poolIds.push(pid);
        poolExistence[_rewardToken][EXPEDITION] = true;
        poolElevation[pid] = EXPEDITION;
        cartographerExpedition.add(pid, _rewardToken, _rewardAmount, _rounds, _withUpdate);

        emit ExpeditionCreated(pid, address(_rewardToken), _rewardAmount, _rounds);
    }

    // Update the given pool's SUMMIT allocation point and deposit fee. Can only be called by the owner.
    function set(uint8 _pid, bool _live, uint16 _depositFee, bool _withUpdate) public onlyOwner oasisOrElevation(poolElevation[_pid]) poolExists(_pid) {
        require(_depositFee <= 400, "Invalid deposit fee");
        if (poolElevation[_pid] == OASIS) {
            cartographerOasis.set(_pid, _live, _depositFee, _withUpdate);
        } else {
            cartographerElevation.set(_pid, _live, _depositFee, _withUpdate);
        }
        emit PoolUpdated(_pid, _live, _depositFee, poolElevation[_pid]);
    }
    

    function elevationRoundEndTime(uint8 _elevation) public view elevationOrExpedition(_elevation) returns(uint256) {
        return elevationHelper.elevationRoundEndTime(_elevation);
    }

    function getReferralBurnTime() public view returns(uint256) {
        return elevationHelper.referralRoundEndTime();
    }
    function getKeywordRound() public view returns(uint256) {
        return elevationHelper.getKeywordRound();
    }

    modifier correctKeyword(string memory keyword) {
        require(summitKeywords.checkKeyword(keyword, getKeywordRound()), "Bad keyword");
        _;
    }

    function rolloverElevation(uint8 _elevation, string memory _keyword) public elevationOrExpedition(_elevation) correctKeyword(_keyword) {
        elevationHelper.requireElevationRolloverAvailable(_elevation);
    
        summit.mint(address(msg.sender), 2e18);
        bytes32 randomHash = randomGenerator.getRandomNumber(_keyword, msg.sender, elevationHelper.elevationRound(_elevation), _elevation, stakedSummitRandAccum);
        elevationHelper.selectWinningTotem(_elevation, randomGenerator.hashAgainstElevationReturnUint(randomHash, _elevation));

        // For these functions, the winning totem exists for the round, but the round index hasn't rolled over
        if (_elevation == EXPEDITION) {
            cartographerExpedition.rolloverExpedition();
        } else {
            cartographerElevation.rolloverAllRoundsAtElevation(_elevation);
        }
        
        elevationHelper.rolloverElevation(_elevation);
        emit RolloverElevation(msg.sender, _elevation);
    }

    function rolloverReferral(string memory _keyword) public correctKeyword(_keyword) {
        elevationHelper.requireRolloverReferralBurnAvailable();
        summitReferrals.burnUnclaimedReferralRewardsAndRolloverRound(msg.sender);
        elevationHelper.rolloverReferralBurn();
        emit RolloverReferral(msg.sender);
    }

    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }

    function getLpSupply(uint8 pid) public view returns (uint256) {
        if (pid == 0) { return 0; }
        if (poolElevation[pid] == OASIS) {
            return cartographerOasis.getLpSupply(pid);
        } else if (poolElevation[pid] == EXPEDITION) {
            return cartographerExpedition.getLpSupply(pid);
        } else {
            return cartographerElevation.getLpSupply(pid);
        }
    }
    function getLpToken(uint8 pid) public view poolExists(pid) returns (IBEP20) {
        return poolElevation[pid] == OASIS ?
                cartographerOasis.getLpToken(pid) :
                cartographerElevation.getLpToken(pid);
    }
    function getDepositFee(uint8 pid) public view poolExists(pid) returns (uint256) {
        return poolElevation[pid] == OASIS ?
                cartographerOasis.getDepositFee(pid) :
                cartographerElevation.getDepositFee(pid);
    }
    function getTotem(uint8 elevation, address _userAdd) public view validElevation(elevation) returns (uint8) {
        if (elevation == OASIS) {
            return 0;
        } else if (elevation == EXPEDITION) {
            return cartographerExpedition.userTotem(_userAdd);
        } else {
            return cartographerElevation.userTotem(_userAdd, elevation);
        }
    }
    function getIsTotemInUse(uint8 elevation, address _userAdd) public view validElevation(elevation) returns (bool) {
        if (elevation == OASIS) {
            return false;
        } else if (elevation == EXPEDITION) {
            return cartographerExpedition.getIsTotemInUse(_userAdd);
        } else {
            return cartographerElevation.getIsTotemInUse(elevation, _userAdd);
        }
    }

    function getTokenElevationRewardMultiplier(IBEP20 _lpToken, uint8 _elevation) public view returns (uint256) {
        uint256 totalLpTokenSupply = getLpSupply(tokenElevationPid[_lpToken][OASIS]).mul(getEffectiveAllocPoint(tokenElevationPid[_lpToken][OASIS]))
            .add(getLpSupply(tokenElevationPid[_lpToken][TWOTHOUSAND]).mul(getEffectiveAllocPoint(tokenElevationPid[_lpToken][TWOTHOUSAND])))
            .add(getLpSupply(tokenElevationPid[_lpToken][FIVETHOUSAND]).mul(getEffectiveAllocPoint(tokenElevationPid[_lpToken][FIVETHOUSAND])))
            .add(getLpSupply(tokenElevationPid[_lpToken][TENTHOUSAND]).mul(getEffectiveAllocPoint(tokenElevationPid[_lpToken][TENTHOUSAND])));
        if (totalLpTokenSupply == 0) { return 0; }
        return getLpSupply(tokenElevationPid[_lpToken][_elevation])
            .mul(1e12).mul(getEffectiveAllocPoint(tokenElevationPid[_lpToken][_elevation]))
            .div(totalLpTokenSupply);
    }

    function getPendingReward(uint8 _pid, address _userAdd) public view poolExists(_pid) validElevation(_pid) returns (uint256, uint256, uint256, uint256) {
        uint8 elevation = poolElevation[_pid];
        
        if (elevation == OASIS) {
            return (cartographerOasis.getPendingSummit(_pid, _userAdd), 0, 0, 0);
        } else if (elevation == EXPEDITION) {
            return (cartographerExpedition.getPendingReward(_pid, _userAdd), 0, 0, 0);
        } else {
            return cartographerElevation.getPendingAndVestingSummit(_pid, _userAdd);
        }
    }
    
    function getHypotheticalReward(uint8 _pid, address _userAdd) public view poolExists(_pid) validElevation(_pid) returns (uint256, uint256) {
        uint8 elevation = poolElevation[_pid];
        if (elevation == OASIS) {
            return (0, 0);
        } else if (elevation == EXPEDITION) {
            return cartographerExpedition.getHypotheticalReward(_pid, _userAdd);
        } else {
            return cartographerElevation.getHypotheticalSummit(_pid, _userAdd);
        }
    }
    
    function deposit(uint8 _pid, uint256 _amount, uint8 _totem) public nonReentrant poolExists(_pid) {
        uint8 elevation = poolElevation[_pid];
        require(elevation == OASIS || _totem < elevationHelper.elevTotemCount(poolElevation[_pid]), "Invalid totem");
        stakedSummitRandAccum += _amount;
        uint256 trueDepositAmount;
        if (elevation == OASIS) {
            trueDepositAmount = cartographerOasis.deposit(_pid, _amount, msg.sender);
        } else if (elevation == EXPEDITION) {
            trueDepositAmount = cartographerExpedition.deposit(_pid, _amount, _totem, msg.sender);
        } else {
            trueDepositAmount = cartographerElevation.deposit(_pid, _amount, _totem, msg.sender);
        }
        emit Deposit(msg.sender, _pid, trueDepositAmount);
    }

    function switchTotem(uint8 _elevation, uint8 _newTotem) public nonReentrant elevationOrExpedition(_elevation) {
        require(_newTotem < elevationHelper.elevTotemCount(_elevation), "Invalid totem");
        if (_elevation == EXPEDITION) {
            cartographerExpedition.switchAllTotems(_newTotem, msg.sender);
        } else {
            cartographerElevation.switchAllTotems(_elevation, _newTotem, msg.sender);
        }
        emit SwitchTotem(msg.sender, _elevation, _newTotem);
    }

    function switchElevation(uint8 _currentPid, uint8 _newPid, uint256 _amount, uint8 _totem) public nonReentrant poolExists(_currentPid) poolExists(_newPid) {
        require(_amount > 0, "Transfer non zero amount");
        uint8 currentElev = poolElevation[_currentPid];
        uint8 newElev = poolElevation[_newPid];

        require(currentElev != newElev, "Must change elev");
        require(currentElev != EXPEDITION && newElev != EXPEDITION, "No exped elev switch");

        (address lpToken, uint256 transferAmount, uint256 cakeChefPid) = currentElev == OASIS ?
            cartographerOasis.switchElevationWithdraw(_currentPid, _amount, msg.sender) :
            cartographerElevation.switchElevationWithdraw(_currentPid, _amount, msg.sender);

        if(newElev == OASIS) {
            cartographerOasis.switchElevationValidate(_newPid, lpToken, cakeChefPid, msg.sender);
        } else {
            cartographerElevation.switchElevationValidate(_newPid, lpToken, cakeChefPid, _totem, msg.sender);
        }

        transferAmount = newElev == OASIS ?
            cartographerOasis.switchElevationDeposit(_newPid, transferAmount, msg.sender) :
            cartographerElevation.switchElevationDeposit(_newPid, transferAmount, _totem, msg.sender);

        emit SwitchElevation(msg.sender, _currentPid, _newPid, _totem, transferAmount);          
    }

    function withdraw(uint8 _pid, uint256 _amount) public nonReentrant poolExists(_pid) {
        uint8 elevation = poolElevation[_pid];
        stakedSummitRandAccum -= _amount;
        if (elevation == OASIS) {
            cartographerOasis.withdraw(_pid, _amount, msg.sender);
        } else if (elevation == EXPEDITION) {
            cartographerExpedition.withdraw(_pid, _amount, msg.sender);
        } else {
            cartographerElevation.withdraw(_pid, _amount, msg.sender);
        }
        emit Withdraw(msg.sender, _pid, _amount);
    }

    function emergencyWithdraw(uint8 _pid) public nonReentrant poolExists(_pid) {
        uint8 elevation = poolElevation[_pid];
        uint256 amount;
        if (elevation == OASIS) {
            amount = cartographerOasis.emergencyWithdraw(_pid, msg.sender);
        } else if (elevation == EXPEDITION) {
            amount = cartographerElevation.emergencyWithdraw(_pid, msg.sender);
        } else {
            amount = cartographerExpedition.emergencyWithdraw(_pid, msg.sender);
        }
        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }


    function enableTokenAtElevation(IBEP20 lpToken, uint8 elevation) external onlySubCartographer() {
        uint256 modAllocPoint = elevationHelper.getElevationModifiedAllocPoint(tokenBaseAllocPoint[lpToken], elevation);
        tokenSharedAllocPoint[lpToken] = tokenSharedAllocPoint[lpToken].add(modAllocPoint);
        totalAllocPoint = totalAllocPoint.add(modAllocPoint);
        tokenElevationLive[lpToken][elevation] = true;
    }
    function disableTokenAtElevation(IBEP20 lpToken, uint8 elevation) external onlySubCartographer() {
        uint256 modAllocPoint = elevationHelper.getElevationModifiedAllocPoint(tokenBaseAllocPoint[lpToken], elevation);
        tokenSharedAllocPoint[lpToken] = tokenSharedAllocPoint[lpToken].sub(modAllocPoint);
        totalAllocPoint = totalAllocPoint.sub(modAllocPoint);
        tokenElevationLive[lpToken][elevation] = false;
    }

    // FUNDS FUNCTIONS
    function transferPassthroughRewards() internal {
        uint256 rewardAmount = cakeToken.balanceOf(address(this));
        cakeToken.safeTransfer(devAdd, rewardAmount.mul(8).div(100));
        cakeToken.safeTransfer(expedAdd, rewardAmount.mul(92).div(100));
    }
    function takeDepositFee(IBEP20 lpToken, uint256 depositFeeBP, uint256 amount) internal returns (uint256) {
        if (depositFeeBP > 0) {
            uint256 depositFee = amount.mul(depositFeeBP).div(10000);
            uint256 depositFeeHalf = depositFee.div(2);
            lpToken.safeTransfer(expedAdd, depositFeeHalf);
            lpToken.safeTransfer(devAdd, depositFeeHalf);
            return amount.sub(depositFee);
        } 
        return amount;
    }

    function depositTokenManagement(address userAdd, IBEP20 lpToken, uint256 depositFeeBP, uint256 amount, uint256 cakeChefPid) external onlySubCartographer() returns (uint256) {
        lpToken.safeTransferFrom(userAdd, address(this), amount);
        uint256 amountAfterFee = takeDepositFee(lpToken, depositFeeBP, amount);
        if (cakeChefPid != 0) {
            cakeChef.deposit(cakeChefPid, amountAfterFee);
            transferPassthroughRewards();
        }
        return amountAfterFee;
    }
    function withdrawalTokenManagement(address userAdd, IBEP20 lpToken, uint256 amount, uint256 cakeChefPid) external onlySubCartographer() {
        if (cakeChefPid != 0) {
            cakeChef.withdraw(cakeChefPid, amount);
            transferPassthroughRewards();
        }
        lpToken.safeTransfer(userAdd, amount);
    }
    function setPassthroughTokenManagement(uint256 cakeChefPid, IBEP20 lpToken, uint256 initialAmount) external onlySubCartographer() {
        lpToken.approve(address(cakeChef), 1e50);
        if (initialAmount == 0) { return; }
        cakeChef.deposit(cakeChefPid, initialAmount);
    }
    function disablePassthroughTokenManagement(uint256 amount, uint256 cakeChefPid) external onlySubCartographer() {
        cakeChef.withdraw(cakeChefPid, amount);
        transferPassthroughRewards();
    }

    function getFullRewardMultiplier(uint256 lastRewardBlock, IBEP20 lpToken, uint8 elevation) internal view returns (uint256) {
        if (totalAllocPoint == 0) { return 0; }
        return getMultiplier(lastRewardBlock, block.number).mul(1e12)
            .mul(tokenSharedAllocPoint[lpToken]).div(totalAllocPoint)
            .mul(getTokenElevationRewardMultiplier(lpToken, elevation)).div(1e12);
    }

    function getSummitReward(uint256 lastRewardBlock, IBEP20 lpToken, uint8 elevation) external view onlySubCartographer() returns (uint256) {
        if (lastRewardBlock == block.number) { return 0; }
        return getFullRewardMultiplier(lastRewardBlock, lpToken, elevation)
            .mul(summitPerBlock).div(1e12);
    }

    function updatePoolMint(uint256 lastRewardBlock, IBEP20 _lpToken, uint8 _elevation) external onlySubCartographer() returns (uint256) {
        uint256 rewMultiplier = getFullRewardMultiplier(lastRewardBlock, _lpToken, _elevation);
        summit.mint(devAdd, rewMultiplier.mul(devSummitPerBlock).div(1e12));
        summit.mint(address(summitReferrals), rewMultiplier.mul(referralsSummitPerBlock).div(1e12));
        summit.mint(address(this), rewMultiplier.mul(summitPerBlock).div(1e12));
        return rewMultiplier.mul(summitPerBlock).div(1e12);
    }

    function redeemRewards(address userAdd, uint256 amount) external onlySubCartographer() {
        safeSummitTransfer(userAdd, amount);
        summitReferrals.addReferralRewardsIfNecessary(userAdd, amount);
        emit RedeemRewards(userAdd, amount);
    }

    function massUpdatePools() public {
        cartographerOasis.massUpdatePools();
        cartographerElevation.massUpdatePools();
        cartographerExpedition.massUpdatePools();
    }

    // UTILS / SETTERS
    function safeSummitTransfer(address _to, uint256 _amount) internal {
        uint256 summitBal = summit.balanceOf(address(this));
        bool transferSuccess = false;
        if (_amount > summitBal) {
            transferSuccess = summit.transfer(_to, summitBal);
        } else {
            transferSuccess = summit.transfer(_to, _amount);
        }
        require(transferSuccess, "SafeSummitTransfer: failed");
    }

    function setDevAdd(address _devAdd) public {
        require(msg.sender == devAdd, "Forbidden");
        devAdd = _devAdd;
        emit SetDevAddress(msg.sender, _devAdd);
    }
    
    function setExpedAdd(address _expedAdd) public {
        require(msg.sender == expedAdd, "Forbidden");
        expedAdd = _expedAdd;
        emit SetExpedAdd(msg.sender, _expedAdd);
    }

    function setTotalSummitPerBlock(uint256 _amount) public onlyOwner {
        summitPerBlock = _amount.mul(90).div(100);
        devSummitPerBlock = _amount.mul(8).div(100);
        referralsSummitPerBlock = _amount.mul(2).div(100);
    }

    function getTimeStamp() public view returns (uint256) { return block.timestamp; }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract ElevationHelper is Ownable {
    using SafeMath for uint256;
    uint256 constant sInH = 3600;
    uint8 constant OASIS = 0;
    uint8 constant TWOTHOUSAND = 1;
    uint8 constant FIVETHOUSAND = 2;
    uint8 constant TENTHOUSAND = 3;
    uint8 constant EXPEDITION = 4;
    uint8[5] public elevAllocModifiers = [100, 110, 125, 150, 100];
    uint8[5] public elevTotemCount = [1, 2, 5, 10, 2];
    uint256[5] public elevDurationSeconds = [0, 3600, 7200, 14400, 28800];
    mapping(uint8 => mapping(uint256 => uint256)) public poolWinCounter;

    uint256[5] public elevationUnlock;
    uint256[5] public elevationRoundEndTime;
    uint256[5] public elevationRound;
    mapping(uint256 => uint8) public expeditionRoundTotemDivider;
    mapping(uint8 => mapping(uint256 => uint8)) public roundWinningTotem;

    // REFERRAL
    uint256 REFERRAL_DURATION_SECONDS = 100;

    uint256 public referralGenesis;
    uint256 public referralRoundEndTime;
    uint256 public referralRound;

    // KEYWORD
    uint256 keywordRoundStart;

    
    // LOCAL
    address public cartographer;
    
    modifier onlyCartographer() {
        require(msg.sender == cartographer, "Not Cartographer" );
        _;
    }
    modifier allElevations(uint8 elev) {
        require(elev <= EXPEDITION, "Bad Elevation");
        _;
    }
    modifier elevationOrExpedition(uint8 elev) {
        require(elev >= TWOTHOUSAND && elev <= EXPEDITION, "Bad Elevation");
        _;
    }
    
    constructor(address _cartographer) public onlyOwner {
        require(_cartographer != address(0), "Cart missing");
        cartographer = _cartographer;
    }
    
    function enableSummit(uint256 genesisTime) external onlyCartographer() {
        uint256 nextHourTimestamp = genesisTime + (elevDurationSeconds[TWOTHOUSAND] - (genesisTime % elevDurationSeconds[TWOTHOUSAND]));
        elevationUnlock = [
            nextHourTimestamp,                              // oasis - throwaway
            nextHourTimestamp,                              // Two Thousand Meters Unlocks at next hour
            nextHourTimestamp.add(1 hours),                  // Five Thousand Meters Unlocks after 1 day
            nextHourTimestamp.add(4 hours),                  // Ten Thousand Meters Unlocks after 4 hours
            nextHourTimestamp.add(7 hours)                   // Expeditions Unlock after 7 hours
        ];
        elevationRoundEndTime = elevationUnlock;
        referralGenesis = nextHourTimestamp.add(1 hours);    // Referral Burn Unlocks after 1 day
        referralRoundEndTime = referralGenesis;
        keywordRoundStart = nextHourTimestamp;
    }
    
    // The elevation rewards multiplier
    function getElevationModifiedAllocPoint(uint256 allocPoint, uint8 elevation) external view allElevations(elevation) returns (uint256) {
        return allocPoint.mul(elevAllocModifiers[elevation]).div(100);
    }
    
    // RAND WINNING NUMBER
    function selectWinningTotem(uint8 elevation, uint256 rand) external elevationOrExpedition(elevation) onlyCartographer() {
        if (elevationRound[elevation] == 0) { return; }
        uint8 winningTotem;
        if (elevation == TWOTHOUSAND) { winningTotem = uint8(rand % 2); }
        if (elevation == FIVETHOUSAND) { winningTotem = uint8(rand % 5); }
        if (elevation == TENTHOUSAND) { winningTotem = uint8(rand % 10); }
        if (elevation == EXPEDITION) { winningTotem = uint8(rand % 100) < expeditionRoundTotemDivider[elevationRound[elevation]] ? 0 : 1; }
        
        poolWinCounter[elevation][winningTotem] += 1;
        roundWinningTotem[elevation][elevationRound[elevation]] = winningTotem;

        // Set Next Round Expedition Totem Divider
        if (elevation == EXPEDITION) {
            expeditionRoundTotemDivider[elevationRound[elevation] + 1] = uint8(50 + (uint256(keccak256(abi.encode(elevation, rand, block.timestamp, block.number))) % 50)); // Rand 50 - 99
        }
    }
    function getCurrentExpeditionRoundTotemDivider() external view returns (uint8) {
        return expeditionRoundTotemDivider[elevationRound[EXPEDITION]];
    }
    function getHistoricalWinningTotems(uint8 elevation) public view allElevations(elevation) returns (uint256[20] memory) {
        uint256 round = elevationRound[elevation];
        if (elevation == OASIS) {
            return [uint256(0), 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
        }
        if (elevation == TWOTHOUSAND || elevation == EXPEDITION) {
            return [
                poolWinCounter[elevation][0],
                poolWinCounter[elevation][1],
                0, 0, 0, 0, 0, 0, 0, 0,
                roundWinningTotem[elevation][round - 1],
                roundWinningTotem[elevation][round - 2],
                roundWinningTotem[elevation][round - 3],
                roundWinningTotem[elevation][round - 4],
                roundWinningTotem[elevation][round - 5],
                roundWinningTotem[elevation][round - 6],
                roundWinningTotem[elevation][round - 7],
                roundWinningTotem[elevation][round - 8],
                roundWinningTotem[elevation][round - 9],
                roundWinningTotem[elevation][round - 10]
            ];
        }
        if (elevation == FIVETHOUSAND) {
            return [
                poolWinCounter[elevation][0],
                poolWinCounter[elevation][1],
                poolWinCounter[elevation][2],
                poolWinCounter[elevation][3],
                poolWinCounter[elevation][4],
                0, 0, 0, 0, 0,
                roundWinningTotem[elevation][round - 1],
                roundWinningTotem[elevation][round - 2],
                roundWinningTotem[elevation][round - 3],
                roundWinningTotem[elevation][round - 4],
                roundWinningTotem[elevation][round - 5],
                roundWinningTotem[elevation][round - 6],
                roundWinningTotem[elevation][round - 7],
                roundWinningTotem[elevation][round - 8],
                roundWinningTotem[elevation][round - 9],
                roundWinningTotem[elevation][round - 10]
            ];
        }
        if (elevation == TENTHOUSAND) {
            return [
                poolWinCounter[elevation][0],
                poolWinCounter[elevation][1],
                poolWinCounter[elevation][2],
                poolWinCounter[elevation][3],
                poolWinCounter[elevation][4],
                poolWinCounter[elevation][5],
                poolWinCounter[elevation][6],
                poolWinCounter[elevation][7],
                poolWinCounter[elevation][8],
                poolWinCounter[elevation][9],
                roundWinningTotem[elevation][round - 1],
                roundWinningTotem[elevation][round - 2],
                roundWinningTotem[elevation][round - 3],
                roundWinningTotem[elevation][round - 4],
                roundWinningTotem[elevation][round - 5],
                roundWinningTotem[elevation][round - 6],
                roundWinningTotem[elevation][round - 7],
                roundWinningTotem[elevation][round - 8],
                roundWinningTotem[elevation][round - 9],
                roundWinningTotem[elevation][round - 10]
            ];
        }
    }


    // INTERFACE
    function getKeywordRoundEndTime() public view returns (uint256) {
        return block.timestamp + (elevDurationSeconds[TWOTHOUSAND] - (block.timestamp % elevDurationSeconds[TWOTHOUSAND]));
    }
    function getKeywordRound() external view returns (uint256) {
        return keywordRoundStart >= block.timestamp ? 0 : ((block.timestamp - keywordRoundStart) / elevDurationSeconds[TWOTHOUSAND]);
    }
    function getElevationLockedUntilRollover(uint8 elevation) external view returns (bool) {
        return block.timestamp + 60 >= elevationRoundEndTime[elevation];
    }
    function internalElevationStartRound(uint8 elevation) internal view returns (uint256) {
        return block.timestamp <= elevationUnlock[elevation] ? 0 : elevationRound[elevation];
    }
    function getElevationStartRound(uint8 elevation) external view returns (uint256) {
        return internalElevationStartRound(elevation);
    }
    function internalGetElevationTimeRemainingInRound(uint8 elevation) internal view returns (uint256) {
        return block.timestamp >= elevationRoundEndTime[elevation] ? 0 : elevationRoundEndTime[elevation] - block.timestamp;
    }
    function getElevationTimeRemainingInRound(uint8 elevation) external view returns (uint256) {
        return internalGetElevationTimeRemainingInRound(elevation);
    }
    function getElevationFracRoundRemaining(uint8 elevation) external view returns (uint256) {
        return internalGetElevationTimeRemainingInRound(elevation)
            .mul(1e12).div(elevDurationSeconds[elevation]);
    }
    function getElevationFracRoundProgress(uint8 elevation) external view returns (uint256) {
        return elevDurationSeconds[elevation].sub(internalGetElevationTimeRemainingInRound(elevation))
            .mul(1e12).div(elevDurationSeconds[elevation]);
    }
    function getElevationCurrentRoundStartTime(uint8 elevation) external view returns(uint256) {
        return elevationRoundEndTime[elevation].sub(elevDurationSeconds[elevation]);
    }
    function requireElevationRolloverAvailable(uint8 elevation) external view {
        require(block.timestamp >= elevationUnlock[elevation], "Elevation locked");
        require(block.timestamp >= elevationRoundEndTime[elevation], "Round already rolled over");
        return;
    }
    
    // VERIFIED
    function rolloverElevation(uint8 elevation) external onlyCartographer() {
        uint256 roundsToAdd = ((block.timestamp - elevationRoundEndTime[elevation]) / elevDurationSeconds[elevation]) + 1;
        elevationRound[elevation] += 1;
        elevationRoundEndTime[elevation] += (elevDurationSeconds[elevation] * roundsToAdd);
        return;
    }
    
    function getReferralBurnTimeRemaining() external view returns (uint256) {
        return referralRoundEndTime - block.timestamp;
    }
    function requireRolloverReferralBurnAvailable() external view {
        require(block.timestamp >= referralGenesis, "Referral burn locked");
        require(block.timestamp >= referralRoundEndTime, "Referral already burned");
        return;
    }
    function rolloverReferralBurn() external onlyCartographer() {
        referralRound += 1;
        referralRoundEndTime += REFERRAL_DURATION_SECONDS;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "./libs/IBEP20.sol";
import "./libs/SafeBEP20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


// Simple passthrough staking pool to test against
interface ICakeMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./libs/BEP20.sol";

// SummitToken with Governance.
contract SummitToken is BEP20('summit.defi', 'SUMMIT') {
    address burnAdd = 0x000000000000000000000000000000000000dEaD;

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (MasterChef).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
        _moveDelegates(address(0), _delegates[_to], _amount);
    }
    function burn(uint256 _amount) public {
        _approve(msg.sender, burnAdd, _amount);
        _transfer(msg.sender, burnAdd, _amount);
    }
    
    function mintInitialSummit(address _to) public onlyOwner { mint(_to, 20000e18); }

    // Copied and modified from YAM code:
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernanceStorage.sol
    // https://github.com/yam-finance/yam-protocol/blob/master/contracts/token/YAMGovernance.sol
    // Which is copied and modified from COMPOUND:
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/Comp.sol

    // A record of each accounts delegate
    mapping (address => address) internal _delegates;

    // A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint256 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

      /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegator The address to get delegatee for
     */
    function delegates(address delegator)
        external
        view
        returns (address)
    {
        return _delegates[delegator];
    }

   /**
    * @notice Delegate votes from `msg.sender` to `delegatee`
    * @param delegatee The address to delegate votes to
    */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint nonce,
        uint expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name())),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(
                DELEGATION_TYPEHASH,
                delegatee,
                nonce,
                expiry
            )
        );

        bytes32 digest = keccak256(
            abi.encode(
                "\x19\x01",
                domainSeparator,
                structHash
            )
        );

        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "SUMMIT::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "SUMMIT::delegateBySig: invalid nonce");
        require(now <= expiry, "SUMMIT::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account)
        external
        view
        returns (uint256)
    {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber)
        external
        view
        returns (uint256)
    {
        require(blockNumber < block.number, "Summit::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee)
        internal
    {
        address currentDelegate = _delegates[delegator];
        uint256 delegatorBalance = balanceOf(delegator); // balance of underlying Summits (not scaled);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveDelegates(address srcRep, address dstRep, uint256 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                // decrease old representative
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint256 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint256 srcRepNew = srcRepOld.sub(amount);
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                // increase new representative
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint256 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint256 dstRepNew = dstRepOld.add(amount);
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint256 oldVotes,
        uint256 newVotes
    )
        internal
    {
        uint32 blockNumber = safe32(block.number, "Summit::_writeCheckpoint: block number exceeds 32 bits");

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IRandomNumberGenerator {
    function getRandomNumber(string memory keyWord, address user, uint256 round, uint8 elevation, uint256 randAccum) external view returns (bytes32);
    function hashAgainstElevationReturnUint(bytes32 seedHash, uint8 elevation) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./SummitToken.sol";

interface ISummitReferrals {
    function enableSummit(SummitToken _summit) external;
    function addReferralRewardsIfNecessary(address referee, uint256 amount) external;
    function getReferralRound() external view returns(uint256);
    function burnUnclaimedReferralRewardsAndRolloverRound(address referee) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ISummitKeywords {
    function checkKeyword(string memory keyword, uint256 round) external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./libs/IBEP20.sol";
import "./libs/SafeBEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Cartographer.sol";
import "./CartographerOasis.sol";
import "./ICakeMasterChef.sol";

import "hardhat/console.sol";

contract CartographerOasis is Ownable, Initializable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // Info of each user.
    struct UserInfo {
        uint256 debt;
        uint256 staked;
    }

    struct OasisPoolInfo {              // EXISTS FOR ALL POOLS
        uint8 pid;                      // Running index, source of truth for pool
        IBEP20 lpToken;                 // Address of LP token contract.
        uint256 lpSupply;               // Could be overlapping LP pools, this allows that
        bool live;                      // To turn off pool in lieu of allocPoint
        uint256 lastRewardBlock;        // Last block number that SUMMIT distribution occurs.
        uint256 accSummitPerShare;      // Accumulated SUMMIT per share, times 1e12. See below.
        uint16 depositFeeBP;            // Deposit fee in basis points

        uint256 passthroughPid;
    }

    Cartographer cartographer;
    uint256 public summitGenesisTime = 1641028149; // 2022-1-1, will be updated when summit ecosystem switched on

    uint8 constant OASIS = 0;
    uint8[] public oasisPIDs;
    mapping(uint8 => bool) public pidExistence;
    mapping(uint8 => OasisPoolInfo) public oasisPoolInfo;
    mapping(uint8 => mapping(address => UserInfo)) public userInfo;
    
    constructor(address _Cartographer) public {
        require(_Cartographer != address(0), "Cartographer required");
        cartographer = Cartographer(_Cartographer);
    }

    function enableSummit(uint256 _genTime) external onlyCartographer() {
        summitGenesisTime = _genTime;
    }

    modifier onlyCartographer() {
        require(msg.sender == address(cartographer), "Only cartographer");
        _;
    }

    modifier validUserAdd(address userAdd) {
        require(userAdd != address(0), "User not 0");
        _;
    }

    mapping(IBEP20 => bool) public poolExistence;
    modifier nonDuplicated(IBEP20 _lpToken) {
        require(poolExistence[_lpToken] == false, "duplicated!");
        _;
    }

    modifier poolExists(uint8 pid) {
        require(pidExistence[pid], "Pool doesnt exist");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function add(uint8 _pid, bool _live, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate, uint256 _cakeChefPid) external onlyCartographer() nonDuplicated(_lpToken) {
        if (_withUpdate) {
            cartographer.massUpdatePools();
        }

        cartographer.enableTokenAtElevation(_lpToken, OASIS);
        
        poolExistence[_lpToken] = true;
        pidExistence[_pid] = true;
        oasisPIDs.push(_pid);

        oasisPoolInfo[_pid] = OasisPoolInfo({
            pid: _pid,
            lpToken: _lpToken,
            lpSupply: 0,
            live: _live,
            accSummitPerShare: 0,
            lastRewardBlock: block.number,
            depositFeeBP: _depositFeeBP,

            passthroughPid: _cakeChefPid
        });

        // PASSTHROUGH
        if (_cakeChefPid != 0) {
            cartographer.setPassthroughTokenManagement(
                _cakeChefPid,
                _lpToken,
                0
            );
        }
    }

    // Update the given pool's SUMMIT allocation point and deposit fee. Can only be called by the owner.
    function set(uint8 _pid, bool _live, uint16 _depositFeeBP, bool _withUpdate) external onlyCartographer() poolExists(_pid) {
        require(_depositFeeBP <= 400, "Invalid deposit fee");
        if (_withUpdate) {
            cartographer.massUpdatePools();
        }
        OasisPoolInfo storage pool = oasisPoolInfo[_pid];

        if (pool.live != _live) {
            if (_live) { cartographer.enableTokenAtElevation(pool.lpToken, OASIS); }
            else { cartographer.disableTokenAtElevation(pool.lpToken, OASIS); }
        }
        pool.live = _live;
        pool.depositFeeBP = _depositFeeBP;
    }
    
    function disablePassthrough(uint8 _pid) public onlyOwner poolExists(_pid) {
        // SAFETY VALVE
        OasisPoolInfo storage pool = oasisPoolInfo[_pid];
        if (pool.passthroughPid == 0) { return; }
        cartographer.disablePassthroughTokenManagement(pool.lpSupply, pool.passthroughPid);
        pool.passthroughPid = 0;
    }

    function setPassthrough(uint8 _pid, uint256 _cakeChefPid) public onlyOwner poolExists(_pid) {
        require(_cakeChefPid != 0, "Passthrough pid invalid");
        // Withdraw from previous passthrough pool if applicable
        disablePassthrough(_pid);
        
        // Send lp supply to new passthroughPool
        OasisPoolInfo storage pool = oasisPoolInfo[_pid];
        pool.passthroughPid = _cakeChefPid;

        cartographer.setPassthroughTokenManagement(
            _cakeChefPid,
            pool.lpToken,
            pool.lpSupply
        );
    }
    
    // INTERFACE
    function getPendingSummit(uint8 _pid, address _userAdd) public view poolExists(_pid) validUserAdd(_userAdd) returns (uint256) {
        OasisPoolInfo storage pool = oasisPoolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_userAdd];
        uint256 accSummitPerShare = pool.accSummitPerShare;
        uint256 staked = user.staked;
        if (block.number > pool.lastRewardBlock && pool.lpSupply != 0) {
            uint256 summitReward = cartographer.getSummitReward(pool.lastRewardBlock, pool.lpToken, OASIS);
            accSummitPerShare = accSummitPerShare.add(summitReward.mul(1e12).div(pool.lpSupply));
        }
        return staked.mul(accSummitPerShare).div(1e12).sub(user.debt);
    }

    function getLpSupply(uint8 _pid) external view poolExists(_pid) returns (uint256) {
        return oasisPoolInfo[_pid].lpSupply;
    }
    function getLpToken(uint8 _pid) external view poolExists(_pid) returns (IBEP20) {
        return oasisPoolInfo[_pid].lpToken;
    }
    function getDepositFee(uint8 _pid) external view poolExists(_pid) returns (uint256) {
        return oasisPoolInfo[_pid].depositFeeBP;
    }
    function getIsLive(uint8 _pid) external view poolExists(_pid) returns (bool) {
        return oasisPoolInfo[_pid].live;
    }
    
    function massUpdatePools() external onlyCartographer() {
        for (uint8 i = 0; i < oasisPIDs.length; i++) {
            updatePool(oasisPIDs[i]);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint8 _pid) public {
        OasisPoolInfo storage pool = oasisPoolInfo[_pid];
        if (pool.lastRewardBlock == block.number) { return; }
        if (block.timestamp < summitGenesisTime || pool.lpSupply == 0 || !pool.live) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 summitReward = cartographer.updatePoolMint(pool.lastRewardBlock, pool.lpToken, OASIS);
        pool.accSummitPerShare = pool.accSummitPerShare.add(summitReward.mul(1e12).div(pool.lpSupply));
        pool.lastRewardBlock = block.number;
    }
    
    function deposit(uint8 _pid, uint256 _amount, address _userAdd) external nonReentrant onlyCartographer() poolExists(_pid) validUserAdd(_userAdd) returns (uint256) {
        OasisPoolInfo storage pool = oasisPoolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_userAdd];

        return unifiedDeposit(pool, user, _amount, _userAdd, false);
    }

    function switchElevationValidate(uint8 _pid, address _lpToken, uint256 _cakeChefPid, address _userAdd) external nonReentrant onlyCartographer() poolExists(_pid) validUserAdd(_userAdd) {
        require(_lpToken == address(oasisPoolInfo[_pid].lpToken), "Different lpToken");
        require(_cakeChefPid == oasisPoolInfo[_pid].passthroughPid, "Different passthrough targets");
    }

    function switchElevationDeposit(uint8 _pid, uint256 _amount, address _userAdd) external nonReentrant onlyCartographer() returns (uint256) {
        OasisPoolInfo storage pool = oasisPoolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_userAdd];        
        return unifiedDeposit(pool,  user, _amount, _userAdd, true);
    }

    function unifiedDeposit(OasisPoolInfo storage pool,  UserInfo storage user, uint256 amount, address userAdd, bool elevationTransfer) internal returns (uint256) {
        updatePool(pool.pid);

        if (user.staked > 0) {
            uint256 pending = user.staked.mul(pool.accSummitPerShare).div(1e12).sub(user.debt);
            if (pending > 0) {
                cartographer.redeemRewards(userAdd, pending);
            }
        }

        uint256 amountAfterFee = amount;
        if (amount > 0) {
            if (!elevationTransfer) {
                amountAfterFee = cartographer.depositTokenManagement(
                    userAdd,
                    pool.lpToken,
                    pool.depositFeeBP,
                    amount,
                    pool.passthroughPid
                );
            }
            
            pool.lpSupply = pool.lpSupply.add(amountAfterFee);
        }
        
        user.staked = user.staked.add(amountAfterFee);
        user.debt = user.staked.mul(pool.accSummitPerShare).div(1e12);
        
        return amountAfterFee;
    }

    function withdraw(uint8 _pid, uint256 _amount, address _userAdd) external nonReentrant onlyCartographer() poolExists(_pid) validUserAdd(_userAdd) returns (uint256) {
        UserInfo storage user = userInfo[_pid][_userAdd];
        require(_amount > 0 && user.staked > 0 && user.staked >= _amount, "Bad withdrawal");
        
        OasisPoolInfo storage pool = oasisPoolInfo[_pid];

        return unifiedWithdrawal(pool,  user, _amount, _userAdd, false);
    }

    function switchElevationWithdraw(uint8 _pid, uint256 _amount, address _userAdd) external nonReentrant onlyCartographer() poolExists(_pid) validUserAdd(_userAdd) returns (address, uint256, uint256) {
        UserInfo storage user = userInfo[_pid][_userAdd];       
        require(_amount > 0 && user.staked > 0 && user.staked >= _amount, "Bad transfer");
        OasisPoolInfo storage pool = oasisPoolInfo[_pid];

        unifiedWithdrawal(pool, user, _amount, _userAdd, true);
        return (address(pool.lpToken), _amount, pool.passthroughPid);
    }

    function unifiedWithdrawal(OasisPoolInfo storage pool, UserInfo storage user, uint256 amount, address userAdd, bool elevationTransfer) internal returns (uint256) {
        updatePool(pool.pid);

        uint256 pending = user.staked.mul(pool.accSummitPerShare).div(1e12).sub(user.debt);
        if (pending > 0) {
            cartographer.redeemRewards(userAdd, pending);
        }

        user.staked = user.staked.sub(amount);
        pool.lpSupply = pool.lpSupply.sub(amount);        
        user.debt = user.staked.mul(pool.accSummitPerShare).div(1e12);
                
        if (!elevationTransfer) {
            cartographer.withdrawalTokenManagement(
                userAdd,
                pool.lpToken,
                amount,
                pool.passthroughPid
            );
        }

        return amount;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint8 _pid, address _userAdd) external nonReentrant onlyCartographer() poolExists(_pid) validUserAdd(_userAdd) returns (uint256) {
        OasisPoolInfo storage pool = oasisPoolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_userAdd];
        require(user.staked > 0, "Emergency Withdraw: nothing to withdraw");
        uint256 amount = user.staked;
        user.staked = 0;
        
        cartographer.withdrawalTokenManagement(
            _userAdd,
            pool.lpToken,
            amount,
            pool.passthroughPid
        );
        pool.lpSupply = pool.lpSupply.sub(amount);
        return amount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./libs/IBEP20.sol";
import "./libs/SafeBEP20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/Initializable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Cartographer.sol";
import "./ElevationHelper.sol";
import "./ICakeMasterChef.sol";
import "hardhat/console.sol";

contract CartographerElevation is Ownable, Initializable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    
    uint8 constant TWOTHOUSAND = 0;
    uint8 constant FIVETHOUSAND = 1;
    uint8 constant TENTHOUSAND = 2;

    struct UserInfo {
        // Yield Gambling
        uint256 prevInteractedRound;                // Round the user last made a deposit / withdrawal / harvest
        uint256 staked;                             // The amount of token the user has in the pool
        uint256 roundDebt;                          // Used to calculate user's first interacted round reward
        uint256 roundRew;                           // Running sum of user's rewards earned in current round

        // Vesting
        uint256 vestAmt;                            // The amount of SUMMIT reward to vest over a duration
        uint256 vestStart;                          // The start of the current vesting period, updated on interaction
        uint256 vestDur;                            // How long the current vesting stint lasts
    }
    
    struct RoundInfo {                              // All are multiplied by 1e12 during storage for math precision
        uint256 endAccSummitPerShare;               // The accSummitPerShare at the end of the round, used for back calculations
        uint256 winningsMultiplier;                 // Rewards multiplier: TOTAL POOL STAKED / WINNING TOTEM STAKED
        uint256 precomputedFullRoundMult;           // Change in accSummitPerShare over round multiplied by winnings multiplier
    }

    struct ElevationPoolInfo {
        uint8 pid;                                  // Running index, source of truth for pool
        bool enabled;                               // If start round has passed.
        IBEP20 lpToken;                             // Address of LP token contract.
        uint256 lpSupply;                           // Could be overlapping LP pools, this allows that
        bool live;                                  // If the pool is running, in lieu of allocPoint
        uint256 lastRewardBlock;                    // Last block number that SUMMIT distribution occurs.
        uint256 accSummitPerShare;                  // Accumulated SUMMIT per share, times 1e12. See below.
        uint16 depositFeeBP;                        // Deposit fee in basis points
        uint8 elevation;                            // The elevation of this pool

        uint256[] totemLpSupplies;                   // Running total of LP in each totem to calculate rewards
        uint256 roundRewards;                       // Rewards of entire pool accum over round
        uint256[] totemRoundRewards;                 // Rewards of each totem accum over round
        uint256 startRound;                         // The global elevation round pool started on

        uint256 passthroughPid;
    }

    Cartographer cartographer;
    ElevationHelper elevationHelper;

    // Info of each pool.
    uint8[] public elevationPIDs;
    mapping(uint8 => bool) public pidExistence;
    mapping(uint8 => ElevationPoolInfo) public elevationPoolInfo;
    mapping(uint8 => mapping(address => UserInfo)) public userInfo;
    mapping(address => mapping(uint8 => uint8)) public userTotem;
    mapping(uint8 => mapping(uint256 => RoundInfo)) public poolRoundInfo;
    mapping(uint8 => uint8[]) public poolsAtElevation;
    
    constructor(address _Cartographer) public {
        require(_Cartographer != address(0), "Cartographer required");
        cartographer = Cartographer(_Cartographer);
    }

    function initialize(address _ElevationHelper) external initializer onlyCartographer() {
        require(_ElevationHelper != address(0), "Contract is zero");
        elevationHelper = ElevationHelper(_ElevationHelper);
    }

    modifier onlyCartographer() {
        require(msg.sender == address(cartographer), "Only cartographer");
        _;
    }
    modifier validUserAdd(address _userAdd) {
        require(_userAdd != address(0), "User address is zero");
        _;
    }

    mapping(IBEP20 => mapping(uint8 => bool)) public poolExistence;
    modifier nonDuplicated(IBEP20 _lpToken, uint8 _elevation) {
        require(poolExistence[_lpToken][_elevation] == false, "Duplicated");
        _;
    }
    
    modifier poolExists(uint8 pid) {
        require(pidExistence[pid], "Pool doesnt exist");
        _;
    }
    modifier poolExistsAndEnabled(uint8 pid) {
        require(pidExistence[pid], "Pool doesnt exist");
        require(elevationPoolInfo[pid].enabled, "Pool not available yet");
        _;
    }
    
    modifier validElevation(uint8 elevation) {
        require(elevation <= 2, "Invalid elevation");
        _;
    }
    modifier validTotem(uint8 elevation, uint8 totem) {
        require(totem < elevationHelper.elevTotemCount(elevation), "Invalid totem");
        _;
    }
    modifier elevationNotLockedUntilRollover(uint8 elevation) {
        require(!elevationHelper.getElevationLockedUntilRollover(elevation), "Elev locked until rollover");
        _;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    function registerPool(uint8 _pid, IBEP20 _lpToken, uint8 _elevation) internal {
        poolExistence[_lpToken][_elevation] = true;
        pidExistence[_pid] = true;
        poolsAtElevation[_elevation].push(_pid);
        elevationPIDs.push(_pid);
    }

    function add(uint8 _pid, bool _live, IBEP20 _lpToken, uint16 _depositFeeBP, bool _withUpdate, uint8 _elevation, uint256 _cakeChefPid) external onlyCartographer() nonDuplicated(_lpToken, _elevation) {
        if (_withUpdate) {
            cartographer.massUpdatePools();
        }
        
        registerPool(_pid, _lpToken, _elevation);

        elevationPoolInfo[_pid] = ElevationPoolInfo({
            pid: _pid,
            enabled: false,
            lpToken: _lpToken,
            lpSupply: 0,
            live: _live,
            accSummitPerShare : 0,
            lastRewardBlock : block.number,
            depositFeeBP : _depositFeeBP,
            elevation : _elevation,

            totemLpSupplies : new uint256[](elevationHelper.elevTotemCount(_elevation)),
            roundRewards : 0,
            totemRoundRewards : new uint256[](elevationHelper.elevTotemCount(_elevation)),
            startRound: elevationHelper.getElevationStartRound(_elevation),

            passthroughPid: _cakeChefPid
        });

        // PASSTHROUGH
        if (_cakeChefPid != 0) {
            cartographer.setPassthroughTokenManagement(
                _cakeChefPid,
                _lpToken,
                0
            );
        }
    }
    
    function disablePassthrough(uint8 _pid) public onlyOwner poolExists(_pid) {
        ElevationPoolInfo storage pool = elevationPoolInfo[_pid];
        if (pool.passthroughPid == 0) { return; }
        cartographer.disablePassthroughTokenManagement(pool.lpSupply, pool.passthroughPid);
        pool.passthroughPid = 0;
    }
    
    function setPassthrough(uint8 _pid, uint256 _cakeChefPid) public onlyOwner poolExists(_pid) {
        require(_cakeChefPid != 0, "Passthrough info required");
        // Withdraw from previous passthrough pool if applicable
        disablePassthrough(_pid);
        
        // Send lp supply to new passthroughPool
        ElevationPoolInfo storage pool = elevationPoolInfo[_pid];
        pool.passthroughPid = _cakeChefPid;

        cartographer.setPassthroughTokenManagement(
            _cakeChefPid,
            pool.lpToken,
            pool.lpSupply
        );


    }

    // Update the given pool's SUMMIT allocation point and deposit fee. Can only be called by the owner.
    function set(uint8 _pid, bool _live, uint16 _depositFeeBP, bool _withUpdate) public onlyCartographer() poolExists(_pid) {
        require(_depositFeeBP <= 400, "Invalid deposit fee");
        if (_withUpdate) {
            cartographer.massUpdatePools();
        }
        ElevationPoolInfo storage pool = elevationPoolInfo[_pid];

        if (pool.live != _live) {
            if (_live) { cartographer.enableTokenAtElevation(pool.lpToken, pool.elevation); }
            else { cartographer.disableTokenAtElevation(pool.lpToken, pool.elevation); }
        }
        pool.live = _live;
        pool.depositFeeBP = _depositFeeBP;
    }

    ////////////////////////////////
    //       R O L L O V E R      //
    ////////////////////////////////
    
    function rolloverAllRoundsAtElevation(uint8 _elevation) external onlyCartographer() {
        uint8[] memory poolsAtElev = poolsAtElevation[_elevation];
        uint256 currRound = elevationHelper.elevationRound(_elevation);
        uint256 nextRound = currRound + 1;
        for (uint8 i = 0; i < poolsAtElev.length; i++) {
            uint8 pidAtElev = poolsAtElev[i];
            if (elevationPoolInfo[pidAtElev].enabled) {
                endRoundAndStartNext(pidAtElev, currRound, nextRound);

            } else {
                startFirstRoundIfAvailable(pidAtElev, nextRound);
            }
        }
    }
    
    function endRoundAndStartNext(uint8 _pid, uint256 currRound, uint256 nextRound) internal poolExistsAndEnabled(_pid) {
        ElevationPoolInfo storage pool = elevationPoolInfo[_pid];
        if (currRound == 0 || pool.startRound == nextRound) { return; } // Exit on pool starting round rollover
        updatePool(_pid);

        uint256 accSummitPerShare = pool.accSummitPerShare;
        uint256 deltaAccSummitPerShare = accSummitPerShare.sub(poolRoundInfo[_pid][currRound - 1].endAccSummitPerShare);
        uint256 winningTotemRoundRewards = pool.totemRoundRewards[elevationHelper.roundWinningTotem(pool.elevation, currRound)];
        uint256 winningsMultiplier = winningTotemRoundRewards == 0 ? 0 : pool.roundRewards.mul(1e12).div(winningTotemRoundRewards);
        poolRoundInfo[_pid][currRound] = RoundInfo({
            endAccSummitPerShare: accSummitPerShare,
            winningsMultiplier: winningsMultiplier,
            precomputedFullRoundMult: deltaAccSummitPerShare.mul(winningsMultiplier).div(1e12)
        });
        
        pool.roundRewards = 0;
        pool.totemRoundRewards = new uint256[](elevationHelper.elevTotemCount(pool.elevation));
    }

    function startFirstRoundIfAvailable(uint8 _pid, uint256 nextRound) internal poolExists(_pid) {
        ElevationPoolInfo storage pool = elevationPoolInfo[_pid];
        if (nextRound < pool.startRound || !pool.live) { return; }
        pool.enabled = true;
        cartographer.enableTokenAtElevation(pool.lpToken, pool.elevation);
    }

    ////////////////////////////////
    //        P E N D I N G       //
    ////////////////////////////////
    function getMultiplier(uint256 _from, uint256 _to) public pure returns (uint256) {
        return _to.sub(_from);
    }
    
    function getVestingAvail(UserInfo storage user) internal view returns (uint256) {
        if (user.vestAmt == 0) { return 0; }
        if (block.timestamp >= user.vestStart.add(user.vestDur)) { return user.vestAmt; }
        return user.vestAmt.mul(block.timestamp.sub(user.vestStart)).div(user.vestDur);
    }

    function getPendingAndVestingSummit(uint8 _pid, address _userAdd) external view onlyCartographer() poolExists(_pid) validUserAdd(_userAdd) returns (uint256, uint256, uint256, uint256) {
        ElevationPoolInfo storage pool = elevationPoolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_userAdd];
        (uint256 vestingAmount, uint256 vestingDuration, uint256 currentVestingPeriodStart) = getRemainingToVest(pool, user, _userAdd);
        return (getElevationPendingSummit(pool, user, _userAdd), vestingAmount, currentVestingPeriodStart, vestingDuration);
    }

    function getCurrentAccSummitPerShare(ElevationPoolInfo memory pool) internal view returns (uint256, uint256) {
        if (block.number > pool.lastRewardBlock && pool.lpSupply > 0) {
            uint256 summitReward = cartographer.getSummitReward(pool.lastRewardBlock, pool.lpToken, pool.elevation);
            return (pool.accSummitPerShare.add(summitReward.mul(1e12).div(pool.lpSupply)), summitReward);
        }
        return (pool.accSummitPerShare, 0);
    }

    function getUserHypotheticalReward(ElevationPoolInfo memory pool, UserInfo storage user, uint256 accSummitPerShare) internal view returns (uint256) {
        uint256 currRound = elevationHelper.elevationRound(pool.elevation);
        if (user.prevInteractedRound == currRound) {
            return user.staked.mul(accSummitPerShare).div(1e12).sub(user.roundDebt).add(user.roundRew);   // Change in accSummitPerShare since debt point above
        }
        return user.staked.mul(accSummitPerShare.sub(poolRoundInfo[pool.pid][currRound - 1].endAccSummitPerShare)).div(1e12);
    }
    
    function getHypotheticalSummit(uint8 _pid, address _userAdd) external view poolExists(_pid) validUserAdd(_userAdd) returns (uint256, uint256) {
        ElevationPoolInfo memory pool = elevationPoolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_userAdd];
        
        (uint256 accSummitPerShare, uint256 summitReward) = getCurrentAccSummitPerShare(pool);
        uint8 totem = userTotem[_userAdd][pool.elevation];
        (uint256 liveRoundRewards, uint256 liveTotemRoundRewards) = getLiveRoundRewards(_pid, totem, summitReward);
        uint256 rew = getUserHypotheticalReward(pool, user, accSummitPerShare);    
        if (rew == 0 || liveTotemRoundRewards == 0) { return (0, 0); }
        return (
            // CURRENT: How much the user has farmed currently
            rew,
            // IF WIN: User rewards * (total round rewards / totem rewards)
            liveTotemRoundRewards > 0 ? rew.mul(liveRoundRewards).div(liveTotemRoundRewards) : rew
        );
    }

    function getUserFirstInteractedRoundReward(RoundInfo memory round, UserInfo storage user) internal view returns (uint256) {
        return user.staked
            .mul(round.endAccSummitPerShare).div(1e12).sub(user.roundDebt)
            .add(user.roundRew)
            .mul(round.winningsMultiplier).div(1e12);
    }

    function getFracRoundProgressAvailWinnings(uint256 amount, uint8 elevation) internal view returns (uint256) {
        return amount.mul(elevationHelper.getElevationFracRoundProgress(elevation)).div(1e12);
    }

    function getRoundWinnings(ElevationPoolInfo storage pool, UserInfo storage user, uint256 roundIndex, uint256 prevRoundIndex, address userAdd) internal view returns (uint256) {
        if (userTotem[userAdd][pool.elevation] != elevationHelper.roundWinningTotem(pool.elevation, roundIndex)) { return 0; }
        
        RoundInfo memory round = poolRoundInfo[pool.pid][roundIndex];

        uint256 roundWinnings = user.prevInteractedRound == roundIndex ?
            getUserFirstInteractedRoundReward(round, user) :
            user.staked.mul(round.precomputedFullRoundMult).div(1e12);

        return roundIndex == prevRoundIndex ?
            getFracRoundProgressAvailWinnings(roundWinnings, pool.elevation) :
            roundWinnings;
    } 
    
    function getElevationPendingSummit(ElevationPoolInfo storage pool, UserInfo storage user, address userAdd) internal view poolExists(pool.pid) returns (uint256) {
        uint256 currRound = elevationHelper.elevationRound(pool.elevation);
        if (currRound <= pool.startRound) { return 0; } // return this value when no previous rounds available to be harvested

        uint256 avail = getVestingAvail(user);

        // If user has nothing staked, or last user interaction is within current round (this handles Round 0), return the VESTING AVAILABLE
        if (user.prevInteractedRound == currRound) { return avail; }
        
        // Else increment the available rewards (from vesting so far) with each rounds winnings
        uint256 prevRoundIndex = currRound - 1;
        for (uint256 roundIndex = user.prevInteractedRound; roundIndex < currRound; roundIndex++) {
            avail += getRoundWinnings(
                pool,
                user,
                roundIndex,
                prevRoundIndex,
                userAdd
            );
        }

        return avail;
    }
    
    function getRemainingToVest(ElevationPoolInfo storage pool, UserInfo storage user, address userAdd) internal view returns (uint256, uint256, uint256) {
        // Returns (AMOUNT CURRENTLY VESTING, VESTING DUR, VESTING START)
        uint256 currRound = elevationHelper.elevationRound(pool.elevation);
        if (currRound == pool.startRound || currRound == 0) {
            return (0, 0, 0);
        }

        if (user.prevInteractedRound == currRound) {
            // Vesting info comes from UserInfo
            uint256 avail = getVestingAvail(user);
            return (
                user.vestAmt.sub(avail),
                elevationHelper.getElevationTimeRemainingInRound(pool.elevation),
                user.vestStart
            );
        }

        // Vesting info comes from previous rounds win/loss
        uint256 roundWinnings = getRoundWinnings(
            pool,
            user,
            currRound - 1,      // Previous Round Index
            currRound,          // This has to be different than previous param to force no vesting
            userAdd
        );

        // Escape early if previous round was lost
        if (roundWinnings == 0) { return (0, 0, 0); }

        return (
            roundWinnings.mul(elevationHelper.getElevationFracRoundRemaining(pool.elevation)).div(1e12),    // Total winnings of previous round as they vest
            elevationHelper.getElevationTimeRemainingInRound(pool.elevation),                               // Vesting duration remaining
            elevationHelper.getElevationCurrentRoundStartTime(pool.elevation)                               // Round Start, when this vesting period really began
        );
    }

    function massUpdatePools() external onlyCartographer() {
        for (uint8 i = 0; i < elevationPIDs.length; i++) {
            updatePool(elevationPIDs[i]);
        }
    }

    function updatePool(uint8 _pid) public {
        ElevationPoolInfo storage pool = elevationPoolInfo[_pid];
        if (pool.lastRewardBlock == block.number) { return; }
        if (!pool.enabled || pool.lpSupply == 0 || !pool.live) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 summitReward = cartographer.updatePoolMint(pool.lastRewardBlock, pool.lpToken, pool.elevation);
        pool.accSummitPerShare = pool.accSummitPerShare.add(summitReward.mul(1e12).div(pool.lpSupply));
        
        pool.roundRewards = pool.roundRewards.add(summitReward);
        for (uint8 i = 0; i < pool.totemRoundRewards.length; i++) {
            pool.totemRoundRewards[i] = pool.totemRoundRewards[i].add(summitReward.mul(1e12).mul(pool.totemLpSupplies[i]).div(pool.lpSupply).div(1e12));
        }        
        pool.lastRewardBlock = block.number;
    }

    function harvestPendingAndUpdateVesting(ElevationPoolInfo storage pool, UserInfo storage user, address userAdd) internal {
        uint256 pending = getElevationPendingSummit(pool, user, userAdd);
        if (pending > 0) {
            cartographer.redeemRewards(userAdd, pending);
        }
        (uint256 vestAmount, uint256 vestDur,) = getRemainingToVest(pool, user, userAdd);
        user.vestAmt = vestAmount;
        if (vestAmount == 0) { return; }
        user.vestDur = vestDur;
        user.vestStart = block.timestamp;
    }

    function updateUserRoundInteraction(ElevationPoolInfo storage pool, UserInfo storage user, uint256 amount, bool isDeposit) internal {
        uint256 currRound = elevationHelper.elevationRound(pool.elevation);

        if (user.prevInteractedRound == currRound) {
            // User already interacted this round, update current interaction
            user.roundRew = user.roundRew.add(user.staked.mul(pool.accSummitPerShare).div(1e12).sub(user.roundDebt));
        } else {
            // User interacted in any previous round, create new interaction based on that previous round's stats
            uint256 roundStartAccSummitPerShare = poolRoundInfo[pool.pid][currRound - 1].endAccSummitPerShare;
            user.roundRew = user.staked.mul(pool.accSummitPerShare.sub(roundStartAccSummitPerShare)).div(1e12); // Done before the staked updated because it is the earned amount before the change
        }
        
        if (isDeposit) { user.staked += amount; }
        else { user.staked -= amount; } // Validated in require of withdraw functions
        
        user.roundDebt = user.staked.mul(pool.accSummitPerShare).div(1e12); // The debt is the amount after the change in staked amount, which is why it references the updated staked
        user.prevInteractedRound = currRound;
        return;
    }


    ///////////////////////////////////
    //    I N T E R A C T I O N S    //
    ///////////////////////////////////

    function getLpSupply(uint8 _pid) external view poolExists(_pid) returns (uint256) {
        return elevationPoolInfo[_pid].lpSupply;
    }
    function getLpToken(uint8 _pid) external view poolExists(_pid) returns (IBEP20) {
        return elevationPoolInfo[_pid].lpToken;
    }
    function getDepositFee(uint8 _pid) external view poolExists(_pid) returns (uint256) {
        return elevationPoolInfo[_pid].depositFeeBP;
    }
    function getIsLive(uint8 _pid) external view poolExists(_pid) returns (bool) {
        return elevationPoolInfo[_pid].live;
    }
    function switchAllTotems(uint8 _elevation, uint8 _newTotem, address _userAdd) external nonReentrant onlyCartographer() validTotem(_elevation, _newTotem) validUserAdd(_userAdd) elevationNotLockedUntilRollover(_elevation) {
        // Switch users totem and harvest pending for all pools at elevation
        uint8 prevTotem = userTotem[_userAdd][_elevation];
        for (uint8 i = 0; i < poolsAtElevation[_elevation].length; i++) {
            uint8 pidAtElev = poolsAtElevation[_elevation][i];
            if (elevationPoolInfo[pidAtElev].enabled && userInfo[pidAtElev][_userAdd].staked > 0) {
                switchTotem(pidAtElev, prevTotem, _newTotem, _userAdd);
            }
        }
        userTotem[_userAdd][_elevation] = _newTotem;
    }

    function internalIsTotemInUse(uint8 _elevation, address _userAdd) internal view returns (bool) {
        for (uint8 i = 0; i < poolsAtElevation[_elevation].length; i++) {
            if (elevationPoolInfo[poolsAtElevation[_elevation][i]].enabled && userInfo[poolsAtElevation[_elevation][i]][_userAdd].staked > 0) {
                return true;
            }
        }
        return false;
    }
    function getIsTotemInUse(uint8 _elevation, address _userAdd) external view returns (bool) {
        return internalIsTotemInUse(_elevation, _userAdd);
    }

    function switchTotem(uint8 pidAtElev, uint8 _prevTotem, uint8 _newTotem, address _userAdd) internal {
        UserInfo storage user = userInfo[pidAtElev][_userAdd];
        if (user.staked == 0) { return; }
        
        ElevationPoolInfo storage pool = elevationPoolInfo[pidAtElev];
        
        harvestPendingAndUpdateVesting(pool, user, _userAdd);
        updateUserRoundInteraction(pool, user, 0, true);

        pool.totemLpSupplies[_prevTotem] -= user.staked;
        pool.totemLpSupplies[_newTotem] += user.staked;
        pool.totemRoundRewards[_prevTotem] -= user.roundRew;
        pool.totemRoundRewards[_newTotem] += user.roundRew;
    }

    
    
    function depositTokenManagement(uint8 pid, uint256 amount, address userAdd) internal returns (uint256) {
        return cartographer.depositTokenManagement(
            userAdd,
            elevationPoolInfo[pid].lpToken,
            elevationPoolInfo[pid].depositFeeBP,
            amount,
            elevationPoolInfo[pid].passthroughPid
        );
    }
    
    
    function deposit(uint8 _pid, uint256 _amount, uint8 _totem, address _userAdd) external nonReentrant onlyCartographer() poolExistsAndEnabled(_pid) validTotem(elevationPoolInfo[_pid].elevation, _totem) validUserAdd(_userAdd) elevationNotLockedUntilRollover(elevationPoolInfo[_pid].elevation) returns (uint256) {
        UserInfo storage user = userInfo[_pid][_userAdd];
        ElevationPoolInfo storage pool = elevationPoolInfo[_pid];
        require(!internalIsTotemInUse(pool.elevation, _userAdd) || userTotem[_userAdd][pool.elevation] == _totem, "Cant switch totem during deposit");

        updatePool(pool.pid);
        harvestPendingAndUpdateVesting(pool, user, _userAdd);

        uint256 amountAfterFee = _amount > 0 ?
            depositTokenManagement(_pid, _amount, _userAdd) :
            _amount;
            
        pool.totemLpSupplies[_totem] += amountAfterFee;
        pool.lpSupply += amountAfterFee;
        
        updateUserRoundInteraction(pool, user, amountAfterFee, true);
        userTotem[_userAdd][pool.elevation] = _totem;

        return amountAfterFee;
    }

    function switchElevationValidate(uint8 _pid, address _lpToken, uint256 _cakeChefPid, uint8 _totem, address _userAdd) external nonReentrant onlyCartographer() poolExistsAndEnabled(_pid) validTotem(elevationPoolInfo[_pid].elevation, _totem) elevationNotLockedUntilRollover(elevationPoolInfo[_pid].elevation) {
        require(!internalIsTotemInUse(elevationPoolInfo[_pid].elevation, _userAdd) || userTotem[_userAdd][elevationPoolInfo[_pid].elevation] == _totem, "Cant switch totem during transfer");
        require(_lpToken == address(elevationPoolInfo[_pid].lpToken), "Different lpToken");
        require(_cakeChefPid == elevationPoolInfo[_pid].passthroughPid, "Different passthrough targets");
    }

    function switchElevationDeposit(uint8 _pid, uint256 _amount, uint8 _totem, address _userAdd) external nonReentrant onlyCartographer() returns (uint256) {
        UserInfo storage user = userInfo[_pid][_userAdd];
        ElevationPoolInfo storage pool = elevationPoolInfo[_pid];

        updatePool(pool.pid);
        harvestPendingAndUpdateVesting(pool, user, _userAdd);
            
        pool.totemLpSupplies[_totem] += _amount;
        pool.lpSupply += _amount;
        
        updateUserRoundInteraction(pool, user, _amount, true);

        return _amount;
    }

    function withdraw(uint8 _pid, uint256 _amount, address _userAdd) external nonReentrant onlyCartographer() poolExists(_pid) validUserAdd(_userAdd) elevationNotLockedUntilRollover(elevationPoolInfo[_pid].elevation) returns (uint256) {
        UserInfo storage user = userInfo[_pid][_userAdd];
        require(_amount > 0 && user.staked > 0 && user.staked >= _amount, "Bad withdrawal");
        ElevationPoolInfo storage pool = elevationPoolInfo[_pid];

        return unifiedWithdrawal(pool, user, _amount, _userAdd, false);
    }

    function switchElevationWithdraw(uint8 _pid, uint256 _amount, address _userAdd) external nonReentrant onlyCartographer() poolExists(_pid) validUserAdd(_userAdd) elevationNotLockedUntilRollover(elevationPoolInfo[_pid].elevation) returns (address, uint256, uint256) {
        UserInfo storage user = userInfo[_pid][_userAdd];       
        require(_amount > 0 && user.staked > 0 && user.staked >= _amount, "Bad transfer");
        ElevationPoolInfo storage pool = elevationPoolInfo[_pid];

        unifiedWithdrawal(pool, user, _amount, _userAdd, true);
        return (address(pool.lpToken), _amount, pool.passthroughPid);
    }  

    function unifiedWithdrawal(ElevationPoolInfo storage pool, UserInfo storage user, uint256 amount, address userAdd, bool elevationTransfer) internal returns (uint256) {
        updatePool(pool.pid);
        
        harvestPendingAndUpdateVesting(pool, user, userAdd);
        updateUserRoundInteraction(pool, user, amount, false);
        
        if (!elevationTransfer) {
            cartographer.withdrawalTokenManagement(userAdd, pool.lpToken, amount, pool.passthroughPid);
        }
        
        uint8 totem = userTotem[userAdd][pool.elevation];
        pool.totemLpSupplies[totem] = pool.totemLpSupplies[totem].sub(amount);
        pool.lpSupply = pool.lpSupply.sub(amount);        

        return amount;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint8 _pid, address _userAdd) external nonReentrant onlyCartographer() poolExistsAndEnabled(_pid) validUserAdd(_userAdd) elevationNotLockedUntilRollover(elevationPoolInfo[_pid].elevation) returns (uint256) {
        UserInfo storage user = userInfo[_pid][_userAdd];
        require(user.staked > 0, "Nothing to emergency withdraw");
        ElevationPoolInfo storage pool = elevationPoolInfo[_pid];
        updatePool(pool.pid);
        
        uint256 amount = user.staked;
        user.prevInteractedRound = 0;
        user.staked = 0;

        cartographer.withdrawalTokenManagement(_userAdd, pool.lpToken, amount, pool.passthroughPid);

        uint8 totem = userTotem[_userAdd][pool.elevation];
        pool.totemLpSupplies[totem] = pool.totemLpSupplies[totem].sub(amount);
        pool.lpSupply = pool.lpSupply.sub(amount);

        return amount;
    }

    // TESTING FUNCTIONS
    function totemLpSupplies(uint8 _pid) public view poolExists(_pid) returns (uint256[10] memory) {
        ElevationPoolInfo storage pool = elevationPoolInfo[_pid];
        if (pool.elevation == 1) {
            return [pool.totemLpSupplies[0], pool.totemLpSupplies[1], 0, 0, 0, 0, 0, 0, 0, 0];
        } else if (pool.elevation == 2) {
            return [pool.totemLpSupplies[0], pool.totemLpSupplies[1], pool.totemLpSupplies[2], pool.totemLpSupplies[3], pool.totemLpSupplies[4], 0, 0, 0, 0, 0];
        } else {
            return [pool.totemLpSupplies[0], pool.totemLpSupplies[1], pool.totemLpSupplies[2], pool.totemLpSupplies[3], pool.totemLpSupplies[4], pool.totemLpSupplies[5], pool.totemLpSupplies[6], pool.totemLpSupplies[7], pool.totemLpSupplies[8], pool.totemLpSupplies[9]];
        }       
    }
    function totemRoundRewards(uint8 _pid) public view poolExists(_pid) returns (uint256[11] memory) {
        ElevationPoolInfo storage pool = elevationPoolInfo[_pid];
        uint8 totemCount = elevationHelper.elevTotemCount(pool.elevation);
        uint256 summitReward = cartographer.getSummitReward(pool.lastRewardBlock, pool.lpToken, pool.elevation);
        uint256[11] memory finalTotemRewards;
        finalTotemRewards[0] = pool.roundRewards.add(summitReward);
        for (uint8 i = 0; i < 10; i++) {
            if (i >= totemCount) {
                finalTotemRewards[i + 1] = 0;
            } else if (pool.lpSupply == 0 || pool.totemLpSupplies[i] == 0) {
                finalTotemRewards[i + 1] = pool.totemRoundRewards[i];
            } else {
                finalTotemRewards[i + 1] = pool.totemRoundRewards[i]
                    .add(summitReward
                        .mul(1e12)
                        .mul(pool.totemLpSupplies[i])
                        .div(pool.lpSupply)
                        .div(1e12)
                    );
            }
        }
        return finalTotemRewards;
    }
    function getLiveRoundRewards(uint8 _pid, uint8 _totem, uint256 _summitReward) internal view returns (uint256, uint256) {
        ElevationPoolInfo storage pool = elevationPoolInfo[_pid];
        return (
            pool.roundRewards.add(_summitReward),
            pool.lpSupply == 0 || pool.totemLpSupplies[_totem] == 0 ? 
                pool.totemRoundRewards[_totem] :
                pool.totemRoundRewards[_totem]
                    .add(_summitReward
                        .mul(1e12)
                        .mul(pool.totemLpSupplies[_totem])
                        .div(pool.lpSupply)
                        .div(1e12)
                    )
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/GSN/Context.sol';
import './IBEP20.sol';
import '@openzeppelin/contracts/math/SafeMath.sol';

/**
 * @dev Implementation of the {IBEP20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {BEP20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-BEP20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of BEP20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IBEP20-approve}.
 */
contract BEP20 is Context, IBEP20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external override view returns (address) {
        return owner();
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
    * @dev Returns the number of decimals used to get its user representation.
    */
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {BEP20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {BEP20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {BEP20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {BEP20-allowance}.
     */
    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    /**
     * @dev See {BEP20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {BEP20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {BEP20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom (address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'BEP20: transfer amount exceeds allowance')
        );
        return true;
    }

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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {BEP20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, 'BEP20: decreased allowance below zero'));
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `msg.sender`, increasing
     * the total supply.
     *
     * Requirements
     *
     * - `msg.sender` must be the token owner
     */
    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer (address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), 'BEP20: transfer from the zero address');
        require(recipient != address(0), 'BEP20: transfer to the zero address');

        _balances[sender] = _balances[sender].sub(amount, 'BEP20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: mint to the zero address');

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), 'BEP20: burn from the zero address');

        _balances[account] = _balances[account].sub(amount, 'BEP20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve (address owner, address spender, uint256 amount) internal {
        require(owner != address(0), 'BEP20: approve from the zero address');
        require(spender != address(0), 'BEP20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, 'BEP20: burn amount exceeds allowance'));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";

