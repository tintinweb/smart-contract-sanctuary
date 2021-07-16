// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.0;

import {Ownable} from "./Ownable.sol";
import {ReentrancyGuard} from './ReentrancyGuard.sol';
import {SafeERC20} from './SafeERC20.sol';
import {IERC20} from './IERC20.sol';
import {Initializable} from './Initializable.sol';


/// @title Synthetic Delegation Contract
/// @notice User comes and wants to stake LX tokens to get LXP tokens to gain discounts and/or guaranteed allocations
///   to IDO’s and passive yield, in the form of tokens or cash. Yield is in LX tokens.
/// @notice When tokens are staked, they immediately get locked and user gets synthetic LXP tokens,
///   however, tokens are not given access to yield until next two-week cycle.
contract SyntheticDelegation is ReentrancyGuard, Initializable {  // todo: ownable?
    using SafeERC20 for IERC20;
    uint256 constant FIRST_MONDAY = 24 * 3600 * 4;  // 01.01.1970 was a Thursday, so 24 * 3600 * 4 is the first Monday python: datetime.datetime.fromtimestamp(24 * 3600 * 4).weekday()
    uint256 constant WINDOW = 2 * 3600 * 24 * 7;   // 2 weeks
    uint256 constant ACTION_WINDOW = 1 * 3600;  // 1 hour to stake/unstake

//    struct WithdrawOrder {
//        uint256 amount;
//        uint256 lockedTill;
//    }
//    mapping (address => mapping(uint256 => WithdrawOrder)) internal _userWithdrawOrder;

    uint256 public totalCurrentPeriodStakeAmount;
    uint256 public totalNextPeriodStakeAmount;
    uint256 public globalCachePeriod;
    uint256[] public periodTotalReward;
    uint256[] public periodTotalStaked;
    struct UserProfile {
        uint256 currentPeriodStake;
        uint256 nextPeriodStake;
        uint256 currentPeriodAvailableUnstake;
        uint256 nextPeriodAvailableUnstake;
        uint256 cachePeriod;
        uint256 currentPeriodClaimed;
    }

    mapping (address => UserProfile) internal _userProfile;

    address public LX;
    address public LXP;

    event RewardShared(address user, uint256 amount);
    event Stake(address user, uint256 amount);
    event Unstake(address user, uint256 amount);
    event Claim(address user, uint256 amount);
    event GlobalCacheUpdated(address indexed caller, uint256 indexed previousPeriod, uint256 indexed currentPeriod);
    event UserCacheUpdated(address indexed caller, address indexed user, uint256 previousPeriod, uint256 indexed currentPeriod);
    event UserPeriodPayout(address indexed caller, address indexed user, uint256 indexed period, uint256 payout);

    function initialize(address _LX, address _LXP) external initializer {
        LX = _LX;
        LXP = _LXP;
    }

    function getCurrentPeriodIndex() view public returns(uint256) {
        return (block.timestamp - FIRST_MONDAY) / WINDOW;
    }

    function timeFromPeriodStart() view public returns(uint256) {
        return (block.timestamp - FIRST_MONDAY) % WINDOW;
    }

    function updateGlobalCachePeriod() public {
        uint256 current = getCurrentPeriodIndex();
        if (current > globalCachePeriod) {
            emit GlobalCacheUpdated(msg.sender, globalCachePeriod, current);
            for (uint256 i = globalCachePeriod+1; i < current; i++) {
                periodTotalStaked[i] = totalNextPeriodStakeAmount;
            }
            globalCachePeriod = current;
            totalCurrentPeriodStakeAmount = totalNextPeriodStakeAmount;
        }
    }

    function updateUserCachePeriod(address user) public {  // todo maybe nonReentrant?
        uint256 current = getCurrentPeriodIndex();
        UserProfile storage profile = _userProfile[user];
        if (current > profile.cachePeriod) {
            emit UserCacheUpdated(msg.sender, user, profile.cachePeriod, current);
            uint256 reward;
            for (uint256 i = profile.cachePeriod; i < current; i++) {
                uint256 iReward = periodTotalReward[i] * profile.currentPeriodStake / periodTotalStaked[i] - profile.currentPeriodClaimed;
                profile.currentPeriodClaimed += iReward;
                if (iReward > 0) {
                    reward += iReward;
                    emit UserPeriodPayout(msg.sender, user, i, iReward);
                }
                profile.cachePeriod = i+1;
                profile.currentPeriodStake = profile.nextPeriodStake;
                profile.currentPeriodAvailableUnstake = profile.nextPeriodAvailableUnstake;
                profile.currentPeriodClaimed = 0;
            }
            if (reward > 0) {
                IERC20(LX).safeTransfer(user, reward);
            }
        }
    }


    /// @notice Tokens are added every two weeks.
    ///   Users must wait until beginning of a new two-week period for tokens to stake.
    function stake(uint256 amount) external nonReentrant {
        updateGlobalCachePeriod();
        updateUserCachePeriod(msg.sender);
        UserProfile storage profile = _userProfile[msg.sender];
        profile.nextPeriodStake += amount;
        emit Stake(msg.sender, amount);
        IERC20(LX).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(LXP).safeTransfer(msg.sender, amount);
    }

    /// @notice The contract needs to keep track of users’ running balance from delegation cycle to
    ///   delegation cycle and users need to be able to withdraw from just this yield balance without
    ///   removing themselves from the delegation.
    ///   They also need to be able to read this balance(UI showing balance on staking page)
    function getPossibleUnstakeAmountOfUserInNextPeriod(address user) public returns(uint256) {
        updateGlobalCachePeriod();
        updateUserCachePeriod(user);
        return _userProfile[user].nextPeriodStake - _userProfile[user].nextPeriodAvailableUnstake;
    }

    function claimToUnstakeInNextPeriod(uint256 amount) public {  //todo nonReentrant ??
        require(amount <= IERC20(LXP).balanceOf(msg.sender), "NOT_ENOUGH_LXP");
        uint256 possibleUnstakeAmount = getPossibleUnstakeAmountOfUserInNextPeriod(msg.sender);
        if (possibleUnstakeAmount > 0) {
            _userProfile[msg.sender].nextPeriodAvailableUnstake += amount;
            _userProfile[msg.sender].nextPeriodStake -= amount;
            emit Claim(msg.sender, amount);
            IERC20(LXP).safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    /// @notice When user decides to withdraw, they do not receive tokens until end of two-week delegation cycle,
    ///   but they still need synthetic tokens in wallet to burn to contract.
    function unstake(uint256 amount) external nonReentrant {
        updateGlobalCachePeriod();
        updateUserCachePeriod(msg.sender);
        _userProfile[msg.sender].currentPeriodAvailableUnstake -= amount;
        _userProfile[msg.sender].nextPeriodAvailableUnstake -= amount;
        emit Unstake(msg.sender, amount);
        IERC20(LX).safeTransfer(msg.sender, amount);
    }

    /// @dev Contract also needs ability to receive yield and claim that yield based on share of contract.
    function shareReward(uint256 amount) external nonReentrant {
        updateGlobalCachePeriod();
        IERC20(LX).safeTransferFrom(msg.sender, address(this), amount);
        periodTotalReward[getCurrentPeriodIndex()] += amount;
    }

    function getRevision() public returns(uint256) {
        return 1;
    }
}