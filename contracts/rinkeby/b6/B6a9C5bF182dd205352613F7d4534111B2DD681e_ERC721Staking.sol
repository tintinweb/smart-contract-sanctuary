//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Libraries
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

// Contracts
import "./StakingBase.sol";

// Interfaces
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../tokens/IMintableERC20.sol";
import "./IERC721Staking.sol";

contract ERC721Staking is StakingBase, IERC721Staking, IERC721Receiver {
    using SafeERC20 for IERC20;

    constructor(
        address settingsAddress,
        address outputAddress,
        address feeReceiverAddress,
        address tokenValuatorAddress,
        uint256 outputAmountPerBlock,
        uint256 startBlockNumber,
        uint256 bonusEndBlockNumber
    )
        public
        StakingBase(
            settingsAddress,
            outputAddress,
            feeReceiverAddress,
            tokenValuatorAddress,
            outputAmountPerBlock,
            startBlockNumber,
            bonusEndBlockNumber
        )
    {}

    function stake(uint256 pid, uint256 id)
        external
        override
        existPool(pid)
        whenPlatformIsNotPaused()
        whenPoolIsNotPaused(pid)
        onlyEOAIfSet(msg.sender)
    {
        _stake(pid, id);
    }

    function stakeAll(uint256 pid, uint256[] calldata ids)
        external
        override
        existPool(pid)
        whenPlatformIsNotPaused()
        whenPoolIsNotPaused(pid)
        onlyEOAIfSet(msg.sender)
    {
        require(ids.length > 0, "TOKEN_IDS_REQUIRED");
        for (uint256 indexAt = 0; indexAt < ids.length; indexAt++) {
            _stake(pid, ids[indexAt]);
        }
    }

    function stakeAll(uint256 pid)
        external
        override
        existPool(pid)
        whenPlatformIsNotPaused()
        whenPoolIsNotPaused(pid)
        onlyEOAIfSet(msg.sender)
    {
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        uint256 userBalance = IERC721Enumerable(pool.token).balanceOf(msg.sender);
        require(userBalance > 0, "USER_HASNT_STAKED_TOKENS");
        for (uint256 indexAt = 0; indexAt < userBalance; indexAt++) {
            _stake(
                pid,
                IERC721Enumerable(pool.token).tokenOfOwnerByIndex(
                    msg.sender,
                    userBalance.sub(1).sub(indexAt)
                )
            );
        }
    }

    function unstake(uint256 pid, uint256 id)
        external
        override
        existPool(pid)
        whenPlatformIsNotPaused()
        whenPoolIsNotPaused(pid)
        onlyEOAIfSet(msg.sender)
    {
        _unstake(pid, id);
    }

    function unstakeAll(uint256 pid)
        external
        override
        existPool(pid)
        whenPlatformIsNotPaused()
        whenPoolIsNotPaused(pid)
        onlyEOAIfSet(msg.sender)
    {
        UserInfoLib.UserInfo storage user = userInfo[pid][msg.sender];
        uint256[] memory tokenIDs = user.getTokenIds();
        require(tokenIDs.length > 0, "USER_HASNT_STAKED_TOKENS");
        for (uint256 indexAt = 0; indexAt < tokenIDs.length; indexAt++) {
            _unstake(pid, tokenIDs[indexAt]);
        }
    }

    function unstakeAll(uint256 pid, uint256[] memory ids)
        external
        override
        existPool(pid)
        whenPlatformIsNotPaused()
        whenPoolIsNotPaused(pid)
        onlyEOAIfSet(msg.sender)
    {
        require(ids.length > 0, "TOKEN_IDS_REQUIRED");
        for (uint256 indexAt = 0; indexAt < ids.length; indexAt++) {
            _unstake(pid, ids[indexAt]);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        // It is implemented to support ERC721 transfers.
        return IERC721Receiver.onERC721Received.selector;
    }

    /* View Functions */

    /* Internal Funcctions  */

    function _afterUserStake(
        uint256 amountOrId,
        uint256 valuedAmountOrId,
        PoolInfoLib.PoolInfo storage pool,
        UserInfoLib.UserInfo storage user
    ) internal override {
        valuedAmountOrId;
        pool;
        user.addTokenId(amountOrId);
    }

    function _afterUserUnstake(
        uint256 amountOrId,
        uint256 valuedAmountOrId,
        PoolInfoLib.PoolInfo storage pool,
        UserInfoLib.UserInfo storage user
    ) internal override {
        valuedAmountOrId;
        pool;
        user.removeTokenId(amountOrId);
    }

    function _beforeUserUnstake(
        address account,
        uint256 amountOrId,
        uint256 valuedAmountOrId,
        PoolInfoLib.PoolInfo storage pool,
        UserInfoLib.UserInfo storage user
    ) internal view override {
        account;
        valuedAmountOrId;
        pool;
        user.requireHasTokenId(amountOrId);
    }

    function _safePoolTokenTransferFrom(
        address poolToken,
        address from,
        address to,
        uint256,
        uint256 amount
    ) internal override {
        IERC721(poolToken).safeTransferFrom(from, to, amount);
    }

    function _safePoolTokenTransfer(
        address poolToken,
        address from,
        address to,
        uint256,
        uint256 amount
    ) internal override {
        IERC721(poolToken).safeTransferFrom(from, to, amount);
    }

    function _getPoolTokenBalance(
        address poolToken,
        address account,
        uint256
    ) internal view override returns (uint256) {
        return IERC721(poolToken).balanceOf(account);
    }

    function _safeOutputTokenTransfer(
        address,
        address to,
        uint256,
        uint256 amount
    ) internal override {
        uint256 outputBalance = IERC20(output).balanceOf(address(this));
        if (amount > outputBalance) {
            IERC20(output).safeTransfer(to, outputBalance);
        } else {
            IERC20(output).safeTransfer(to, amount);
        }
    }

    function _safeOutputTokenMint(
        address,
        address to,
        uint256,
        uint256 amount
    ) internal override {
        IMintableERC20(output).mint(to, amount);
    }

    function _emergencyUnstakeAll(
        address userAccount,
        uint256 pid,
        PoolInfoLib.PoolInfo storage pool,
        UserInfoLib.UserInfo storage user
    ) internal override {
        user.emergencyUnstakeAll();

        uint256 totalTokens = user.getTotalTokens();
        require(totalTokens > 0, "USER_HASNT_STAKED_TOKENS");
        uint256 totalValuedAmountOrId;
        for (uint256 indexAt = 0; indexAt < totalTokens; indexAt++) {
            uint256 tokenId = user.getTokenIdAt(indexAt);
            uint256 valuedAmountOrId =
                ITokenValuator(tokenValuator).valuate(pool.token, userAccount, pid, tokenId);
            totalValuedAmountOrId = totalValuedAmountOrId.add(valuedAmountOrId);

            _safePoolTokenTransfer(pool.token, address(this), userAccount, pid, tokenId);
        }
        user.cleanTokenIDs();
        pool.totalDeposit = pool.totalDeposit.sub(totalValuedAmountOrId);
    }

    function _sweep(
        address token,
        uint256 id,
        address to
    ) internal override returns (uint256) {
        IERC721(token).safeTransferFrom(address(this), to, id);
        return id;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Libraries
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../libs/UserInfoLib.sol";
import "../libs/PoolInfoLib.sol";
import "@openzeppelin/contracts/utils/Address.sol";

// Contracts
import "../base/Base.sol";

// Interfaces
import "./IStaking.sol";
import "../valuators/ITokenValuator.sol";

abstract contract StakingBase is Base, IStaking {
    using Address for address;
    using SafeMath for uint256;
    using UserInfoLib for UserInfoLib.UserInfo;
    using PoolInfoLib for PoolInfoLib.PoolInfo;

    uint256 public constant AMOUNT_SCALE = 1e12;

    uint256 public constant PERCENTAGE_100 = 100;

    uint256 public constant DEFAULT_FEE = 10;

    address public immutable output;

    address public tokenValuator;

    address public feeReceiver;

    uint256 public outputPerBlock;

    uint256 public startBlock;

    // Block number where the bonus rewards end.
    uint256 public bonusEndBlock;

    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint;

    // Info of each pool.
    PoolInfoLib.PoolInfo[] public poolInfo;

    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfoLib.UserInfo)) internal userInfo;

    mapping(address => bool) public existsPool;

    constructor(
        address settingsAddress,
        address outputAddress,
        address feeReceiverAddress,
        address tokenValuatorAddress,
        uint256 outputAmountPerBlock,
        uint256 startBlockNumber,
        uint256 bonusEndBlockNumber
    ) public Base(settingsAddress) {
        require(outputAddress.isContract(), "OUTPUT_TOKEN_MUST_BE_CONTRACT");
        require(feeReceiverAddress != address(0x0), "FEE_RECEIVER_IS_REQUIRED");
        require(tokenValuatorAddress.isContract(), "VALUATOR_MUST_BE_CONTRACT");
        require(outputAmountPerBlock > 0, "OUTPUT_AMOUNT_GT_ZERO");
        require(startBlockNumber > 0, "START_BLOCK_GT_ZERO");
        require(startBlockNumber <= bonusEndBlockNumber, "START_LTE_BONUS_END");

        output = outputAddress;
        feeReceiver = feeReceiverAddress;
        tokenValuator = tokenValuatorAddress;
        outputPerBlock = outputAmountPerBlock;
        startBlock = startBlockNumber;
        bonusEndBlock = bonusEndBlockNumber;
    }

    // Add a new token to the pool. Can only be called by the owner.
    // @dev DO NOT add the same token more than once. Rewards will be messed up if you do. A validation was added to verify it.
    function addPool(
        uint256 allocationPoints,
        address token,
        bool withUpdate
    ) external override onlyConfigurator(msg.sender) {
        require(token.isContract(), "TOKEN_MUST_BE_CONTRACT");
        require(!existsPool[token], "POOL_FOR_TOKEN_ALREADY_EXISTS");
        ITokenValuator(tokenValuator).requireIsConfigured(token);
        if (withUpdate) {
            _massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(allocationPoints);
        poolInfo.push(
            PoolInfoLib.PoolInfo({
                totalDeposit: 0,
                token: token,
                allocPoint: allocationPoints,
                lastRewardBlock: lastRewardBlock,
                accTokenPerShare: 0,
                isPaused: false
            })
        );
        existsPool[token] = true;
        emit NewPoolAdded(token, poolInfo.length - 1, allocationPoints, totalAllocPoint);
    }

    function pausePool(uint256 pid) external override existPool(pid) onlyPauser(msg.sender) {
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        pool.requireIsNotPaused();
        pool.setIsPaused(true);

        emit PoolPauseSet(pid, true);
    }

    function unpausePool(uint256 pid) external override existPool(pid) onlyPauser(msg.sender) {
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        pool.requireIsPaused();
        pool.setIsPaused(false);

        emit PoolPauseSet(pid, false);
    }

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() external override {
        _massUpdatePools();
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyUnstakeAll(uint256 pid)
        external
        override
        existPool(pid)
        onlyEOAIfSet(msg.sender)
    {
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        UserInfoLib.UserInfo storage user = userInfo[pid][msg.sender];

        _emergencyUnstakeAll(msg.sender, pid, pool, user);

        emit EmergencyUnstake(msg.sender, pid);
    }

    function setOutputPerBlock(uint256 newOutputPerBlock)
        external
        override
        onlyConfigurator(msg.sender)
    {
        require(
            newOutputPerBlock > 0 && outputPerBlock != newOutputPerBlock,
            "NEW_OUTPUT_PER_BLOCK_INVALID"
        );
        uint256 oldOutputPerBlock = outputPerBlock;
        outputPerBlock = newOutputPerBlock;
        emit OutputPerBlockUpdated(oldOutputPerBlock, newOutputPerBlock);
    }

    function setFeeReceiver(address newFeeReceiver) external override onlyConfigurator(msg.sender) {
        require(
            newFeeReceiver != address(0x0) && newFeeReceiver != feeReceiver,
            "NEW_FEE_RECEIVER_INVALID"
        );
        address oldFeeReceiver = feeReceiver;
        feeReceiver = newFeeReceiver;
        emit FeeReceiverUpdated(oldFeeReceiver, newFeeReceiver);
    }

    function setTokenValuator(address newTokenValuator)
        external
        override
        onlyConfigurator(msg.sender)
    {
        require(newTokenValuator.isContract(), "TOKEN_VALUATOR_MUST_BE_CONTRACT");
        require(newTokenValuator != tokenValuator, "TOKEN_VALUATOR_MUST_BE_NEW");
        address oldTokenValutor = tokenValuator;
        tokenValuator = newTokenValuator;
        emit TokenValuatorUpdated(oldTokenValutor, newTokenValuator);
    }

    // Update the given pool's token allocation point. Can only be called by the owner.
    function setAllocPoint(
        uint256 pid,
        uint256 newAllocPoint,
        bool withUpdate
    ) external override onlyConfigurator(msg.sender) existPool(pid) {
        if (withUpdate) {
            _massUpdatePools();
        }
        uint256 oldAllocPoint = poolInfo[pid].allocPoint;
        totalAllocPoint = totalAllocPoint.sub(poolInfo[pid].allocPoint).add(newAllocPoint);
        poolInfo[pid].allocPoint = newAllocPoint;

        emit AllocPointsUpdated(pid, oldAllocPoint, newAllocPoint);
    }

    /* View Functions */
    function getTotalPools() external view override returns (uint256) {
        return poolInfo.length;
    }

    function getInfo()
        external
        view
        override
        returns (
            uint256 totalPools,
            uint256 outputPerBlockNumber,
            uint256 startBlockNumber,
            uint256 bonusEndBlockNumber,
            bool bonusFinished,
            uint256 totalAllocPoints
        )
    {
        return (
            poolInfo.length,
            outputPerBlock,
            startBlock,
            bonusEndBlock,
            bonusEndBlock < block.number,
            totalAllocPoint
        );
    }

    function getUserInfoForPool(uint256 pid, address account)
        external
        view
        override
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256[] memory tokenIDs
        )
    {
        amount = userInfo[pid][account].amount;
        rewardDebt = userInfo[pid][account].rewardDebt;
        tokenIDs = userInfo[pid][account].getTokenIds();
    }

    function getPoolInfoFor(uint256 pid)
        external
        view
        override
        returns (
            uint256 totalDeposit,
            address token,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accTokenPerShare,
            bool isPaused
        )
    {
        if (pid >= poolInfo.length) {
            return (0, address(0x0), 0, 0, 0, false);
        }
        totalDeposit = poolInfo[pid].totalDeposit;
        token = poolInfo[pid].token;
        allocPoint = poolInfo[pid].allocPoint;
        lastRewardBlock = poolInfo[pid].lastRewardBlock;
        accTokenPerShare = poolInfo[pid].accTokenPerShare;
        isPaused = poolInfo[pid].isPaused;
    }

    // Return reward multiplier over the given fromBlock to toBlock block.
    function getMultiplier(uint256 fromBlock, uint256 toBlock)
        external
        view
        override
        returns (uint256)
    {
        return _getMultiplier(fromBlock, toBlock);
    }

    function getPendingTokens(uint256 pid, address account)
        external
        view
        override
        returns (uint256)
    {
        return _getPendingTokens(pid, account);
    }

    function getAllPendingTokens(address account) external view override returns (uint256) {
        uint256 allPendingTokens = 0;
        for (uint256 index = 0; index < poolInfo.length; index += 1) {
            allPendingTokens = allPendingTokens.add(_getPendingTokens(index, account));
        }
        return allPendingTokens;
    }

    function getPools()
        external
        view
        override
        returns (
            address[] memory tokens,
            uint256[] memory totalDeposit,
            uint256[] memory allocPoints,
            uint256[] memory lastRewardBlocks,
            uint256[] memory accTokenPerShares,
            bool[] memory isPaused,
            uint256 totalPools
        )
    {
        totalPools = poolInfo.length;
        tokens = new address[](totalPools);
        totalDeposit = new uint256[](totalPools);
        allocPoints = new uint256[](totalPools);
        lastRewardBlocks = new uint256[](totalPools);
        accTokenPerShares = new uint256[](totalPools);
        isPaused = new bool[](totalPools);
        for (uint256 indexAt = 0; indexAt < totalPools; indexAt++) {
            tokens[indexAt] = poolInfo[indexAt].token;
            totalDeposit[indexAt] = poolInfo[indexAt].totalDeposit;
            allocPoints[indexAt] = poolInfo[indexAt].allocPoint;
            lastRewardBlocks[indexAt] = poolInfo[indexAt].lastRewardBlock;
            accTokenPerShares[indexAt] = poolInfo[indexAt].accTokenPerShare;
            isPaused[indexAt] = poolInfo[indexAt].isPaused;
        }
    }

    function sweep(address token, uint256 amountOrId) external override onlyOwner(msg.sender) {
        require(!existsPool[token], "TOKEN_POOL_EXIST");
        uint256 amountOrIdSweeped = _sweep(token, amountOrId, msg.sender);

        emit TokenSweeped(token, amountOrIdSweeped);
    }

    /* Internal Funcctions  */

    // Staking tokens for token allocation.
    function _stake(uint256 pid, uint256 amountOrId) internal {
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        UserInfoLib.UserInfo storage user = userInfo[pid][msg.sender];
        uint256 valuedAmountOrId =
            ITokenValuator(tokenValuator).valuate(pool.token, msg.sender, pid, amountOrId);

        _beforeUserStake(msg.sender, amountOrId, valuedAmountOrId, pool, user);
        _updatePool(pid);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accTokenPerShare).div(AMOUNT_SCALE).sub(user.rewardDebt);
            _safeOutputTokenTransfer(address(this), msg.sender, pid, pending);
        }

        _safePoolTokenTransferFrom(pool.token, msg.sender, address(this), pid, amountOrId);

        user.stake(valuedAmountOrId, pool.accTokenPerShare);
        pool.stake(valuedAmountOrId);

        _afterUserStake(amountOrId, valuedAmountOrId, pool, user);
        emit Staked(msg.sender, pid, amountOrId, valuedAmountOrId);
    }

    // Unstake tokens from this contract.
    function _unstake(uint256 pid, uint256 amountOrId) internal {
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        UserInfoLib.UserInfo storage user = userInfo[pid][msg.sender];

        uint256 valuedAmountOrId =
            ITokenValuator(tokenValuator).valuate(pool.token, msg.sender, pid, amountOrId);
        _beforeUserUnstake(msg.sender, amountOrId, valuedAmountOrId, pool, user);
        require(user.amount >= valuedAmountOrId, "VALUED_AMOUNT_EXCEEDS_STAKED");
        _updatePool(pid);
        uint256 pending =
            user.amount.mul(pool.accTokenPerShare).div(AMOUNT_SCALE).sub(user.rewardDebt);
        _safeOutputTokenTransfer(address(this), msg.sender, pid, pending);

        user.unstake(valuedAmountOrId, pool.accTokenPerShare);
        pool.unstake(valuedAmountOrId);
        _afterUserUnstake(amountOrId, valuedAmountOrId, pool, user);

        _safePoolTokenTransfer(pool.token, address(this), msg.sender, pid, amountOrId);

        emit Unstaked(msg.sender, pid, amountOrId, valuedAmountOrId);
    }

    function _beforeUserStake(
        address account,
        uint256 amountOrId,
        uint256 valuedAmountOrId,
        PoolInfoLib.PoolInfo storage pool,
        UserInfoLib.UserInfo storage user
    ) internal view virtual {}

    function _afterUserStake(
        uint256 amountOrId,
        uint256 valuedAmountOrId,
        PoolInfoLib.PoolInfo storage pool,
        UserInfoLib.UserInfo storage user
    ) internal virtual {}

    function _afterUserUnstake(
        uint256 amountOrId,
        uint256 valuedAmountOrId,
        PoolInfoLib.PoolInfo storage pool,
        UserInfoLib.UserInfo storage user
    ) internal virtual {}

    function _beforeUserUnstake(
        address account,
        uint256 amountOrId,
        uint256 valuedAmountOrId,
        PoolInfoLib.PoolInfo storage pool,
        UserInfoLib.UserInfo storage user
    ) internal view virtual {}

    function _emergencyUnstakeAll(
        address userAccount,
        uint256 pid,
        PoolInfoLib.PoolInfo storage pool,
        UserInfoLib.UserInfo storage user
    ) internal virtual {}

    function _safePoolTokenTransferFrom(
        address poolToken,
        address from,
        address to,
        uint256 pid,
        uint256 amountOrIId
    ) internal virtual;

    function _safePoolTokenTransfer(
        address poolToken,
        address from,
        address to,
        uint256 pid,
        uint256 amountOrIId
    ) internal virtual;

    function _getPoolTokenBalance(
        address poolToken,
        address account,
        uint256 pid
    ) internal view virtual returns (uint256);

    function _safeOutputTokenTransfer(
        address from,
        address to,
        uint256 pid,
        uint256 amount
    ) internal virtual;

    function _safeOutputTokenMint(
        address from,
        address to,
        uint256 pid,
        uint256 amount
    ) internal virtual;

    function _sweep(
        address token,
        uint256 amountOrId,
        address to
    ) internal virtual returns (uint256);

    // Update reward variables of the given pool to be up-to-date.
    function _updatePool(uint256 pid) internal {
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 tokenSupply = _getPoolTokenBalance(pool.token, address(this), pid);
        if (tokenSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = _getMultiplier(pool.lastRewardBlock, block.number);
        uint256 tokenReward =
            multiplier.mul(outputPerBlock).mul(pool.allocPoint).div(totalAllocPoint);

        _safeOutputTokenMint(
            address(this),
            feeReceiver,
            pid,
            tokenReward.mul(_getFee()).div(PERCENTAGE_100)
        );
        _safeOutputTokenMint(address(this), address(this), pid, tokenReward);

        pool.accTokenPerShare = pool.accTokenPerShare.add(
            tokenReward.mul(AMOUNT_SCALE).div(tokenSupply)
        );
        pool.lastRewardBlock = block.number;
    }

    function _massUpdatePools() internal {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            _updatePool(pid);
        }
    }

    function _getFee() internal view returns (uint256) {
        uint256 fee = _getPlatformSettingsValue(_settingsConsts().FEE());
        return fee == 0 ? DEFAULT_FEE : fee;
    }

    /**
        @return The bonus muliplier for early stakers.
     */
    function _getBonusMultiplier() internal view returns (uint256) {
        uint256 bonusMultiplier = _getPlatformSettingsValue(_settingsConsts().BONUS_MULTIPLIER());
        return bonusMultiplier == 0 ? 1 : bonusMultiplier;
    }

    // Return reward multiplier over the given fromBlock to toBlock block.
    function _getMultiplier(uint256 fromBlock, uint256 toBlock) internal view returns (uint256) {
        uint256 bonusMultiplier = _getBonusMultiplier();

        if (toBlock <= bonusEndBlock) {
            return toBlock.sub(fromBlock).mul(bonusMultiplier);
        } else if (fromBlock >= bonusEndBlock) {
            return toBlock.sub(fromBlock);
        } else {
            return
                bonusEndBlock.sub(fromBlock).mul(bonusMultiplier).add(toBlock.sub(bonusEndBlock));
        }
    }

    function _getPendingTokens(uint256 pid, address account) internal view returns (uint256) {
        if (pid >= poolInfo.length) {
            return 0;
        }
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        UserInfoLib.UserInfo storage user = userInfo[pid][account];
        uint256 accTokenPerShare = pool.accTokenPerShare;
        uint256 tokenSupply = _getPoolTokenBalance(pool.token, address(this), pid);

        if (block.number > pool.lastRewardBlock && tokenSupply != 0) {
            uint256 multiplier = _getMultiplier(pool.lastRewardBlock, block.number);
            uint256 tokenReward =
                multiplier.mul(outputPerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accTokenPerShare = accTokenPerShare.add(tokenReward.mul(AMOUNT_SCALE).div(tokenSupply));
        }
        return user.amount.mul(accTokenPerShare).div(AMOUNT_SCALE).sub(user.rewardDebt);
    }

    /** Modifiers */

    modifier onlyEOAIfSet(address account) {
        uint256 allowOnlyEOA = _getPlatformSettingsValue(_settingsConsts().ALLOW_ONLY_EOA());
        if (account.isContract()) {
            // allowOnlyEOA = 0 => Contracts and External Owned Accounts
            // allowOnlyEOA = 1 => Only External Owned Accounts (not contracts).
            require(allowOnlyEOA == 0, "ONLY_EOA_ALLOWED");
        }
        _;
    }

    modifier existPool(uint256 pid) {
        require(poolInfo.length > pid, "POOL_ID_DOESNT_EXIST");
        _;
    }

    modifier whenPoolIsNotPaused(uint256 pid) {
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        require(!pool.isPaused, "POOL_IS_PAUSED");
        _;
    }

    modifier whenPoolIsPaused(uint256 pid) {
        PoolInfoLib.PoolInfo storage pool = poolInfo[pid];
        require(pool.isPaused, "POOL_ISNT_PAUSED");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMintableERC20 is IERC20 {
    function mint(address account, uint256 amount) external;
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Libraries

// Contracts

// Interfaces
import "./IStaking.sol";

interface IERC721Staking is IStaking {
    function stakeAll(uint256 pid, uint256[] calldata ids) external;

    function stakeAll(uint256 pid) external;

    function unstakeAll(uint256 pid) external;

    function unstakeAll(uint256 pid, uint256[] memory ids) external;
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

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Libraries
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

library UserInfoLib {
    using EnumerableSet for EnumerableSet.UintSet;
    using SafeMath for uint256;

    uint256 private constant AMOUNT_SCALE = 1e12;

    // Info of each user.
    struct UserInfo {
        EnumerableSet.UintSet tokenIds;
        uint256 amount; // How many tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of TOKENs
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (user.amount * pool.accTokenPerShare) - user.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accTokenPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    function hasTokenId(UserInfo storage self, uint256 tokenId) internal view returns (bool) {
        return self.tokenIds.contains(tokenId);
    }

    function getTotalTokens(UserInfo storage self) internal view returns (uint256) {
        return self.tokenIds.length();
    }

    function getTokenIdAt(UserInfo storage self, uint256 index) internal view returns (uint256) {
        return self.tokenIds.at(index);
    }

    function getTokenIds(UserInfo storage self) internal view returns (uint256[] memory tokenIDs) {
        tokenIDs = new uint256[](self.tokenIds.length());
        for (uint256 indexAt = 0; indexAt < self.tokenIds.length(); indexAt++) {
            tokenIDs[indexAt] = self.tokenIds.at(indexAt);
        }
        return tokenIDs;
    }

    function requireHasTokenId(UserInfo storage self, uint256 tokenId) internal view {
        require(hasTokenId(self, tokenId), "ACCOUNT_DIDNT_STAKE_TOKEN_ID");
    }

    function addTokenId(UserInfo storage self, uint256 tokenId) internal {
        self.tokenIds.add(tokenId);
    }

    function removeTokenId(UserInfo storage self, uint256 tokenId) internal {
        self.tokenIds.remove(tokenId);
    }

    function stake(
        UserInfo storage self,
        uint256 valuedAmountOrId,
        uint256 accTokenPerShare
    ) internal {
        self.amount = self.amount.add(valuedAmountOrId);
        self.rewardDebt = self.amount.mul(accTokenPerShare).div(AMOUNT_SCALE);
    }

    function unstake(
        UserInfo storage self,
        uint256 valuedAmountOrId,
        uint256 accTokenPerShare
    ) internal {
        self.amount = self.amount.sub(valuedAmountOrId);
        self.rewardDebt = self.amount.mul(accTokenPerShare).div(AMOUNT_SCALE);
    }

    function emergencyUnstakeAll(UserInfo storage self) internal {
        self.amount = 0;
        self.rewardDebt = 0;
    }

    function cleanTokenIDs(UserInfo storage self) internal {
        delete self.tokenIds;
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Interfaces

// Libraries
import "@openzeppelin/contracts/math/SafeMath.sol";

library PoolInfoLib {
    using SafeMath for uint256;

    // Info of each pool.
    struct PoolInfo {
        uint256 totalDeposit;
        address token; // Address of token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Tokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that tokens distribution occurs.
        uint256 accTokenPerShare; // Accumulated tokens per share, times 1e12. See below.
        bool isPaused;
    }

    function setIsPaused(PoolInfo storage self, bool newIsPaused) internal {
        self.isPaused = newIsPaused;
    }

    function requireIsNotPaused(PoolInfo storage self) internal view {
        require(!self.isPaused, "POOL_IS_PAUSED");
    }

    function requireIsPaused(PoolInfo storage self) internal view {
        require(self.isPaused, "POOL_ISNT_PAUSED");
    }

    function stake(PoolInfo storage self, uint256 valuedAmount) internal {
        self.totalDeposit = self.totalDeposit.add(valuedAmount);
    }

    function unstake(PoolInfo storage self, uint256 valuedAmount) internal {
        self.totalDeposit = self.totalDeposit.sub(valuedAmount);
    }
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Contracts
import "../roles/RolesManagerConsts.sol";
import "../settings/PlatformSettingsConsts.sol";

// Libraries
import "@openzeppelin/contracts/utils/Address.sol";

// Interfaces
import "../settings/IPlatformSettings.sol";
import "../roles/IRolesManager.sol";

abstract contract Base {
    using Address for address;

    /* Constant Variables */

    /* State Variables */

    address public settings;

    /* Modifiers */

    modifier whenPlatformIsPaused() {
        require(_settings().isPaused(), "PLATFORM_ISNT_PAUSED");
        _;
    }

    modifier whenPlatformIsNotPaused() {
        require(!_settings().isPaused(), "PLATFORM_IS_PAUSED");
        _;
    }

    modifier onlyOwner(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).OWNER_ROLE(),
            account,
            "SENDER_ISNT_OWNER"
        );
        _;
    }

    modifier onlyMinter(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).MINTER_ROLE(),
            account,
            "SENDER_ISNT_MINTER"
        );
        _;
    }

    modifier onlyConfigurator(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).CONFIGURATOR_ROLE(),
            account,
            "SENDER_ISNT_CONFIGURATOR"
        );
        _;
    }

    modifier onlyPauser(address account) {
        _requireHasRole(
            RolesManagerConsts(_rolesManager().consts()).PAUSER_ROLE(),
            account,
            "SENDER_ISNT_PAUSER"
        );
        _;
    }

    /* Constructor */

    constructor(address settingsAddress) internal {
        require(settingsAddress.isContract(), "SETTINGS_MUST_BE_CONTRACT");
        settings = settingsAddress;
    }

    function setSettings(address newSettings) external onlyOwner(msg.sender) {
        require(newSettings.isContract(), "SETTINGS_MUST_BE_CONTRACT");
        require(newSettings != settings, "SETTINGS_MUST_BE_NEW");
        address oldSettings = settings;
        settings = newSettings;
        emit PlatformSettingsUpdated(oldSettings, newSettings);
    }

    /** Internal Functions */

    function _settings() internal view returns (IPlatformSettings) {
        return IPlatformSettings(settings);
    }

    function _settingsConsts() internal view returns (PlatformSettingsConsts) {
        return PlatformSettingsConsts(_settings().consts());
    }

    function _rolesManager() internal view returns (IRolesManager) {
        return IRolesManager(IPlatformSettings(settings).rolesManager());
    }

    function _requireHasRole(
        bytes32 role,
        address account,
        string memory message
    ) internal view {
        IRolesManager rolesManager = _rolesManager();
        rolesManager.requireHasRole(role, account, message);
    }

    function _getPlatformSettingsValue(bytes32 name) internal view returns (uint256) {
        return _settings().getSettingValue(name);
    }

    /** Events */

    event PlatformSettingsUpdated(address indexed oldSettings, address indexed newSettings);
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

// Libraries

// Contracts

// Interfaces

interface IStaking {
    function stake(uint256 pid, uint256 amountOrId) external;

    function unstake(uint256 pid, uint256 amountOrId) external;

    function addPool(
        uint256 allocationPoints,
        address token,
        bool withUpdate
    ) external;

    function pausePool(uint256 pid) external;

    function unpausePool(uint256 pid) external;

    function sweep(address token, uint256 amountOrId) external;

    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() external;

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyUnstakeAll(uint256 pid) external;

    // Update the given pool's token allocation point. Can only be called by the owner.
    function setAllocPoint(
        uint256 pid,
        uint256 newAllocPoint,
        bool withUpdate
    ) external;

    function setOutputPerBlock(uint256 newOutputPerBlock) external;

    function setFeeReceiver(address newFeeReceiver) external;

    function setTokenValuator(address newTokenValuator) external;

    /* View Functions */

    function getTotalPools() external view returns (uint256);

    function getInfo()
        external
        view
        returns (
            uint256 totalPools,
            uint256 outputPerBlockNumber,
            uint256 startBlockNumber,
            uint256 bonusEndBlockNumber,
            bool bonusFinished,
            uint256 totalAllocPoints
        );

    function getUserInfoForPool(uint256 pid, address account)
        external
        view
        returns (
            uint256 amount,
            uint256 rewardDebt,
            uint256[] memory tokenIDs
        );

    function getPoolInfoFor(uint256 pid)
        external
        view
        returns (
            uint256 totalDeposit,
            address token,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accTokenPerShare,
            bool isPaused
        );

    // Return reward multiplier over the given fromBlock to toBlock block.
    function getMultiplier(uint256 fromBlock, uint256 toBlock) external view returns (uint256);

    function getPendingTokens(uint256 pid, address account) external view returns (uint256);

    function getAllPendingTokens(address account) external view returns (uint256);

    function getPools()
        external
        view
        returns (
            address[] memory tokens,
            uint256[] memory totalDeposit,
            uint256[] memory allocPoints,
            uint256[] memory lastRewardBlocks,
            uint256[] memory accTokenPerShares,
            bool[] memory isPaused,
            uint256 totalPools
        );

    /// @notice event emitted when a user has staked a token
    event Staked(address indexed user, uint256 pid, uint256 amount, uint256 valuedAmount);

    /// @notice event emitted when a user has unstaked a token
    event Unstaked(address indexed user, uint256 pid, uint256 amount, uint256 valuedAmount);

    /// @notice event emitted when a user claims reward
    event RewardPaid(address indexed user, uint256 pid, uint256 reward);

    /// @notice Emergency unstake tokens without rewards
    event EmergencyUnstake(address indexed user, uint256 pid);

    event OutputPerBlockUpdated(uint256 oldOutputPerBlock, uint256 newOutputPerBlock);

    event TokenValuatorUpdated(address indexed oldTokenValuator, address indexed newTokenValuator);

    event FeeReceiverUpdated(address indexed oldFeeReceiver, address indexed newFeeReceiver);

    event AllocPointsUpdated(uint256 pid, uint256 oldAllocPoints, uint256 newAllocPoints);

    event NewPoolAdded(
        address indexed token,
        uint256 pid,
        uint256 allocPoint,
        uint256 totalAllocPoint
    );

    event PoolPauseSet(uint256 pid, bool pause);

    event TokenSweeped(address indexed token, uint256 amountOrId);
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

interface ITokenValuator {
    function valuate(
        address token,
        address user,
        uint256 pid,
        uint256 amountOrId
    ) external view returns (uint256);

    function isConfigured(address token) external view returns (bool);

    function requireIsConfigured(address token) external view;

    function hasValuation(
        address token,
        address user,
        uint256 pid,
        uint256 amountOrId
    ) external view returns (bool);

    function requireHasValuation(
        address token,
        address user,
        uint256 pid,
        uint256 amountOrId
    ) external view;
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
library EnumerableSet {
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

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

contract RolesManagerConsts {
    /**
        @notice It is the AccessControl.DEFAULT_ADMIN_ROLE role.
     */
    bytes32 public constant OWNER_ROLE = keccak256("");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    bytes32 public constant CONFIGURATOR_ROLE = keccak256("CONFIGURATOR_ROLE");
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

contract PlatformSettingsConsts {
    bytes32 public constant FEE = "Fee";

    bytes32 public constant BONUS_MULTIPLIER = "BonusMultiplier";

    bytes32 public constant ALLOW_ONLY_EOA = "AllowOnlyEOA";

    bytes32 public constant RATE_TOKEN_PAUSED = "RATETokenPaused";
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../libs/SettingsLib.sol";

interface IPlatformSettings {
    event PlatformPaused(address indexed pauser);

    event PlatformUnpaused(address indexed unpauser);

    event PlatformSettingCreated(
        bytes32 indexed name,
        address indexed creator,
        uint256 value,
        uint256 minValue,
        uint256 maxValue
    );

    event PlatformSettingRemoved(bytes32 indexed name, address indexed remover, uint256 value);

    event PlatformSettingUpdated(
        bytes32 indexed name,
        address indexed remover,
        uint256 oldValue,
        uint256 newValue
    );

    function createSetting(
        bytes32 name,
        uint256 value,
        uint256 min,
        uint256 max
    ) external;

    function removeSetting(bytes32 name) external;

    function getSetting(bytes32 name) external view returns (SettingsLib.Setting memory);

    function getSettingValue(bytes32 name) external view returns (uint256);

    function hasSetting(bytes32 name) external view returns (bool);

    function rolesManager() external view returns (address);

    function isPaused() external view returns (bool);

    function requireIsPaused() external view;

    function requireIsNotPaused() external view;

    function consts() external view returns (address);

    function pause() external;

    function unpause() external;
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

interface IRolesManager {
    event MaxMultiItemsUpdated(address indexed updater, uint8 oldValue, uint8 newValue);

    function setMaxMultiItems(uint8 newMaxMultiItems) external;

    function multiGrantRole(bytes32 role, address[] calldata accounts) external;

    function multiRevokeRole(bytes32 role, address[] calldata accounts) external;

    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;

    function consts() external view returns (address);

    function maxMultiItems() external view returns (uint8);

    function requireHasRole(bytes32 role, address account) external view;

    function requireHasRole(
        bytes32 role,
        address account,
        string calldata message
    ) external view;
}

//SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.6.12;

library SettingsLib {
    /**
        It defines a setting. It includes: value, min, and max values.
     */
    struct Setting {
        uint256 value;
        uint256 min;
        uint256 max;
        bool exists;
    }

    /**
        @notice It creates a new setting given a name, min and max values.
        @param value initial value for the setting.
        @param min min value allowed for the setting.
        @param max max value allowed for the setting.
     */
    function create(
        Setting storage self,
        uint256 value,
        uint256 min,
        uint256 max
    ) internal {
        requireNotExists(self);
        require(value >= min, "VALUE_MUST_BE_GT_MIN_VALUE");
        require(value <= max, "VALUE_MUST_BE_LT_MAX_VALUE");
        self.value = value;
        self.min = min;
        self.max = max;
        self.exists = true;
    }

    /**
        @notice Checks whether the current setting exists or not.
        @dev It throws a require error if the setting already exists.
        @param self the current setting.
     */
    function requireNotExists(Setting storage self) internal view {
        require(!self.exists, "SETTING_ALREADY_EXISTS");
    }

    /**
        @notice Checks whether the current setting exists or not.
        @dev It throws a require error if the current setting doesn't exist.
        @param self the current setting.
     */
    function requireExists(Setting storage self) internal view {
        require(self.exists, "SETTING_NOT_EXISTS");
    }

    /**
        @notice It updates a current setting.
        @dev It throws a require error if:
            - The new value is equal to the current value.
            - The new value is not lower than the max value.
            - The new value is not greater than the min value
        @param self the current setting.
        @param newValue the new value to set in the setting.
     */
    function update(Setting storage self, uint256 newValue) internal returns (uint256 oldValue) {
        requireExists(self);
        require(self.value != newValue, "NEW_VALUE_REQUIRED");
        require(newValue >= self.min, "NEW_VALUE_MUST_BE_GT_MIN_VALUE");
        require(newValue <= self.max, "NEW_VALUE_MUST_BE_LT_MAX_VALUE");
        oldValue = self.value;
        self.value = newValue;
    }

    /**
        @notice It removes a current setting.
        @param self the current setting to remove.
     */
    function remove(Setting storage self) internal {
        requireExists(self);
        self.value = 0;
        self.min = 0;
        self.max = 0;
        self.exists = false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}