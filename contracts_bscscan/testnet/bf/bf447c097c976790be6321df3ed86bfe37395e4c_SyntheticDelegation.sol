// SPDX-License-Identifier: unlicensed
pragma solidity ^0.8.0;

/*
The delegation staking smart contract.
The principle of the Synthetic Delegation Contract is quite simple.
User is able to stake the LNCHX tokens in the smart contract in exchange for the LNCHXP tokens.
The user will then be rewarded yields in bi-weekly cycles in LNCHX tokens,
deposited in the smart contract by a centralised authority.

The smart contract shall have a constructor that specifies the addresses of both lnchx and lnchxp token smart contracts.
The smart contract shall be upgradable through Proxy,
so the owner of the smart contract has an option to upgrade it in order to fix possible issues.

The contract will own the totalSupply of the LNCHXP tokens, they will be exchanged for LNCHX at 1:1 ratio at staking,
and received back by the contract on unstaking. So prior to making any staking transaction a transfer
the of totalSupply of the LNCHXP tokens to the synthetic contract shall be made.

In order to stake into smart contract the user will first call the “approve” method of the LNCHX token smart contract,
and then this method of the Synthetic Delegation Contract:

function stake(amount)

The previous “approve” call transaction should have been confirmed by now and should have been called for
the same amount of tokens.

As stake is called and LNCHX is transferred from the caller’s address the same amount of LNCHXP tokens
are transferred to the caller’s address from the synthetic delegation contract.

As the stake is performed the smart contract remembers the total amount staked by user and
the starting cycle (next biweekly cycle) the yield should be rewarded from.
No new stakes can be added by the same address until all yields from previous periods are claimed by the staker.

The stakes receives no yields from current 2 week cycle. Even if he posts the stake in the first day of the cycle.
The yields will start next cycle for him.

Anybody may deposit the bi-weekly Rewards and assign a cycle this reward should be applied to.
The reward may be assigned to current bi-weekly cycle too.

The following method shall be called when the rewards are deposited into the contract:
function shareReward(amount, cycle).
The “amount” is specified in LNCHX tokens, and the “cycle” shall be the cycle’s
index number that identifies the cycle this reward should be assigned to.
Prior to depositing the LNCHX tokens the operator who makes the reward deposit shall call the approve method of the
LNCHX token contract, allowing the smart contract to withdraw the same amount of from the operator’s wallet.
There should be ability to call this method more than once for the same cycle, so the rewards are added up.

The user may claim pending rewards for past cycles where she participated.
todo: ??? In order to save gas costs, the contract is designed to avoid large for loops.
One solution that was accepted by the team was that a new staking deposit can not be made
until all claimable rewards for the previous cycles have all been claimed.

The claiming of the rewards are done by calling this smart contract method:
function claim().

If there are rewards claimable by the user rewards for all previous cycles will be claimed in one call.
They will be transferred to the user in the same transaction.
The rewards for current cycle can not be claimed,
the user will need to wait for the end of the current cycle to be able to claim the reward.

todo: ??? when to allow reward for period index

The rewards claimable for an address can be retrieved via:
todo: claimableAmountOfUser(address)
The contract is also to have other view methods:
todo: totalTokensStaked()
Also a method to get current cycle index:
todo: getCurrentCycle()
And a method that returns rewards for a cycle.
todo: cycleTotalRewards(cycle)
todo: cycleRewardsOfUser(cycle, address)
On to the unstaking.
The unsticking is done in 2 transactions method calls:
todo: requestUnstake(amount)
This method will require the same amount of LNCHXP previously unlocked (approved)
for the contract to transfer from the caller’s address.
Once called, the LNCHXP tokens are transferred back to the Synthetic contract,
and the same amount of LNCHX tokens is reserved for withdrawal at the end of the current staking period.

Once the request is submitted, the user will not be awarded any yields beyond the current period.
She will need to complete the unstake, and then stake again to be able to get new rewards.
At any time after the cycle end the user can complete the Unstaking Request.
This step should be done by one method call without parameters:

unstake()
This method shall fail if there are any pending reward claims by address. (claimableAmountOfUser(address) > 0)
The frontend must know of any pending withdrawals by calling this method:
pendingUnstakeRequests(address)
*/

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
    uint256 constant WINDOW = 14 * 24 * 3600;   // 2 weeks
    uint256 constant ACTION_WINDOW = 1 * 3600;  // 1 hour to stake/unstake

