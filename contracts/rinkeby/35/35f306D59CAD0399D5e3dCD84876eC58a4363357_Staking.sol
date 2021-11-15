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

    struct StakingData {
        uint256 depositedTokens; // deposited tokens amount
        uint256 depositedLiquidity; // deposited lp amount
        uint256 currentTokens; // current staked tokens amount
        uint256 currentLiquidity; // current staked LP tokens amount
        uint256 currentSuperPool; // current Super token stake pool
        uint256 currentSuperLpPool; // current Super LP stake pool
        uint256 lastEvent; // last recalculation event timestamp
        uint256 totalRewards; // current total rewards sent by recalculation events
        uint256 totalClaimed; // current total tokens claimed
        uint256 totalFees; // current total tokens from fees given to stakers
    }

    StakingData private _data;

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
    string internal constant ERR_SUPER_STAKER = "Already super staker";
    string internal constant ERR_TRANSFER = "ERC20 transfer error";
    string internal constant ERR_TOO_SOON = "Too soon";

    // stake struct
    struct Stake {
        uint256 startTime; // stake created at timestamp
        uint256 superStakerPossibleAt; // timestamp after which super staker status can be claimed
        bool isSuperStaker; // true = user is super staker
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
    event Recalculation(uint256 timestamp, uint256 reward, uint256 lpReward);

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
        _data.lastEvent = nextEvent;
        recalculationPeriod = period;
        TIME_TO_SUPER = timeToSuper;
        TIME_TO_UNSTAKE = unstakeDelay;
    }

    function depositedTokens() external view returns (uint256) {
        return _data.depositedTokens;
    }

    function depositedLiquidity() external view returns (uint256) {
        return _data.depositedLiquidity;
    }

    function currentTokens() external view returns (uint256) {
        return _data.currentTokens;
    }

    function currentLiquidity() external view returns (uint256) {
        return _data.currentLiquidity;
    }

    function currentSuperPool() external view returns (uint256) {
        return _data.currentSuperPool;
    }

    function currentSuperLpPool() external view returns (uint256) {
        return _data.currentSuperLpPool;
    }

    function lastEvent() external view returns (uint256) {
        return _data.lastEvent;
    }

    function totalRewards() external view returns (uint256) {
        return _data.totalRewards;
    }

    function totalClaimed() external view returns (uint256) {
        return _data.totalClaimed;
    }

    function totalFees() external view returns (uint256) {
        return _data.totalFees;
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
        uint256 next = _data.lastEvent + recalculationPeriod;
        require(time > next, ERR_TOO_SOON);

        uint256 reward = tokenReward + lpReward;

        // pull tokens
        success = _transferFrom(tokenAddress, msg.sender, address(this), reward);

        unchecked {
            _data.lastEvent += recalculationPeriod;
            _data.totalRewards += reward;
        }

        uint256 contractBalance = _balance(tokenAddress, address(this));
        uint256 feesCollected = contractBalance - _data.depositedTokens - (_data.totalRewards + _data.totalFees - _data.totalClaimed);
        _data.totalFees += feesCollected;

        Event memory r;
        r.timestamp = next;

        uint256 superRewards;
        unchecked {
            superRewards = feesCollected / 2;
        }

        if (_data.currentSuperPool == 0) {
            _accumulatedSuperTokenPoolRewards += superRewards;
        } else {
            r.superTokenRewards = superRewards + _accumulatedSuperTokenPoolRewards;
            delete _accumulatedSuperTokenPoolRewards;
        }

        if (_data.currentSuperLpPool == 0) {
            _accumulatedSuperLpPoolRewards += superRewards;
        } else {
            r.superLpRewards = superRewards + _accumulatedSuperLpPoolRewards;
            delete _accumulatedSuperLpPoolRewards;
        }

        r.tokens = _data.currentTokens;
        r.lpStaked = _data.currentLiquidity;

        if (_data.currentTokens == 0) {
            _accumulatedTokenPoolRewards += tokenReward;
        } else {
            r.tokenRewards = tokenReward + _accumulatedTokenPoolRewards;
            delete _accumulatedTokenPoolRewards;
        }

        if (_data.currentLiquidity == 0) {
            _accumulatedLpPoolRewards += lpReward;
        } else {
            r.lpRewards = lpReward + _accumulatedLpPoolRewards;
            delete _accumulatedLpPoolRewards;
        }

        // copy SS pool data, it is updated on setSuper, add and remove stake
        r.superLp = _data.currentSuperLpPool;
        r.superTokens = _data.currentSuperPool;
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
    @notice Add tokens to staking using permit to set allowance
    @param amount of tokens to stake
    @param deadline of permit signature
    @param approveMax allowance for the token
    */
    function addTokenStakeWithPermit(
        uint256 amount,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint256 value = approveMax ? type(uint256).max : amount;
        IERC20(tokenAddress).permit(msg.sender, address(this), value, deadline, v, r, s);
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

    /**
    @notice Add liquidity tokens for staking
    @param amount of tokens to stake
    @param deadline of permit signature
    @param approveMax allowance for the token
    */
    function addLiquidityStakeWithPermit(
        uint256 amount,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        uint256 value = approveMax ? type(uint256).max : amount;
        IERC20(liquidityAddress).permit(msg.sender, address(this), value, deadline, v, r, s);
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
            s.superStakerPossibleAt = s.startTime + TIME_TO_SUPER;
            // will be counted from next one
            s.lastEvent = events.length;
        } else {
            _updateRewardToDate(s, lp);
            if (s.lastSuperEvent > 0) {
                if (lp) {
                    _data.currentSuperLpPool += amount;
                } else {
                    _data.currentSuperPool += amount;
                }
            }
        }
        // update staked amounts
        s.tokens += amount;
        if (lp) {
            _data.currentLiquidity += amount;
            _data.depositedLiquidity += amount;
        } else {
            _data.currentTokens += amount;
            _data.depositedTokens += amount;
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

    function _getRewardToDate(Stake storage s, bool lp) internal view returns (uint256 reward) {
        uint256 ts = s.tokens;
        if (ts == 0 || s.isWithdrawing) return 0; //nothing to do
        uint256 lr = s.lastEvent;
        uint256 len = events.length;
        uint256 sup = s.lastSuperEvent;
        for (lr; lr < len; lr++) {
            Event memory r = events[lr];
            uint256 pool = lp ? r.lpStaked : r.tokens;
            uint256 stakeReward = lp ? r.lpRewards : r.tokenRewards;
            uint256 pct = (ts * 1 ether) / pool; // TODO: what if pool=0? pool can't be 0 if we staked in it
            reward += (pct * stakeReward) / 1 ether;
            if (sup != 0 && sup <= lr) {
                pool = lp ? r.superLp : r.superTokens;
                stakeReward = lp ? r.superLpRewards : r.superTokenRewards;
                pct = (ts * 1 ether) / pool; // TODO: possible to pool=0? pool can't be 0 if we staked in it
                reward += (pct * stakeReward) / 1 ether;
            }
        }
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
                _data.currentSuperPool += reward;
            }
            t.tokens += reward;
        } else {
            //create token stake
            t.lastEvent = events.length;
            t.startTime = block.timestamp;
            t.superStakerPossibleAt = t.startTime + TIME_TO_SUPER;
            t.tokens = reward;
        }
        _data.totalClaimed += reward;
        _data.depositedTokens += reward;
        _data.currentTokens += reward;
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
                _data.currentSuperLpPool -= amt;
            } else {
                _data.currentSuperPool -= amt;
            }
        }
        // update global stake pool amounts
        if (lp) {
            _data.currentLiquidity -= s.tokens;
        } else {
            _data.currentTokens -= s.tokens;
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
            _data.depositedTokens -= tokenStake[msg.sender].tokens;
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
        _data.totalClaimed += s.tokensEarned;
        tokens += s.tokensEarned;
        if (lpTokens > 0) {
            _data.depositedLiquidity -= lpTokens;
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
        uint256 rewardTokens; // SNP tokens to be sent back
        if (l.isWithdrawing) {
            uint256 lpTokens = (l.tokens * 9) / 10; //remaining tokens are on contract
            _data.totalClaimed += l.tokensEarned;
            rewardTokens += l.tokensEarned;
            delete liquidityStake[msg.sender];
            if (lpTokens > 0) {
                _data.depositedLiquidity -= l.tokens;
                // sanity check, it should be always true there
                emit StakeLiquidityRemoved(msg.sender, lpTokens);
                require(_transfer(liquidityAddress, msg.sender, lpTokens), ERR_TRANSFER);
            }
        }
        if (t.isWithdrawing) {
            uint256 toUnstake = (t.tokens * 9) / 10; // fee goes to Super Stakers
            if (toUnstake > 0) {
                _data.depositedTokens -= t.tokens;
                // also always should be true
                emit StakeRemoved(msg.sender, toUnstake);
            }
            _data.totalClaimed += t.tokensEarned;
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
            _data.totalClaimed += reward;
            require(_transfer(tokenAddress, to, reward), ERR_TRANSFER);
            emit Claimed(from, reward);
        }
    }

    function claimable(address user) external view returns (uint256 token, uint256 lp) {
        Stake storage t = tokenStake[user];
        Stake storage l = liquidityStake[user];
        token = _getRewardToDate(t, false);
        lp = _getRewardToDate(l, true);
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
        if (t.superStakerPossibleAt < block.timestamp && !t.isSuperStaker && !t.isWithdrawing) token = true;
        if (l.superStakerPossibleAt < block.timestamp && !l.isSuperStaker && !l.isWithdrawing) lp = true;
    }

    /**
    Set Super Staker status if possible
    This way it can be done later - but before planned claim
    @param s stake struct from storage
    */
    function _setSuper(Stake storage s, bool lp) internal {
        require(!s.isWithdrawing, ERR_WITHDRAWING);
        require(!s.isSuperStaker, ERR_SUPER_STAKER);
        if (s.superStakerPossibleAt < block.timestamp) {
            _updateRewardToDate(s, lp);
            // to mitigate user specially call this later, after adding more tokens
            // we set his status on current recalculation, even if he gain status earlier
            s.lastSuperEvent = events.length; // active from next recalculation event
            s.isSuperStaker = true;
            // update recalculation pool
            if (lp) {
                _data.currentSuperLpPool += s.tokens;
            } else {
                _data.currentSuperPool += s.tokens;
            }
        }
    }

    /**
    Get planned timestamp of next recalculation event
    @return timestamp of next recalculation
     */
    function getNextEventTime() external view returns (uint256) {
        return _data.lastEvent + recalculationPeriod;
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
    function decimals() external view returns (uint8);
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
    function transferWithPermit(address target, address to, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
}

