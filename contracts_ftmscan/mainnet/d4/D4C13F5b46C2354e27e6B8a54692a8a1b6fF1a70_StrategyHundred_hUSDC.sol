// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.6;

import {StrategyHundred} from "../StrategyHundred.sol";

contract StrategyHundred_hUSDC is StrategyHundred {

    address husd_diff;

    function initializeStrategy(
        address _store,
        address _vault
    ) public initializer {
        address gauge = address(0x110614276F7b9Ae8586a1C1D9Bc079771e2CE8cF);
        address hnd = address(0x10010078a54396F62c96dF8532dc2B4847d47ED3);
        address escrow = address(0x376020c5B0ba3Fd603d7722381fAA06DA8078d8a);
        address bhnd_usdc_ftm_lp = address(0xEF6Ee56d5418AD608E86D34F05F73fFC2769E4e1);

        address[] memory rewards = new address[](1);
        rewards[0] = hnd;

        LiquidationConfig memory config;
        config.depositToken = hnd;
        config.rewardToDepositPoolID = 0xd57cda2caebb9b64bb88905c4de0f0da217a77d7000100000000000000000073;
        config.depositArrayIndex = 1;
        config.nTokens = 3;
        __Strategy_init(
            _store,
            gauge,
            _vault, 
            rewards,
            escrow,
            500,
            config,
            bhnd_usdc_ftm_lp
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IBalancerVault, IAsset} from "../../interfaces/swaps/IBalancerVault.sol";
import {IBalancerPool} from "../../interfaces/swaps/IBalancerPool.sol";
import {IComptroller} from "../../interfaces/protocols/IComptroller.sol";
import {IRewardGauge} from "../../interfaces/protocols/IRewardGauge.sol";
import {IMinter} from "../../interfaces/protocols/IMinter.sol";
import {IVotingEscrow} from "../../interfaces/protocols/IVotingEscrow.sol";
import {IStrategy} from "../../interfaces/IStrategy.sol";
import {IVault} from "../../interfaces/IVault.sol";
import {BaseStrategy} from "../BaseStrategy.sol";

/// @title Gauge Strategy for Hundred. 
/// @author Chainvisions & jlontele 
/// @notice A farming strategy for Hundred that works as a maximizer.

contract StrategyHundred is BaseStrategy {
    using SafeERC20 for IERC20;

    uint256 public constant MAX_LOCK_TIME = 4 * 365 * 86400;    // 4 years as the max lock time.

    // Struct for configuring reward liquidation.
    struct LiquidationConfig {
        address depositToken;
        bytes32 rewardToDepositPoolID;
        uint256 depositArrayIndex;
        uint256 nTokens;
    }

    mapping(bytes32 => bytes32) private bytes32Storage;
    address[] private poolAssets;
    
    /// @notice Initializes the strategy contract.
    /// @param _storage Storage contract for access control.
    /// @param _underlying Underlying token of the strategy.
    /// @param _vault Vault contract for the strategy.
    /// @param _rewards Vault reward tokens.
    /// @param _liquidationConfig Configuration for liquidation on BeethovenX.
    /// @param _targetVault Target vault to convert rewards to and inject to `_vault`.
    function __Strategy_init(
        address _storage,
        address _underlying,
        address _vault,
        address[] memory _rewards,
        address _votingEscrow,
        uint256 _lockNumerator,
        LiquidationConfig memory _liquidationConfig,
        address _targetVault
    )
    public initializer {
        BaseStrategy.initialize(
            _storage,
            _underlying,
            _vault,
            address(0),
            _rewards,
            true,
            1e4,
            12 hours
        );
        _setMinter(IRewardGauge(underlying()).minter());
        _setVotingEscrow(_votingEscrow);
        _setLockNumerator(_lockNumerator);
        _setTargetVault(_targetVault);
        _setDepositToken(_liquidationConfig.depositToken);
        _setRewardToDepositPoolID(_liquidationConfig.rewardToDepositPoolID);
        _setNTokens(_liquidationConfig.nTokens);
        _setDepositArrayIndex(_liquidationConfig.depositArrayIndex);

        // Fetch the bvault address.
        address bvault = IBalancerPool(IVault(targetVault()).underlying()).getVault();
        _setBVault(bvault);

        // Set the pool assets.
        (IERC20[] memory tokens,, ) = IBalancerVault(bvault).getPoolTokens(_liquidationConfig.rewardToDepositPoolID);
        for(uint256 i = 0; i < tokens.length; i++) {
            poolAssets.push(address(tokens[i]));
        }   
    }

    function doHardWork() external onlyNotPausedInvesting restricted {
        IMinter(minter()).mint(underlying());
        _lockHundred();
        _liquidateReward();
        _notifyMaximizerRewards();
    }

    function salvage(address recipient, address token, uint256 amount) external restricted {
        require(!unsalvagableTokens(token), "Strategy: Unsalvagable token");
        IERC20(token).transfer(recipient, amount);
    }

    function finalizeUpgrade() external onlyGovernance {
        _finalizeUpgrade();
    }

    function investedUnderlyingBalance() external view returns (uint256) {
        if (rewardPool() == address(0)) {
            return IERC20(underlying()).balanceOf(address(this));
        }
        return IERC20(underlying()).balanceOf(address(this));
    }

    /// @notice Withdraws all staked funds to the vault. This allows for all funds to be divested
    /// from the strategy in a case such as a bug, issue, or a strategy switch being performed.
    function withdrawAllToVault() public restricted {
        // First we must claim any pending HND rewards and notify them.
        IMinter(minter()).mint(underlying());
        _liquidateReward();
        _notifyMaximizerRewards();

        // Now we can send the underlying to the vault.
        IERC20(underlying()).safeTransfer(vault(), IERC20(underlying()).balanceOf(address(this)));
    }

    /// @notice Withdraws tokens to the vault contract.
    /// @param amount Amount to withdraw to the vault.
    function withdrawToVault(uint256 amount) public restricted {
        IERC20(underlying()).safeTransfer(vault(), amount);
    }

    /// @notice Performs an emergency exit from the farm and pauses the strategy.
    function emergencyExit() public onlyGovernance {
        _setPausedInvesting(true);
    }

    /// @notice Continues investing into the reward pool.
    function continueInvesting() public onlyGovernance {
        _setPausedInvesting(false);
    }

    /// @notice Toggle for selling rewards or not.
    /// @param _sell Whether or not rewards should be sold.
    function setSell(bool _sell) public onlyGovernance {
        _setSell(_sell);
    }

    /// @notice Sets the minimum reward sell amount (or floor).
    /// @param _sellFloor The floor for selling rewards.
    function setSellFloor(uint256 _sellFloor) public onlyGovernance {
        _setSellFloor(_sellFloor);
    }

    /// @notice Sets the HND lock numerator.
    /// @param _lockNumerator Percentage of HND to lock into VotingEscrow.
    function setLockNumerator(uint256 _lockNumerator) public onlyGovernance {
        _setLockNumerator(_lockNumerator);
    }

    /// @notice A check for arb when depositing into the vault.
    /// @return Whether or not depositing is permitted.
    function depositArbCheck() public pure returns (bool) {
        return true;
    }

    /// @notice Checks whether or not a token can be salvaged from the strategy.
    /// @param token Token to check for salvagability.
    /// @return Whether or not the token can be salvaged.
    function unsalvagableTokens(address token) public view returns (bool) {
        return (token == underlying() || _isRewardToken(token));
    }

    /// @notice Gauge minter contract for claiming rewards.
    function minter() public view returns (address) {
        return _getAddress("minter");
    }

    /// @notice Hundred VotingEscrow contract.
    function votingEscrow() public view returns (address) {
        return _getAddress("votingEscrow");
    }

    /// @notice Target vault to deposit into.
    function targetVault() public view returns (address) {
        return _getAddress("targetVault");
    }

    /// @notice Token to enter the target LP via.
    function depositToken() public view returns (address) {
        return _getAddress("depositToken");
    }

    /// @notice BeethovenX vault contract.
    function bVault() public view returns (address) {
        return _getAddress("bVault");
    }

    /// @notice ID of the BeethovenX pool to deposit into.
    function rewardToDepositPoolID() public view returns (bytes32) {
        return _getBytes32("rewardToDepositPoolID");
    }

    /// @notice The indice to deposit from in the BeethovenX pool.
    function depositArrayIndex() public view returns (uint256) {
        return _getUint256("depositArrayIndex");
    }

    /// @notice The amount of tokens in the target BeethovenX pool.
    function nTokens() public view returns (uint256) {
        return _getUint256("nTokens");
    }

    /// @notice Percentage of HND rewards to lock up.
    function lockNumerator() public view returns (uint256) {
        return _getUint256("lockNumerator");
    }

    /// @notice Whether or not the strategy has created a lock on the VotingEscrow.
    function hasOpenLock() public view returns (bool) {
        return _getBool("hasOpenLock");
    }

    function _swapRewardToDeposit(address _reward, uint256 _rewardAmount) internal {
        uint256 rewardBalance = _rewardAmount;

        IBalancerVault.SingleSwap memory singleSwap;
        IBalancerVault.SwapKind swapKind = IBalancerVault.SwapKind.GIVEN_IN;

        singleSwap.poolId = rewardToDepositPoolID();   
        singleSwap.kind = swapKind;
        singleSwap.assetIn = IAsset(_reward);
        singleSwap.assetOut = IAsset(depositToken());
        singleSwap.amount = rewardBalance;
        singleSwap.userData = abi.encode(0);

        IBalancerVault.FundManagement memory funds;
        funds.sender = address(this);
        funds.fromInternalBalance = false;
        funds.recipient = payable(address(this));
        funds.toInternalBalance = false;

        IERC20(_reward).safeApprove(bVault(), 0);
        IERC20(_reward).safeApprove(bVault(), rewardBalance);

        IBalancerVault(bVault()).swap(singleSwap, funds, 1, (block.timestamp + 600));
    }

    function _depositLP() internal {
        uint256 depositTokenBalance = IERC20(depositToken()).balanceOf(address(this));

        IERC20(depositToken()).safeApprove(bVault(), 0);
        IERC20(depositToken()).safeApprove(bVault(), depositTokenBalance);

        IAsset[] memory assets = new IAsset[](nTokens());
        for (uint256 i = 0; i < nTokens(); i++) {
            assets[i] = IAsset(poolAssets[i]);
        }

        IBalancerVault.JoinKind joinKind = IBalancerVault.JoinKind.EXACT_TOKENS_IN_FOR_BPT_OUT;
        uint256[] memory amountsIn = new uint256[](nTokens());
        amountsIn[depositArrayIndex()] = depositTokenBalance;
        uint256 minAmountOut = 1;

        bytes memory userData = abi.encode(joinKind, amountsIn, minAmountOut);

        IBalancerVault.JoinPoolRequest memory request;
        request.assets = assets;
        request.maxAmountsIn = amountsIn;
        request.userData = userData;
        request.fromInternalBalance = false;

        IBalancerVault(bVault()).joinPool(
            rewardToDepositPoolID(),
            address(this),
            address(this),
            request
        );
    }

    function _handleLiquidation(uint256[] memory _balances) internal override {
        address[] memory rewards = _rewardTokens;
        for(uint256 i = 0; i < rewards.length; i++) {
            address reward = rewards[i];
            if(reward == depositToken()) {
                // No swap will be needed, we can enter via single sided depositing;.
                _depositLP();
            } else {
                _swapRewardToDeposit(reward, _balances[i]);
                _depositLP();
            }
        }
    }

    function _notifyMaximizerRewards() internal {
        address targetVaultUnderlying = IVault(targetVault()).underlying();
        uint256 targetUnderlyingBalance = IERC20(targetVaultUnderlying).balanceOf(address(this));

        if(targetUnderlyingBalance > 0) {
            // Deposit the target token into the target vault.
            IERC20(targetVaultUnderlying).safeApprove(targetVault(), 0);
            IERC20(targetVaultUnderlying).safeApprove(targetVault(), targetUnderlyingBalance);
            IVault(targetVault()).deposit(targetUnderlyingBalance);

            // Notify the rewards on the vault.
            uint256 targetVaultBalance = IERC20(targetVault()).balanceOf(address(this));
            IERC20(targetVault()).safeTransfer(vault(), targetVaultBalance);
            IVault(vault()).notifyRewardAmount(targetVault(), targetVaultBalance);
        }
    }

    function _lockHundred() internal {
        // We assume that HND is `_rewardTokens[0]`.
        address hnd = _rewardTokens[0];
        uint256 hndBalance = IERC20(hnd).balanceOf(address(this));

        // Now we can lock our HND rewards if we have any HND tokens.
        if(hndBalance > 0) {
            uint256 hndToLock = (hndBalance * lockNumerator()) / 10000;

            IERC20(hnd).safeApprove(votingEscrow(), 0);
            IERC20(hnd).safeApprove(votingEscrow(), hndToLock);

            if(hasOpenLock()) {
                IVotingEscrow(votingEscrow()).increase_amount(hndToLock);
            } else {
                IVotingEscrow(votingEscrow()).create_lock(hndToLock, (block.timestamp + MAX_LOCK_TIME));
                _setHasOpenLock(true);
            }
        }
    }

    function _setMinter(address _value) internal {
        _setAddress("minter", _value);
    }

    function _setVotingEscrow(address _value) internal {
        _setAddress("votingEscrow", _value);
    }

    function _setTargetVault(address _value) internal {
        _setAddress("targetVault", _value);
    }

    function _setDepositToken(address _value) internal {
        _setAddress("depositToken", _value);
    }

    function _setBVault(address _value) internal {
        _setAddress("bVault", _value);
    }

    function _setRewardToDepositPoolID(bytes32 _value) internal {
        _setBytes32("rewardToDepositPoolID", _value);
    }

    function _setNTokens(uint256 _value) internal {
        _setUint256("nTokens", _value);
    }

    function _setDepositArrayIndex(uint256 _value) internal {
        require(_value <= nTokens(), "Invalid array index");
        _setUint256("depositArrayIndex", _value);
    }

    function _setLockNumerator(uint256 _value) internal {
        require(lockNumerator() <= 10000, "lockNumerator cannot be more than 100%");
        _setUint256("lockNumerator", _value);
    }

    function _setHasOpenLock(bool _value) internal {
        _setBool("hasOpenLock", _value);
    }

    function _setBytes32(string memory _key, bytes32 _value) private {
        bytes32Storage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _getBytes32(string memory _key) private view returns (bytes32) {
        return bytes32Storage[keccak256(abi.encodePacked(_key))];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        // (a + b) / 2 can overflow, so we distribute.
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;
pragma experimental ABIEncoderV2;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IAsset {}

interface IBalancerVault {
    // Internal Balance
    //
    // Users can deposit tokens into the Vault, where they are allocated to their Internal Balance, and later
    // transferred or withdrawn. It can also be used as a source of tokens when joining Pools, as a destination
    // when exiting them, and as either when performing swaps. This usage of Internal Balance results in greatly reduced
    // gas costs when compared to relying on plain ERC20 transfers, leading to large savings for frequent users.
    //
    // Internal Balance management features batching, which means a single contract call can be used to perform multiple
    // operations of different kinds, with different senders and recipients, at once.

    /**
     * @dev Returns `user`'s Internal Balance for a set of tokens.
     */
    function getInternalBalance(address user, IERC20[] calldata tokens) external view returns (uint256[] memory);

    /**
     * @dev Performs a set of user balance operations, which involve Internal Balance (deposit, withdraw or transfer)
     * and plain ERC20 transfers using the Vault's allowance. This last feature is particularly useful for relayers, as
     * it lets integrators reuse a user's Vault allowance.
     *
     * For each operation, if the caller is not `sender`, it must be an authorized relayer for them.
     */
    function manageUserBalance(UserBalanceOp[] calldata ops) external payable;

    /**
     * @dev Data for `manageUserBalance` operations, which include the possibility for ETH to be sent and received
     without manual WETH wrapping or unwrapping.
     */
    struct UserBalanceOp {
        UserBalanceOpKind kind;
        IAsset asset;
        uint256 amount;
        address sender;
        address payable recipient;
    }

    // There are four possible operations in `manageUserBalance`:
    //
    // - DEPOSIT_INTERNAL
    // Increases the Internal Balance of the `recipient` account by transferring tokens from the corresponding
    // `sender`. The sender must have allowed the Vault to use their tokens via `IERC20.approve()`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset and forwarding ETH in the call: it will be wrapped
    // and deposited as WETH. Any ETH amount remaining will be sent back to the caller (not the sender, which is
    // relevant for relayers).
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - WITHDRAW_INTERNAL
    // Decreases the Internal Balance of the `sender` account by transferring tokens to the `recipient`.
    //
    // ETH can be used by passing the ETH sentinel value as the asset. This will deduct WETH instead, unwrap it and send
    // it to the recipient as ETH.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_INTERNAL
    // Transfers tokens from the Internal Balance of the `sender` account to the Internal Balance of `recipient`.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `InternalBalanceChanged` event.
    //
    //
    // - TRANSFER_EXTERNAL
    // Transfers tokens from `sender` to `recipient`, using the Vault's ERC20 allowance. This is typically used by
    // relayers, as it lets them reuse a user's Vault allowance.
    //
    // Reverts if the ETH sentinel value is passed.
    //
    // Emits an `ExternalBalanceTransfer` event.

    enum UserBalanceOpKind { DEPOSIT_INTERNAL, WITHDRAW_INTERNAL, TRANSFER_INTERNAL, TRANSFER_EXTERNAL }

    /**
     * @dev Emitted when a user's Internal Balance changes, either from calls to `manageUserBalance`, or through
     * interacting with Pools using Internal Balance.
     *
     * Because Internal Balance works exclusively with ERC20 tokens, ETH deposits and withdrawals will use the WETH
     * address.
     */
    event InternalBalanceChanged(address indexed user, IERC20 indexed token, int256 delta);

    /**
     * @dev Emitted when a user's Vault ERC20 allowance is used by the Vault to transfer tokens to an external account.
     */
    event ExternalBalanceTransfer(IERC20 indexed token, address indexed sender, address recipient, uint256 amount);

    // Pools
    //
    // There are three specialization settings for Pools, which allow for cheaper swaps at the cost of reduced
    // functionality:
    //
    //  - General: no specialization, suited for all Pools. IGeneralPool is used for swap request callbacks, passing the
    // balance of all tokens in the Pool. These Pools have the largest swap costs (because of the extra storage reads),
    // which increase with the number of registered tokens.
    //
    //  - Minimal Swap Info: IMinimalSwapInfoPool is used instead of IGeneralPool, which saves gas by only passing the
    // balance of the two tokens involved in the swap. This is suitable for some pricing algorithms, like the weighted
    // constant product one popularized by Balancer V1. Swap costs are smaller compared to general Pools, and are
    // independent of the number of registered tokens.
    //
    //  - Two Token: only allows two tokens to be registered. This achieves the lowest possible swap gas cost. Like
    // minimal swap info Pools, these are called via IMinimalSwapInfoPool.

    enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

    /**
     * @dev Registers the caller account as a Pool with a given specialization setting. Returns the Pool's ID, which
     * is used in all Pool-related functions. Pools cannot be deregistered, nor can the Pool's specialization be
     * changed.
     *
     * The caller is expected to be a smart contract that implements either `IGeneralPool` or `IMinimalSwapInfoPool`,
     * depending on the chosen specialization setting. This contract is known as the Pool's contract.
     *
     * Note that the same contract may register itself as multiple Pools with unique Pool IDs, or in other words,
     * multiple Pools may share the same contract.
     *
     * Emits a `PoolRegistered` event.
     */
    function registerPool(PoolSpecialization specialization) external returns (bytes32);

    /**
     * @dev Emitted when a Pool is registered by calling `registerPool`.
     */
    event PoolRegistered(bytes32 indexed poolId, address indexed poolAddress, PoolSpecialization specialization);

    /**
     * @dev Returns a Pool's contract address and specialization setting.
     */
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);

    /**
     * @dev Registers `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Pools can only interact with tokens they have registered. Users join a Pool by transferring registered tokens,
     * exit by receiving registered tokens, and can only swap registered tokens.
     *
     * Each token can only be registered once. For Pools with the Two Token specialization, `tokens` must have a length
     * of two, that is, both tokens must be registered in the same `registerTokens` call, and they must be sorted in
     * ascending order.
     *
     * The `tokens` and `assetManagers` arrays must have the same length, and each entry in these indicates the Asset
     * Manager for the corresponding token. Asset Managers can manage a Pool's tokens via `managePoolBalance`,
     * depositing and withdrawing them directly, and can even set their balance to arbitrary amounts. They are therefore
     * expected to be highly secured smart contracts with sound design principles, and the decision to register an
     * Asset Manager should not be made lightly.
     *
     * Pools can choose not to assign an Asset Manager to a given token by passing in the zero address. Once an Asset
     * Manager is set, it cannot be changed except by deregistering the associated token and registering again with a
     * different Asset Manager.
     *
     * Emits a `TokensRegistered` event.
     */
    function registerTokens(
        bytes32 poolId,
        IERC20[] calldata tokens,
        address[] calldata assetManagers
    ) external;

    /**
     * @dev Emitted when a Pool registers tokens by calling `registerTokens`.
     */
    event TokensRegistered(bytes32 indexed poolId, IERC20[] tokens, address[] assetManagers);

    /**
     * @dev Deregisters `tokens` for the `poolId` Pool. Must be called by the Pool's contract.
     *
     * Only registered tokens (via `registerTokens`) can be deregistered. Additionally, they must have zero total
     * balance. For Pools with the Two Token specialization, `tokens` must have a length of two, that is, both tokens
     * must be deregistered in the same `deregisterTokens` call.
     *
     * A deregistered token can be re-registered later on, possibly with a different Asset Manager.
     *
     * Emits a `TokensDeregistered` event.
     */
    function deregisterTokens(bytes32 poolId, IERC20[] calldata tokens) external;

    /**
     * @dev Emitted when a Pool deregisters tokens by calling `deregisterTokens`.
     */
    event TokensDeregistered(bytes32 indexed poolId, IERC20[] tokens);

    /**
     * @dev Returns detailed information for a Pool's registered token.
     *
     * `cash` is the number of tokens the Vault currently holds for the Pool. `managed` is the number of tokens
     * withdrawn and held outside the Vault by the Pool's token Asset Manager. The Pool's total balance for `token`
     * equals the sum of `cash` and `managed`.
     *
     * Internally, `cash` and `managed` are stored using 112 bits. No action can ever cause a Pool's token `cash`,
     * `managed` or `total` balance to be greater than 2^112 - 1.
     *
     * `lastChangeBlock` is the number of the block in which `token`'s total balance was last modified (via either a
     * join, exit, swap, or Asset Manager update). This value is useful to avoid so-called 'sandwich attacks', for
     * example when developing price oracles. A change of zero (e.g. caused by a swap with amount zero) is considered a
     * change for this purpose, and will update `lastChangeBlock`.
     *
     * `assetManager` is the Pool's token Asset Manager.
     */
    function getPoolTokenInfo(bytes32 poolId, IERC20 token)
        external
        view
        returns (
            uint256 cash,
            uint256 managed,
            uint256 lastChangeBlock,
            address assetManager
        );

    /**
     * @dev Returns a Pool's registered tokens, the total balance for each, and the latest block when *any* of
     * the tokens' `balances` changed.
     *
     * The order of the `tokens` array is the same order that will be used in `joinPool`, `exitPool`, as well as in all
     * Pool hooks (where applicable). Calls to `registerTokens` and `deregisterTokens` may change this order.
     *
     * If a Pool only registers tokens once, and these are sorted in ascending order, they will be stored in the same
     * order as passed to `registerTokens`.
     *
     * Total balances include both tokens held by the Vault and those withdrawn by the Pool's Asset Managers. These are
     * the amounts used by joins, exits and swaps. For a detailed breakdown of token balances, use `getPoolTokenInfo`
     * instead.
     */
    function getPoolTokens(bytes32 poolId)
        external
        view
        returns (
            IERC20[] memory tokens,
            uint256[] memory balances,
            uint256 lastChangeBlock
        );

    /**
     * @dev Called by users to join a Pool, which transfers tokens from `sender` into the Pool's balance. This will
     * trigger custom Pool behavior, which will typically grant something in return to `recipient` - often tokenized
     * Pool shares.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `assets` and `maxAmountsIn` arrays must have the same length, and each entry indicates the maximum amount
     * to send for each asset. The amounts to send are decided by the Pool and not the Vault: it just enforces
     * these maximums.
     *
     * If joining a Pool that holds WETH, it is possible to send ETH directly: the Vault will do the wrapping. To enable
     * this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead of the
     * WETH address. Note that it is not possible to combine ETH and WETH in the same join. Any excess ETH will be sent
     * back to the caller (not the sender, which is important for relayers).
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If sending ETH however, the array must be
     * sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the final
     * `assets` array might not be sorted. Pools with no registered tokens cannot be joined.
     *
     * If `fromInternalBalance` is true, the caller's Internal Balance will be preferred: ERC20 transfers will only
     * be made for the difference between the requested amount and Internal Balance (if any). Note that ETH cannot be
     * withdrawn from Internal Balance: attempting to do so will trigger a revert.
     *
     * This causes the Vault to call the `IBasePool.onJoinPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares). This can be encoded in the `userData` argument, which is ignored by the Vault and passed
     * directly to the Pool's contract, as is `recipient`.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest calldata request
    ) external payable;

    enum JoinKind { INIT, EXACT_TOKENS_IN_FOR_BPT_OUT, TOKEN_IN_FOR_EXACT_BPT_OUT }
    enum ExitKind { EXACT_BPT_IN_FOR_ONE_TOKEN_OUT, EXACT_BPT_IN_FOR_TOKENS_OUT, BPT_IN_FOR_EXACT_TOKENS_OUT }

    struct JoinPoolRequest {
        IAsset[] assets;
        uint256[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    /**
     * @dev Called by users to exit a Pool, which transfers tokens from the Pool's balance to `recipient`. This will
     * trigger custom Pool behavior, which will typically ask for something in return from `sender` - often tokenized
     * Pool shares. The amount of tokens that can be withdrawn is limited by the Pool's `cash` balance (see
     * `getPoolTokenInfo`).
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * The `tokens` and `minAmountsOut` arrays must have the same length, and each entry in these indicates the minimum
     * token amount to receive for each token contract. The amounts to send are decided by the Pool and not the Vault:
     * it just enforces these minimums.
     *
     * If exiting a Pool that holds WETH, it is possible to receive ETH directly: the Vault will do the unwrapping. To
     * enable this mechanism, the IAsset sentinel value (the zero address) must be passed in the `assets` array instead
     * of the WETH address. Note that it is not possible to combine ETH and WETH in the same exit.
     *
     * `assets` must have the same length and order as the array returned by `getPoolTokens`. This prevents issues when
     * interacting with Pools that register and deregister tokens frequently. If receiving ETH however, the array must
     * be sorted *before* replacing the WETH address with the ETH sentinel value (the zero address), which means the
     * final `assets` array might not be sorted. Pools with no registered tokens cannot be exited.
     *
     * If `toInternalBalance` is true, the tokens will be deposited to `recipient`'s Internal Balance. Otherwise,
     * an ERC20 transfer will be performed. Note that ETH cannot be deposited to Internal Balance: attempting to
     * do so will trigger a revert.
     *
     * `minAmountsOut` is the minimum amount of tokens the user expects to get out of the Pool, for each token in the
     * `tokens` array. This array must match the Pool's registered tokens.
     *
     * This causes the Vault to call the `IBasePool.onExitPool` hook on the Pool's contract, where Pools implement
     * their own custom logic. This typically requires additional information from the user (such as the expected number
     * of Pool shares to return). This can be encoded in the `userData` argument, which is ignored by the Vault and
     * passed directly to the Pool's contract.
     *
     * Emits a `PoolBalanceChanged` event.
     */
    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest calldata request
    ) external;

    struct ExitPoolRequest {
        IAsset[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    /**
     * @dev Emitted when a user joins or exits a Pool by calling `joinPool` or `exitPool`, respectively.
     */
    event PoolBalanceChanged(
        bytes32 indexed poolId,
        address indexed liquidityProvider,
        IERC20[] tokens,
        int256[] deltas,
        uint256[] protocolFeeAmounts
    );

    enum PoolBalanceChangeKind { JOIN, EXIT }

    // Swaps
    //
    // Users can swap tokens with Pools by calling the `swap` and `batchSwap` functions. To do this,
    // they need not trust Pool contracts in any way: all security checks are made by the Vault. They must however be
    // aware of the Pools' pricing algorithms in order to estimate the prices Pools will quote.
    //
    // The `swap` function executes a single swap, while `batchSwap` can perform multiple swaps in sequence.
    // In each individual swap, tokens of one kind are sent from the sender to the Pool (this is the 'token in'),
    // and tokens of another kind are sent from the Pool to the recipient in exchange (this is the 'token out').
    // More complex swaps, such as one token in to multiple tokens out can be achieved by batching together
    // individual swaps.
    //
    // There are two swap kinds:
    //  - 'given in' swaps, where the amount of tokens in (sent to the Pool) is known, and the Pool determines (via the
    // `onSwap` hook) the amount of tokens out (to send to the recipient).
    //  - 'given out' swaps, where the amount of tokens out (received from the Pool) is known, and the Pool determines
    // (via the `onSwap` hook) the amount of tokens in (to receive from the sender).
    //
    // Additionally, it is possible to chain swaps using a placeholder input amount, which the Vault replaces with
    // the calculated output of the previous swap. If the previous swap was 'given in', this will be the calculated
    // tokenOut amount. If the previous swap was 'given out', it will use the calculated tokenIn amount. These extended
    // swaps are known as 'multihop' swaps, since they 'hop' through a number of intermediate tokens before arriving at
    // the final intended token.
    //
    // In all cases, tokens are only transferred in and out of the Vault (or withdrawn from and deposited into Internal
    // Balance) after all individual swaps have been completed, and the net token balance change computed. This makes
    // certain swap patterns, such as multihops, or swaps that interact with the same token pair in multiple Pools, cost
    // much less gas than they would otherwise.
    //
    // It also means that under certain conditions it is possible to perform arbitrage by swapping with multiple
    // Pools in a way that results in net token movement out of the Vault (profit), with no tokens being sent in (only
    // updating the Pool's internal accounting).
    //
    // To protect users from front-running or the market changing rapidly, they supply a list of 'limits' for each token
    // involved in the swap, where either the maximum number of tokens to send (by passing a positive value) or the
    // minimum amount of tokens to receive (by passing a negative value) is specified.
    //
    // Additionally, a 'deadline' timestamp can also be provided, forcing the swap to fail if it occurs after
    // this point in time (e.g. if the transaction failed to be included in a block promptly).
    //
    // If interacting with Pools that hold WETH, it is possible to both send and receive ETH directly: the Vault will do
    // the wrapping and unwrapping. To enable this mechanism, the IAsset sentinel value (the zero address) must be
    // passed in the `assets` array instead of the WETH address. Note that it is possible to combine ETH and WETH in the
    // same swap. Any excess ETH will be sent back to the caller (not the sender, which is relevant for relayers).
    //
    // Finally, Internal Balance can be used when either sending or receiving tokens.

    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    /**
     * @dev Performs a swap with a single Pool.
     *
     * If the swap is 'given in' (the number of tokens to send to the Pool is known), it returns the amount of tokens
     * taken from the Pool, which must be greater than or equal to `limit`.
     *
     * If the swap is 'given out' (the number of tokens to take from the Pool is known), it returns the amount of tokens
     * sent to the Pool, which must be less than or equal to `limit`.
     *
     * Internal Balance usage and the recipient are determined by the `funds` struct.
     *
     * Emits a `Swap` event.
     */
    function swap(
        SingleSwap calldata singleSwap,
        FundManagement calldata funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @dev Data for a single swap executed by `swap`. `amount` is either `amountIn` or `amountOut` depending on
     * the `kind` value.
     *
     * `assetIn` and `assetOut` are either token addresses, or the IAsset sentinel value for ETH (the zero address).
     * Note that Pools never interact with ETH directly: it will be wrapped to or unwrapped from WETH by the Vault.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Performs a series of swaps with one or multiple Pools. In each individual swap, the caller determines either
     * the amount of tokens sent to or received from the Pool, depending on the `kind` value.
     *
     * Returns an array with the net Vault asset balance deltas. Positive amounts represent tokens (or ETH) sent to the
     * Vault, and negative amounts represent tokens (or ETH) sent by the Vault. Each delta corresponds to the asset at
     * the same index in the `assets` array.
     *
     * Swaps are executed sequentially, in the order specified by the `swaps` array. Each array element describes a
     * Pool, the token to be sent to this Pool, the token to receive from it, and an amount that is either `amountIn` or
     * `amountOut` depending on the swap kind.
     *
     * Multihop swaps can be executed by passing an `amount` value of zero for a swap. This will cause the amount in/out
     * of the previous swap to be used as the amount in for the current one. In a 'given in' swap, 'tokenIn' must equal
     * the previous swap's `tokenOut`. For a 'given out' swap, `tokenOut` must equal the previous swap's `tokenIn`.
     *
     * The `assets` array contains the addresses of all assets involved in the swaps. These are either token addresses,
     * or the IAsset sentinel value for ETH (the zero address). Each entry in the `swaps` array specifies tokens in and
     * out by referencing an index in `assets`. Note that Pools never interact with ETH directly: it will be wrapped to
     * or unwrapped from WETH by the Vault.
     *
     * Internal Balance usage, sender, and recipient are determined by the `funds` struct. The `limits` array specifies
     * the minimum or maximum amount of each token the vault is allowed to transfer.
     *
     * `batchSwap` can be used to make a single swap, like `swap` does, but doing so requires more gas than the
     * equivalent `swap` call.
     *
     * Emits `Swap` events.
     */
    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] calldata swaps,
        IAsset[] calldata assets,
        FundManagement calldata funds,
        int256[] calldata limits,
        uint256 deadline
    ) external payable returns (int256[] memory);

    /**
     * @dev Data for each individual swap executed by `batchSwap`. The asset in and out fields are indexes into the
     * `assets` array passed to that function, and ETH assets are converted to WETH.
     *
     * If `amount` is zero, the multihop mechanism is used to determine the actual amount based on the amount in/out
     * from the previous swap, depending on the swap kind.
     *
     * The `userData` field is ignored by the Vault, but forwarded to the Pool in the `onSwap` hook, and may be
     * used to extend swap behavior.
     */
    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    /**
     * @dev Emitted for each individual swap performed by `swap` or `batchSwap`.
     */
    event Swap(
        bytes32 indexed poolId,
        IERC20 indexed tokenIn,
        IERC20 indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    /**
     * @dev All tokens in a swap are either sent from the `sender` account to the Vault, or from the Vault to the
     * `recipient` account.
     *
     * If the caller is not `sender`, it must be an authorized relayer for them.
     *
     * If `fromInternalBalance` is true, the `sender`'s Internal Balance will be preferred, performing an ERC20
     * transfer for the difference between the requested amount and the User's Internal Balance (if any). The `sender`
     * must have allowed the Vault to use their tokens via `IERC20.approve()`. This matches the behavior of
     * `joinPool`.
     *
     * If `toInternalBalance` is true, tokens will be deposited to `recipient`'s internal balance instead of
     * transferred. This matches the behavior of `exitPool`.
     *
     * Note that ETH cannot be deposited to or withdrawn from Internal Balance: attempting to do so will trigger a
     * revert.
     */
    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    /**
     * @dev Simulates a call to `batchSwap`, returning an array of Vault asset deltas. Calls to `swap` cannot be
     * simulated directly, but an equivalent `batchSwap` call can and will yield the exact same result.
     *
     * Each element in the array corresponds to the asset at the same index, and indicates the number of tokens (or ETH)
     * the Vault would take from the sender (if positive) or send to the recipient (if negative). The arguments it
     * receives are the same that an equivalent `batchSwap` call would receive.
     *
     * Unlike `batchSwap`, this function performs no checks on the sender or recipient field in the `funds` struct.
     * This makes it suitable to be called by off-chain applications via eth_call without needing to hold tokens,
     * approve them for the Vault, or even know a user's address.
     *
     * Note that this function is not 'view' (due to implementation details): the client code must explicitly execute
     * eth_call instead of eth_sendTransaction.
     */
    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] calldata swaps,
        IAsset[] calldata assets,
        FundManagement calldata funds
    ) external returns (int256[] memory assetDeltas);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IBalancerPool {
    function getLatest(uint8) external view returns (uint256);
    function getPoolId() external view returns (bytes32);
    function getVault() external view returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

interface IComptroller {
    function claimComp(address) external;
    function enterMarkets(address[] memory) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

interface IRewardGauge {
    function deposit(uint256) external;
    function withdraw(uint256) external;
    function claim_rewards() external;
    function balanceOf(address) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function lp_token() external view returns (address);
    function minter() external view returns (address);
    function voting_escrow() external view returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

interface IMinter {
    function mint(address) external;
    function mint_for(address, address) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

interface IVotingEscrow {
    function create_lock(uint256, uint256) external;
    function increase_amount(uint256) external;
    function locked() external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IStrategy {
    function unsalvagableTokens(address tokens) external view returns (bool);
    
    function governance() external view returns (address);
    function controller() external view returns (address);
    function underlying() external view returns (address);
    function vault() external view returns (address);

    function withdrawAllToVault() external;
    function withdrawToVault(uint256 amount) external;

    function investedUnderlyingBalance() external view returns (uint256); // itsNotMuch()

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;
    function depositArbCheck() external view returns(bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IVault {
    function underlyingBalanceInVault() external view returns (uint256);
    function underlyingBalanceWithInvestment() external view returns (uint256);

    function underlying() external view returns (address);
    function strategy() external view returns (address);

    function setStrategy(address) external;
    function setVaultFractionToInvest(uint256) external;

    function deposit(uint256) external;

    function withdrawAll() external;
    function withdraw(uint256) external;

    function getReward() external;
    function getRewardByToken(address) external;
    function notifyRewardAmount(address, uint256) external;

    function getPricePerFullShare() external view returns (uint256);
    function underlyingBalanceWithInvestmentForHolder(address) view external returns (uint256);

    // hard work should be callable only by the controller (by the hard worker) or by governance
    function doHardWork() external;
    function rebalance() external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.6;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IController} from "../interfaces/IController.sol";
import {ControllableInit} from "../ControllableInit.sol";
import {BaseStrategyStorage} from "./BaseStrategyStorage.sol";

abstract contract BaseStrategy is ControllableInit, BaseStrategyStorage {
    using SafeERC20 for IERC20;

    /// @notice A list of reward tokens farmed by the strategy.
    address[] internal _rewardTokens;

    /// @notice Emitted when performance fee collection is skipped.
    event ProfitsNotCollected(bool sell, bool floor);

    /// @notice Emitted when performance fees are collected by the strategy.
    event ProfitLogInReward(uint256 profitAmount, uint256 feeAmount, uint256 timestamp);

    modifier restricted {
        require(msg.sender == vault() || msg.sender == controller()
        || msg.sender == governance(),
        "Strategy: The sender has to be the controller, governance, or vault");
        _;
    }

    // This is only used in `investAllUnderlying()`.
    // The user can still freely withdraw from the strategy.
    modifier onlyNotPausedInvesting {
        require(!pausedInvesting(), "Strategy: Action blocked as the strategy is in emergency state");
        _;
    }

    /// @notice Initializes the strategy proxy.
    /// @param _storage Address of the storage contract.
    /// @param _underlying Underlying token of the strategy.
    /// @param _vault Address of the strategy's vault.
    /// @param _rewardPool Address of the reward pool.
    /// @param _rewards Addresses of the reward tokens.
    /// @param _sell Whether or not `_rewardToken` should be liquidated.
    /// @param _sellFloor Minimum amount of `_rewardToken` to liquidate rewards.
    /// @param _timelockDelay Timelock for changing the proxy's implementation. 
    function initialize(
        address _storage,
        address _underlying,
        address _vault,
        address _rewardPool,
        address[] memory _rewards,
        bool _sell,
        uint256 _sellFloor,
        uint256 _timelockDelay
    ) public initializer {
        __Controllable_init(_storage);
        _setUnderlying(_underlying);
        _setVault(_vault);
        _setRewardPool(_rewardPool);

        _rewardTokens = _rewards;

        _setSell(_sell);
        _setSellFloor(_sellFloor);
        _setTimelockDelay(_timelockDelay);
        _setPausedInvesting(false);
    }

    /// @notice Collects protocol fees and sends them to the Controller.
    /// @param _rewardBalance The amount of rewards generated that is to have fees taken from.
    function notifyProfitInRewardToken(address _reward, uint256 _rewardBalance) internal {
        if(_rewardBalance > 0 ){
            uint256 feeAmount = (_rewardBalance * IController(controller()).profitSharingNumerator()) / IController(controller()).profitSharingDenominator();
            emit ProfitLogInReward(_rewardBalance, feeAmount, block.timestamp);
            IERC20(_reward).safeApprove(controller(), 0);
            IERC20(_reward).safeApprove(controller(), feeAmount);

            IController(controller()).notifyFee(
                _reward,
                feeAmount
            );
        } else {
            emit ProfitLogInReward(0, 0, block.timestamp);
        }
    }

    /// @notice Determines if the proxy can be upgraded.
    /// @return If an upgrade is possible and the address of the new implementation
    function shouldUpgrade() external view returns (bool, address) {
        return (
            nextImplementationTimestamp() != 0
                && block.timestamp > nextImplementationTimestamp()
                && nextImplementation() != address(0),
            nextImplementation()
        );
    }

    /// @notice Schedules an upgrade to the strategy proxy.
    function scheduleUpgrade(address _impl) public onlyGovernance {
        _setNextImplementation(_impl);
        _setNextImplementationTimestamp(block.timestamp + timelockDelay());
    }

    /// @notice Adds a reward token to the strategy contract.
    /// @param _rewardToken Reward token to add to the contract.
    function addRewardToken(address _rewardToken) public onlyGovernance {
        _rewardTokens.push(_rewardToken);
    }

    /// @notice Removes a reward token from the strategy contract.
    /// @param _rewardToken Reward token to remove from the contract.
    function removeRewardToken(address _rewardToken) public onlyGovernance {
        // First we must find the index of the reward token in the array.
        bool didFindIndex;
        uint256 rewardIndex;
        for(uint256 i = 0; i < _rewardTokens.length; i++) {
            if(_rewardTokens[i] == _rewardToken) {
                rewardIndex = i;
                didFindIndex = true;
            }
        }
        // If we cannot find it, we must revert the call.
        require(didFindIndex, "Strategy: Could not find reward token in array");

        // Now we can move the reward token to the last indice of the array and
        // pop the array, removing the reward token from the entire array.
        _rewardTokens[rewardIndex] = _rewardTokens[_rewardTokens.length - 1];
        _rewardTokens.pop();
    }

    /// @notice A list of all of the reward tokens on the strategy.
    /// @return The full `_rewardTokens` array.
    function rewardTokens() public view returns (address[] memory) {
        return (_rewardTokens);
    }

    function _finalizeUpgrade() internal {
        _setNextImplementation(address(0));
        _setNextImplementationTimestamp(0);
    }

    function _liquidateReward() internal {
        address[] memory rewards = _rewardTokens;
        uint256 nIndices = rewards.length;
        uint256[] memory rewardBalances = new uint256[](nIndices);
        for(uint256 i = 0; i < nIndices; i++) {
            address reward = rewards[i];
            uint256 rewardBalance = IERC20(reward).balanceOf(address(this));

            // Check if the reward is enough for liquidation.
            if(!sell() || rewardBalance < sellFloor()) {
                emit ProfitsNotCollected(sell(), rewardBalance < sellFloor());
                return;
            }
            
            // Notify performance fees.
            notifyProfitInRewardToken(reward, rewardBalance);

            // Push the balance after notifying fees.
            rewardBalances[i] = IERC20(reward).balanceOf(address(this));
        }

        _handleLiquidation(rewardBalances);
    }

    function _handleLiquidation(uint256[] memory _balances) internal virtual;

    function _isRewardToken(address _token) internal view returns (bool) {
        bool isReward;
        for(uint256 i = 0; i < _rewardTokens.length; i++) {
            if(_rewardTokens[i] == _token) {
                isReward = true;
            }
        }

        return isReward;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IController {
    function whitelist(address) external view returns (bool);
    function feeExemptAddresses(address) external view returns (bool);
    function greyList(address) external view returns (bool);
    function keepers(address) external view returns (bool);

    function doHardWork(address) external;
    function batchDoHardWork(address[] memory) external;

    function salvage(address, uint256) external;
    function salvageStrategy(address, address, uint256) external;

    function notifyFee(address, uint256) external;
    function profitSharingNumerator() external view returns (uint256);
    function profitSharingDenominator() external view returns (uint256);

    function profitCollector() external view returns (address);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {GovernableInit, Storage} from "./GovernableInit.sol";

contract ControllableInit is GovernableInit {

  constructor() {}

  function __Controllable_init(address _storage) public initializer {
    __Governable_init_(_storage);
  }

  modifier onlyController() {
    require(Storage(_storage()).isController(msg.sender), "Controllable: Not a controller");
    _;
  }

  modifier onlyControllerOrGovernance(){
    require((Storage(_storage()).isController(msg.sender) || Storage(_storage()).isGovernance(msg.sender)),
      "Controllable: The caller must be controller or governance");
    _;
  }

  function controller() public view returns (address) {
    return Storage(_storage()).controller();
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

contract BaseStrategyStorage {
    mapping(bytes32 => uint256) private uint256Storage;
    mapping(bytes32 => address) private addressStorage;
    mapping(bytes32 => bool) private boolStorage;

    function underlying() public view returns (address) {
        return _getAddress("underlying");
    }

    function vault() public view returns (address) {
        return _getAddress("vault");
    }

    function rewardPool() public view returns (address) {
        return _getAddress("rewardPool");
    }

    function sell() public view returns (bool) {
        return _getBool("sell");
    }

    function sellFloor() public view returns (uint256) {
        return _getUint256("sellFloor");
    }

    function pausedInvesting() public view returns (bool) {
        return _getBool("pausedInvesting");
    }

    function nextImplementation() public view returns (address) {
        return _getAddress("nextImplementation");
    }

    function nextImplementationTimestamp() public view returns (uint256) {
        return _getUint256("nextImplementationTimestamp");
    }

    function timelockDelay() public view returns (uint256) {
        return _getUint256("timelockDelay");
    }

    function _setUnderlying(address _value) internal {
        _setAddress("underlying", _value);
    }

    function _setVault(address _value) internal {
        _setAddress("vault", _value);
    }

    function _setRewardPool(address _value) internal {
        _setAddress("rewardPool", _value);
    }

    function _setSell(bool _value) internal {
        _setBool("sell", _value);
    }

    function _setSellFloor(uint256 _value) internal {
        _setUint256("sellFloor", _value);
    }

    function _setPausedInvesting(bool _value) internal {
        _setBool("pausedInvesting", _value);
    }

    function _setNextImplementation(address _value) internal {
        _setAddress("nextImplementation", _value);
    }

    function _setNextImplementationTimestamp(uint256 _value) internal {
        _setUint256("nextImplementationTimestamp", _value);
    }

    function _setTimelockDelay(uint256 _value) internal {
        _setUint256("timelockDelay", _value);
    }

    function _setUint256(string memory _key, uint256 _value) internal {
        uint256Storage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _setAddress(string memory _key, address _value) internal {
        addressStorage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _setBool(string memory _key, bool _value) internal {
        boolStorage[keccak256(abi.encodePacked(_key))] = _value;
    }

    function _getUint256(string memory _key) internal view returns (uint256) {
        return uint256Storage[keccak256(abi.encodePacked(_key))];
    }

    function _getAddress(string memory _key) internal view returns (address) {
        return addressStorage[keccak256(abi.encodePacked(_key))];
    }

    function _getBool(string memory _key) internal view returns (bool) {
        return boolStorage[keccak256(abi.encodePacked(_key))];
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {Storage} from "./Storage.sol";

/**
 * @dev Contract for access control where the governance address specified
 * in the Storage contract can be granted access to specific functions
 * on a contract that inherits this contract.
 *
 * The difference between GovernableInit and Governable is that GovernableInit supports proxy
 * smart contracts.
 */

contract GovernableInit is Initializable {

  bytes32 internal constant _STORAGE_SLOT = 0xa7ec62784904ff31cbcc32d09932a58e7f1e4476e1d041995b37c917990b16dc;

  modifier onlyGovernance() {
    require(Storage(_storage()).isGovernance(msg.sender), "Governable: Not governance");
    _;
  }

  constructor() {
    assert(_STORAGE_SLOT == bytes32(uint256(keccak256("eip1967.governableInit.storage")) - 1));
  }

  function __Governable_init_(address _store) public initializer {
    _setStorage(_store);
  }

  function _setStorage(address newStorage) private {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(slot, newStorage)
    }
  }

  function setStorage(address _store) public onlyGovernance {
    require(_store != address(0), "Governable: New storage shouldn't be empty");
    _setStorage(_store);
  }

  function _storage() internal view returns (address str) {
    bytes32 slot = _STORAGE_SLOT;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      str := sload(slot)
    }
  }

  function governance() public view returns (address) {
    return Storage(_storage()).governance();
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Storage {

  address public governance;
  address public controller;

  constructor() {
    governance = msg.sender;
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Storage: Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "Storage: New governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "Storage: New controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }
}