//    struct WithdrawOrder {
//        uint256 amount;
//        uint256 lockedTill;
//    }
//    mapping (address => mapping(uint256 => WithdrawOrder)) internal _userWithdrawOrder;

    uint256 public totalCurrentPeriodStakeAmount;
    uint256 public totalNextPeriodStakeAmount;
    uint256 public globalCachePeriod;
    mapping (uint256 => uint256) public periodTotalReward;
    mapping (uint256 => uint256) public periodTotalStaked;
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

    function getUserTotalStake(address user) external view returns(uint256) {
        require(getCurrentPeriodIndex() == _userProfile[user].cachePeriod, "update cache please");
        require(getCurrentPeriodIndex() == globalCachePeriod, "update cache please");
        return _userProfile[user].nextPeriodStake;
    }

    function getUserCurrentPeriodAvailableUnstake(address user) external view returns(uint256) {
        require(getCurrentPeriodIndex() == _userProfile[user].cachePeriod, "update cache please");
        require(getCurrentPeriodIndex() == globalCachePeriod, "update cache please");
        return _userProfile[user].currentPeriodAvailableUnstake;
    }

    function getUserNextPeriodAvailableUnstake(address user) external view returns(uint256) {
        require(getCurrentPeriodIndex() == _userProfile[user].cachePeriod, "update cache please");
        require(getCurrentPeriodIndex() == globalCachePeriod, "update cache please");
        return _userProfile[user].nextPeriodAvailableUnstake;
    }

    function getUserCachePeriod(address user) external view returns(uint256) {
        return _userProfile[user].cachePeriod;
    }

    function getGlobalCachePeriod() external view returns(uint256) {
        return globalCachePeriod;
    }

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
        if (globalCachePeriod == 0) {
            emit GlobalCacheUpdated(msg.sender, globalCachePeriod, current);
            globalCachePeriod = current;
            return;
        }
        if (current > globalCachePeriod) {
            emit GlobalCacheUpdated(msg.sender, globalCachePeriod, current);
            for (uint256 i = globalCachePeriod+1; i <= current; i++) {
                periodTotalStaked[i] = totalNextPeriodStakeAmount;
            }
            globalCachePeriod = current;
            totalCurrentPeriodStakeAmount = totalNextPeriodStakeAmount;
        }
    }

    // todo
//    function updateGlobalCachePeriodLimited(uint256 maxIterations) public {
//        uint256 current = getCurrentPeriodIndex();
//        if (current > globalCachePeriod) {
//            emit GlobalCacheUpdated(msg.sender, globalCachePeriod, current);
//            for (uint256 i = globalCachePeriod+1; i < current; i++) {
//                periodTotalStaked[i] = totalNextPeriodStakeAmount;
//            }
//            globalCachePeriod = current;
//            totalCurrentPeriodStakeAmount = totalNextPeriodStakeAmount;
//        }
//    }

    function updateUserCachePeriod(address user) public {  // todo maybe nonReentrant?
        uint256 current = getCurrentPeriodIndex();
        UserProfile storage profile = _userProfile[user];
        if (profile.cachePeriod == 0) {
            emit UserCacheUpdated(msg.sender, user, profile.cachePeriod, current);
            profile.cachePeriod = current;
            return;
        }
        if (current > profile.cachePeriod) {
            emit UserCacheUpdated(msg.sender, user, profile.cachePeriod, current);
            uint256 reward;
            for (uint256 i = profile.cachePeriod; i < current; i++) {
                if (periodTotalStaked[i] > 0) {
                    uint256 iReward = periodTotalReward[i] * profile.currentPeriodStake / periodTotalStaked[i] -
                    profile.currentPeriodClaimed;
                    profile.currentPeriodClaimed += iReward;
                    if (iReward > 0) {
                        reward += iReward;
                        emit UserPeriodPayout(msg.sender, user, i, iReward);
                    }
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

    function claimReward() external nonReentrant {
        updateGlobalCachePeriod();  // todo limit for loop here
        updateUserCachePeriod(msg.sender);
    }

    /// @notice Tokens are added every two weeks.
    ///   Users must wait until beginning of a new two-week period for tokens to stake.
    function stake(uint256 amount) external nonReentrant {
        require(IERC20(LXP).balanceOf(address(this)) >= amount, "not enough LXP on the contract address");
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
        require(_userProfile[msg.sender].currentPeriodAvailableUnstake >= amount, "not enough unfrozen LXP in current period");
        // note that always nextPeriodAvailableUnstake >= currentPeriodAvailableUnstake, so more require not need
        _userProfile[msg.sender].currentPeriodAvailableUnstake -= amount;
        _userProfile[msg.sender].nextPeriodAvailableUnstake -= amount;
        emit Unstake(msg.sender, amount);
        IERC20(LX).safeTransfer(msg.sender, amount);
    }

    /// @dev Contract also needs ability to receive yield and claim that yield based on share of contract.
    function shareReward(uint256 amount, uint256 cycle) external nonReentrant {  //todo discuss
        updateGlobalCachePeriod();
        require(cycle >= getCurrentPeriodIndex(), "reward for past cycle");  // todo: discuss == current
        IERC20(LX).safeTransferFrom(msg.sender, address(this), amount);
        periodTotalReward[cycle] += amount;
    }

    function getRevision() pure public returns(uint256) {
        return 2;
    }
}