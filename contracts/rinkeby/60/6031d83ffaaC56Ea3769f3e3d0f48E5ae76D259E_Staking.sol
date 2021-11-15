// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./interfaces/IERC20.sol";
import "./abstract/Ownable.sol";

contract Staking is Ownable {
    /// stake/reward token address
    address public immutable tokenAddress;
    /// LP stake token address
    address public immutable liquidityAddress;

    /// time between recalculation (7*24*60*60)
    uint256 public immutable recalculationPeriod;
    /// time to allow be Super Staker (30*24*60*60)
    uint256 public immutable TIME_TO_SUPER;
    /// time to wait for unstake (14*24*60*60)
    uint256 public immutable TIME_TO_UNSTAKE;

    // staking storage TODO: maybe one public struct would be cheaper? or private + getters?
    /// current staked tokens count
    uint256 public currentTokens;
    /// current staked LP tokens count
    uint256 public currentLiquidity;
    /// current Super token stake pool
    uint256 public currentSuperPool;
    /// current Super LP stake pool
    uint256 public currentSuperLpPool;
    /// last recalculation event timestamp
    uint256 public lastEvent;
    /// current total rewards sent by recalculation events
    uint256 public totalRewards;
    /// current total tokens claimed
    uint256 public totalClaimed;
    /// current total tokens from fees given to stakers
    uint256 public totalFees;

    /// accumulated token stake pool rewards
    uint256 private _accumulatedTokenPoolRewards;
    /// accumulated LP stake pool rewards
    uint256 private _accumulatedLpPoolRewards;
    /// accumulated super token stake pool rewards
    uint256 private _accumulatedSuperTokenPoolRewards;
    /// accumulated super LP stake pool rewards
    uint256 private _accumulatedSuperLpPoolRewards;

    // error constants
    string internal constant ERR_WITHDRAWING = "Can not when withdrawing";
    string internal constant ERR_TRANSFER = "ERC20 transfer error";
    string internal constant ERR_TOO_SOON = "Too soon";

    // stake struct
    struct Stake {
        uint256 startTime; // stake created at timestamp
        uint256 tokens; // total tokens staked by user
        uint256 tokensEarned; // current not-claimed earings
        uint256 lastEvent; // index of last recalculation event counted
        uint256 lastSuperEvent; // recalculation index when holder become Super Staker
        uint256 withdrawalPossibleAt; // timestamp after which stake can be removed
        bool isWithdrawing; // true = user call to remove stake
    }
    // each holder have one stake
    /// Token stakes storage
    mapping(address => Stake) public tokenStake;
    /// LP token stakes storage
    mapping(address => Stake) public liquidityStake;

    // weekly recalculation event
    struct Event {
        uint256 timestamp; // recalculation timestamp
        uint256 tokens; // total number of tokens staked
        uint256 lpStaked; // total number of LP tokens staked
        uint256 superTokens; // tokens staked by Super Stakers
        uint256 superLp; // LP tokens staked by Super Stakers
        uint256 superTokenRewards; // rewards for token stakers
        uint256 superLpRewards; // rewards for LP stakers
        uint256 lpRewards; // tokens added as rewards for LP stakers
        uint256 tokenRewards; // tokens added as reward for token stakers
    }
    /// recalculation events storage
    Event[] public events;

    // events
    event Claimed(address indexed user, uint256 amount);
    event StakeAdded(address indexed user, uint256 amount);
    event StakeLiquidityAdded(address indexed user, uint256 amount);
    event StakeRemoveRequested(address indexed user);
    event StakeLiquidityRemoveRequested(address indexed user);
    event StakeRemoved(address indexed user, uint256 amount);
    event StakeLiquidityRemoved(address indexed user, uint256 amount);
    event Recalculation(uint256 timestamp, uint256 reward, uint256 LpReward);

    constructor(
        address token,
        address liquidity,
        uint256 nextEvent,
        uint256 period,
        uint256 timeToSuper,
        uint256 unstakeDelay
    ) {
        tokenAddress = token;
        liquidityAddress = liquidity;
        lastEvent = nextEvent;
        recalculationPeriod = period;
        TIME_TO_SUPER = timeToSuper;
        TIME_TO_UNSTAKE = unstakeDelay;
    }

    /**
    @notice weekly trigger to recalculate stake rewards
    @notice contract will pull tokens from sender, need approval first!
    @notice also split reward from fees for Super Stakers
    @param tokenReward number of reward tokens for token stake
    @param lpReward number of reward tokens for liquidity stake
    @return success true if success (or revert)
     */
    function triggerEvent(uint256 tokenReward, uint256 lpReward) external onlyOwner returns (bool success) {
        uint256 time = block.timestamp;
        uint256 next = lastEvent + recalculationPeriod;
        require(time > next, ERR_TOO_SOON);

        uint256 reward = tokenReward + lpReward;

        // pull tokens
        success = _transferFrom(tokenAddress, msg.sender, address(this), reward);

        unchecked {
            lastEvent += recalculationPeriod;

            totalRewards += reward;
        }

        uint256 contractBalance = _balance(tokenAddress, address(this));
        uint256 feesCollected = contractBalance - currentTokens - (totalRewards + totalFees - totalClaimed);
        totalFees += feesCollected;

        Event memory r;
        r.timestamp = next;

        uint256 superRewards;
        unchecked {
            superRewards = feesCollected / 2;
        }

        if (currentSuperPool == 0) {
            _accumulatedSuperTokenPoolRewards += superRewards;
        } else {
            r.superTokenRewards = superRewards + _accumulatedSuperTokenPoolRewards;
            delete _accumulatedSuperTokenPoolRewards;
        }

        if (currentSuperLpPool == 0) {
            _accumulatedSuperLpPoolRewards += superRewards;
        } else {
            r.superLpRewards = superRewards + _accumulatedSuperLpPoolRewards;
            delete _accumulatedSuperLpPoolRewards;
        }

        r.tokens = currentTokens;
        r.lpStaked = currentLiquidity;

        if (currentTokens == 0) {
            _accumulatedTokenPoolRewards += tokenReward;
        } else {
            r.tokenRewards = tokenReward + _accumulatedTokenPoolRewards;
            delete _accumulatedTokenPoolRewards;
        }

        if (currentLiquidity == 0) {
            _accumulatedLpPoolRewards += lpReward;
        } else {
            r.lpRewards = lpReward + _accumulatedLpPoolRewards;
            delete _accumulatedLpPoolRewards;
        }

        // copy SS pool data, it is updated on setSuper, add and remove stake
        r.superLp = currentSuperLpPool;
        r.superTokens = currentSuperPool;
        events.push(r);
        emit Recalculation(next, tokenReward, lpReward);
    }

    /**
    Add tokens for staking
    @param amount of tokens to stake
    */
    function addTokenStake(uint256 amount) external {
        _addStake(msg.sender, amount, false);
        emit StakeAdded(msg.sender, amount);
    }

    /**
    Add liquidity tokens for staking
    @param amount of tokens to stake
    */
    function addLiquidityStake(uint256 amount) external {
        _addStake(msg.sender, amount, true);
        emit StakeLiquidityAdded(msg.sender, amount);
    }

    // Internal add stake function
    function _addStake(
        address user,
        uint256 amount,
        bool lp
    ) internal {
        Stake storage s = lp ? liquidityStake[user] : tokenStake[user];
        require(!s.isWithdrawing, ERR_WITHDRAWING);
        address token = lp ? liquidityAddress : tokenAddress;
        if (s.startTime == 0) {
            // new stake
            s.startTime = block.timestamp;
            // will be counted from next one
            s.lastEvent = events.length;
        } else {
            _updateRewardToDate(s, lp);
            if (s.lastSuperEvent > 0) {
                if (lp) {
                    currentSuperLpPool += amount;
                } else {
                    currentSuperPool += amount;
                }
            }
        }
        // update staked amounts
        s.tokens += amount;
        if (lp) {
            currentLiquidity += amount;
        } else {
            currentTokens += amount;
        }
        require(_transferFrom(token, msg.sender, address(this), amount), ERR_TRANSFER);
    }

    /**
    Update tokensEarned in storage, move lastEvent to date
     */
    function _updateRewardToDate(Stake storage s, bool lp) internal {
        uint256 ts = s.tokens;
        if (ts == 0 || s.isWithdrawing) return; //nothing to do
        uint256 lr = s.lastEvent;
        uint256 len = events.length;
        uint256 sup = s.lastSuperEvent;
        uint256 user;
        for (lr; lr < len; lr++) {
            Event memory r = events[lr];
            uint256 pool = lp ? r.lpStaked : r.tokens;
            uint256 reward = lp ? r.lpRewards : r.tokenRewards;
            uint256 pct = (ts * 1 ether) / pool; // TODO: what if pool=0? pool can't be 0 if we staked in it
            user += (pct * reward) / 1 ether;
            if (sup != 0 && sup <= lr) {
                pool = lp ? r.superLp : r.superTokens;
                reward = lp ? r.superLpRewards : r.superTokenRewards;
                pct = (ts * 1 ether) / pool; // TODO: possible to pool=0? pool can't be 0 if we staked in it
                user += (pct * reward) / 1 ether;
            }
        }
        s.tokensEarned += user;
        s.lastEvent = lr; //TODO: needed? no need +-1?
        if (sup != 0) {
            s.lastSuperEvent = lr;
        } // update super staker start counter
    }

    /**
    Restake earned tokens and add to token stake (instead of claiming)
    If have LP stake but not token stake - token stake will be created.
    */
    function restake() external {
        Stake storage t = tokenStake[msg.sender];
        Stake storage l = liquidityStake[msg.sender];
        require(!t.isWithdrawing, ERR_WITHDRAWING);
        _updateRewardToDate(t, false);
        _updateRewardToDate(l, true);
        uint256 reward = t.tokensEarned + l.tokensEarned;
        require(reward > 0, "Nothing to restake");
        delete t.tokensEarned;
        delete l.tokensEarned;
        if (t.startTime > 0) {
            // update token stake
            if (t.lastSuperEvent > 0) {
                currentSuperPool += reward;
            }
            t.tokens += reward;
        } else {
            //create token stake
            t.lastEvent = events.length;
            t.startTime = block.timestamp;
            t.tokens = reward;
        }

        currentTokens += reward;
        emit StakeAdded(msg.sender, reward);
    }

    /**
    Request unstake tokens
    */
    function requestUnstake() external {
        _requestUnstake(tokenStake[msg.sender], false);
        emit StakeRemoveRequested(msg.sender);
    }

    /**
    Request unstake LP tokens
    */
    function requestUnstakeLp() external {
        _requestUnstake(liquidityStake[msg.sender], true);
        emit StakeLiquidityRemoveRequested(msg.sender);
    }

    /**
    Internal request unstake function
    @param s Stake storage to modify
    @param lp true=> it is LP stake
    */
    function _requestUnstake(Stake storage s, bool lp) internal {
        require(!s.isWithdrawing, ERR_WITHDRAWING);
        uint256 amt = s.tokens;
        require(amt > 0, "nothing staked");
        // count all tokens to date
        _updateRewardToDate(s, lp);

        //remove Super Stake
        if (s.lastSuperEvent > 0) {
            delete s.lastSuperEvent;
            if (lp) {
                currentSuperLpPool -= amt;
            } else {
                currentSuperPool -= amt;
            }
        }
        // update global stake pool amounts
        if (lp) {
            currentLiquidity -= s.tokens;
        } else {
            currentTokens -= s.tokens;
        }

        // set flags
        s.isWithdrawing = true;
        s.withdrawalPossibleAt = block.timestamp + TIME_TO_UNSTAKE;
    }

    /**
    Remove stake from both stakes (if possible)
    */
    function unstake() external {
        uint256 tokens;
        bool success;
        uint256 reward;
        (tokens, success) = _unstake(msg.sender, tokenStake[msg.sender], false);
        if (success) {
            emit StakeRemoved(msg.sender, tokenStake[msg.sender].tokens);
            delete tokenStake[msg.sender];
        }
        (reward, success) = _unstake(msg.sender, liquidityStake[msg.sender], true);
        if (success) {
            delete liquidityStake[msg.sender];
        }
        tokens += reward;
        if (tokens > 0) {
            require(_transfer(tokenAddress, msg.sender, tokens), ERR_TRANSFER);
        }
    }

    /**
    Internal unstake function, transfer out LP tokens, return number of stake/reward tokens
    @param user address of user to transfer tokens
    @param s Stake object
    @param lp true = LP stake
    @return tokens amount of stake/reward tokens
    @return bool true if success
     */
    function _unstake(
        address user,
        Stake storage s,
        bool lp
    ) internal returns (uint256 tokens, bool) {
        if (!s.isWithdrawing) return (tokens, false);
        if (s.withdrawalPossibleAt > block.timestamp) return (tokens, false);
        uint256 lpTokens;
        if (lp) {
            lpTokens = s.tokens;
        } else {
            tokens = s.tokens;
        }
        tokens += s.tokensEarned;
        if (lpTokens > 0) {
            require(_transfer(liquidityAddress, user, lpTokens), ERR_TRANSFER);
            emit StakeLiquidityRemoved(user, lpTokens);
        }
        return (tokens, true);
    }

    //
    // Emergency Unstake (with 10% fee)
    // Need request first
    //
    /**
    Unstake requested stake at any time accepting 10% penalty fee
    */
    function unstakeWithFee() external {
        Stake storage t = tokenStake[msg.sender];
        Stake storage l = liquidityStake[msg.sender];
        uint256 rewardTokens; // tokens to be sent back
        if (l.isWithdrawing) {
            uint256 lpTokens = (l.tokens * 9) / 10; //remaining tokens are on contract
            rewardTokens += l.tokensEarned;
            delete liquidityStake[msg.sender];
            if (lpTokens > 0) {
                // sanity check, it should be always true there
                emit StakeLiquidityRemoved(msg.sender, lpTokens);
                require(_transfer(liquidityAddress, msg.sender, lpTokens), ERR_TRANSFER);
            }
        }
        if (t.isWithdrawing) {
            uint256 toUnstake = (t.tokens * 9) / 10; // fee goes to Super Stakers
            if (toUnstake > 0) {
                // also always should be true
                emit StakeRemoved(msg.sender, toUnstake);
            }
            rewardTokens += (t.tokensEarned + toUnstake);
            delete tokenStake[msg.sender];
        }
        if (rewardTokens > 0) {
            require(_transfer(tokenAddress, msg.sender, rewardTokens), ERR_TRANSFER);
        }
    }

    /**
    Claim reward tokens
    */
    function claim() external {
        _claim(msg.sender, msg.sender);
    }

    /**
    Claim reward tokens to address
    @param dest address where claimed tokens should be sent
    */
    function claimTo(address dest) external {
        _claim(msg.sender, dest);
    }

    /**
    Claim reward tokens for someone (you pay fee, he get his tokens)
    @param user address of user you are paying fee for claim
    */

    // TODO: this function can be used for hostile behavior, user may don't want external addresses to claim for him as
    // his desired flow is to always restake. Don't know if we should remove it or leave it.
    function claimFor(address user) external {
        _claim(user, user);
    }

    // internal claim function, update user stakes and
    function _claim(address from, address to) internal {
        Stake storage t = tokenStake[from];
        Stake storage l = liquidityStake[from];
        _updateRewardToDate(t, false);
        _updateRewardToDate(l, true);
        uint256 reward = t.tokensEarned + l.tokensEarned;
        if (reward > 0) {
            delete t.tokensEarned;
            delete l.tokensEarned;
            totalClaimed += reward;
            require(_transfer(tokenAddress, to, reward), ERR_TRANSFER);
            emit Claimed(from, reward);
        }
    }

    /**
    Set Super Staker status for token pool stake if possible
    @param user address to process
    */
    function setSuperToken(address user) external {
        _setSuper(tokenStake[user], false);
    }

    /**
    Set Super Staker status for LP pool stake if possible
    @param user address to process
    */
    function setSuperLp(address user) external {
        _setSuper(liquidityStake[user], true);
    }

    /**
    Check that staker can set Super Staker status on token and LP stake
    @param user address to check
    @return token true if can set SS on token stake
    @return lp true if can set SS on LP stake
     */
    function canSetSuper(address user) external view returns (bool token, bool lp) {
        Stake memory t = tokenStake[user];
        Stake memory l = liquidityStake[user];
        uint256 tTime = t.startTime + TIME_TO_SUPER;
        uint256 lTime = l.startTime + TIME_TO_SUPER;
        if (tTime < block.timestamp && t.lastSuperEvent == 0 && !t.isWithdrawing) token = true;
        if (lTime < block.timestamp && l.lastSuperEvent == 0 && !l.isWithdrawing) lp = true;
    }

    /**
    Set Super Staker status if possible
    This way it can be done later - but before planned claim
    @param s stake struct from storage
    */
    function _setSuper(Stake storage s, bool lp) internal {
        require(!s.isWithdrawing, ERR_WITHDRAWING);
        uint256 timeSuper = s.startTime + TIME_TO_SUPER;
        if (timeSuper < block.timestamp) {
            _updateRewardToDate(s, lp);
            // to mitigate user specially call this later, after adding more tokens
            // we set his status on current recalculation, even if he gain status earlier
            s.lastSuperEvent = events.length; // active from next recalculation event
            // update recalculation pool
            if (lp) {
                currentSuperLpPool += s.tokens;
            } else {
                currentSuperPool += s.tokens;
            }
        }
    }

    /**
    Get planned timestamp of next recalculation event
    @return timestamp of next recalculation
     */
    function getNextEventTime() external view returns (uint256) {
        return lastEvent + recalculationPeriod;
    }

    //
    // internal ERC20 tools
    //

    function _balance(address token, address user) internal view returns (uint256) {
        return IERC20(token).balanceOf(user);
    }

    function _transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        return IERC20(token).transferFrom(from, to, amount);
    }

    function _transfer(
        address token,
        address to,
        uint256 amount
    ) internal returns (bool) {
        return IERC20(token).transfer(to, amount);
    }
}

// SPDX-License-Identifier: MIT

// Source: https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringOwnable.sol

pragma solidity ^0.8.6;

abstract contract OwnableData {
    address public owner;
    address public pendingOwner;
}

abstract contract Ownable is OwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    function transferOwnership(address newOwner, bool direct) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0), "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    // EIP 2612
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function nonces(address owner) external view returns (uint256);
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
}

