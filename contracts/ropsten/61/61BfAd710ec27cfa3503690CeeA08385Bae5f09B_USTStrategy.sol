// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
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
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.0;

/// @notice Ultra minimal authorization logic for smart contracts.
/// @author Inspired by Dappsys V2 (https://github.com/dapp-org/dappsys-v2/blob/main/src/auth.sol)
abstract contract Trust {
    event UserTrustUpdated(address indexed user, bool trusted);

    mapping(address => bool) public isTrusted;

    constructor(address initialUser) {
        isTrusted[initialUser] = true;

        emit UserTrustUpdated(initialUser, true);
    }

    function setIsTrusted(address user, bool trusted) public virtual requiresTrust {
        isTrusted[user] = trusted;

        emit UserTrustUpdated(user, trusted);
    }

    modifier requiresTrust() {
        require(isTrusted[msg.sender], "UNTRUSTED");

        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

library PercentMath {
    // Divisor used for representing percentages
    uint256 public constant PERC_DIVISOR = 10000;

    /**
     * @dev Returns whether an amount is a valid percentage out of PERC_DIVISOR
     * @param _amount Amount that is supposed to be a percentage
     */
    function validPerc(uint256 _amount) internal pure returns (bool) {
        return _amount <= PERC_DIVISOR;
    }

    /**
     * @dev Compute percentage of a value with the percentage represented by a fraction
     * @param _amount Amount to take the percentage of
     * @param _fracNum Numerator of fraction representing the percentage
     * @param _fracDenom Denominator of fraction representing the percentage
     */
    function percOf(
        uint256 _amount,
        uint256 _fracNum,
        uint256 _fracDenom
    ) internal pure returns (uint256) {
        return (_amount * percPoints(_fracNum, _fracDenom)) / PERC_DIVISOR;
    }

    /**
     * @dev Compute percentage of a value with the percentage represented by a fraction over PERC_DIVISOR
     * @param _amount Amount to take the percentage of
     * @param _fracNum Numerator of fraction representing the percentage with PERC_DIVISOR as the denominator
     */
    function percOf(uint256 _amount, uint256 _fracNum)
        internal
        pure
        returns (uint256)
    {
        return (_amount * _fracNum) / PERC_DIVISOR;
    }

    /**
     * @dev Checks if a given number corresponds to 100%
     * @param _perc Percentage value to check, with PERC_DIVISOR
     */
    function is100Perc(uint256 _perc) internal pure returns (bool) {
        return _perc == PERC_DIVISOR;
    }

    /**
     * @dev Compute percentage representation of a fraction
     * @param _fracNum Numerator of fraction represeting the percentage
     * @param _fracDenom Denominator of fraction represeting the percentage
     */
    function percPoints(uint256 _fracNum, uint256 _fracDenom)
        internal
        pure
        returns (uint256)
    {
        return (_fracNum * PERC_DIVISOR) / _fracDenom;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Trust} from "@rari-capital/solmate/src/auth/Trust.sol";

import "../lib/PercentMath.sol";
import "../vault/IVault.sol";
import "./IStrategy.sol";
import "./anchor/IEthAnchorRouter.sol";
import "./anchor/IExchangeRateFeeder.sol";

/**
 * Base strategy that handles UST tokens and invests them via the EthAnchor
 * protocol (https://docs.anchorprotocol.com/ethanchor/ethanchor)
 */
abstract contract BaseStrategy is IStrategy, Trust {
    using SafeERC20 for IERC20;
    using PercentMath for uint256;

    event PerfFeeClaimed(uint256 amount);
    event PerfFeePctUpdated(uint256 pct);
    event ExchangeRateFeederUpdated(address indexed exchangeRateFeeder);

    struct Operation {
        address operator;
        uint256 amount;
    }

    IERC20 public override(IStrategy) underlying;
    // Vault address
    address public override(IStrategy) vault;

    // address of the treasury
    address public treasury;

    // address for the UST token
    IERC20 public ustToken;

    // address for the aUST token (wrapped Anchor UST, received to accrue interest for an Anchor deposit)
    IERC20 public aUstToken;

    // performance fee taken by the treasury on profits
    uint16 public perfFeePct;

    // external contract to interact with EthAnchor
    IEthAnchorRouter public ethAnchorRouter;

    // external exchange rate provider
    IExchangeRateFeeder public exchangeRateFeeder;

    // amount currently pending in deposits to EthAnchor
    uint256 public pendingDeposits;

    // amount currently pending redeemption from EthAnchor
    uint256 public pendingRedeems;

    // deposit operations history
    Operation[] public depositOperations;

    // redeem operations history
    Operation[] public redeemOperations;

    // amount of UST converted (used to calculate yield)
    uint256 public convertedUst;

    // restructs a function to be called only by the vault or governance
    modifier restricted() {
        require(msg.sender == vault || isTrusted[msg.sender], "restricted");

        _;
    }

    modifier onlyVault() {
        require(msg.sender == vault, "only vault");

        _;
    }

    constructor(
        address _vault,
        address _treasury,
        address _ethAnchorRouter,
        address _exchangeRateFeeder,
        IERC20 _ustToken,
        IERC20 _aUstToken,
        uint16 _perfFeePct,
        address _owner
    ) Trust(_owner) {
        require(_ethAnchorRouter != address(0), "0x addr");
        require(_exchangeRateFeeder != address(0), "0x addr");
        require(address(_ustToken) != address(0), "0x addr");
        require(address(_aUstToken) != address(0), "0x addr");
        require(PercentMath.validPerc(_perfFeePct), "invalid pct");

        treasury = _treasury;
        vault = _vault;
        underlying = IVault(_vault).underlying();
        ethAnchorRouter = IEthAnchorRouter(_ethAnchorRouter);
        exchangeRateFeeder = IExchangeRateFeeder(_exchangeRateFeeder);
        ustToken = _ustToken;
        aUstToken = _aUstToken;
        perfFeePct = _perfFeePct;

        // pre-approve EthAnchor router to transact all UST and aUST
        ustToken.safeIncreaseAllowance(_ethAnchorRouter, type(uint256).max);
        aUstToken.safeIncreaseAllowance(_ethAnchorRouter, type(uint256).max);
    }

    function setExchangeRateFeeder(address _exchangeRateFeeder)
        external
        restricted
    {
        require(_exchangeRateFeeder != address(0), "0x addr");
        exchangeRateFeeder = IExchangeRateFeeder(_exchangeRateFeeder);

        emit ExchangeRateFeederUpdated(_exchangeRateFeeder);
    }

    /**
     * Initiates a deposit of all the currently held UST into EthAnchor
     *
     * @notice since EthAnchor uses an asynchronous model, this function
     * only starts the deposit process, but does not finish it.
     */
    function doHardWork() external virtual;

    function _initDepositStable() internal {
        uint256 ustBalance = _getUstBalance();
        require(ustBalance > 0, "balance 0");
        pendingDeposits += ustBalance;
        address _operator = ethAnchorRouter.initDepositStable(ustBalance);
        depositOperations.push(
            Operation({operator: _operator, amount: ustBalance})
        );
    }

    /**
     * Calls EthAnchor with a pending deposit ID, and attempts to finish it.
     *
     * @notice Must be called some time after `doHardWork()`. Will only work if
     * the EthAnchor bridge has finished processing the deposit.
     *
     * @param idx Id of the pending deposit operation
     */
    function finishDepositStable(uint256 idx) external restricted {
        require(depositOperations.length > idx, "not running");
        Operation storage operation = depositOperations[idx];
        ethAnchorRouter.finishDepositStable(operation.operator);

        pendingDeposits -= operation.amount;
        convertedUst += operation.amount;

        operation.operator = depositOperations[depositOperations.length - 1]
            .operator;
        operation.amount = depositOperations[depositOperations.length - 1]
            .amount;
        depositOperations.pop();
    }

    /**
     * Initiates a withdrawal of UST from EthAnchor
     *
     * @notice since EthAnchor uses an asynchronous model, this function
     * only starts the redeem process, but does not finish it.
     *
     * @param amount Amount of aUST to redeem
     */
    function initRedeemStable(uint256 amount) public restricted {
        uint256 aUstBalance = _getAUstBalance();
        require(amount > 0, "amount 0");
        require(aUstBalance >= amount, "insufficient");
        pendingRedeems += amount;
        address _operator = ethAnchorRouter.initRedeemStable(amount);
        redeemOperations.push(Operation({operator: _operator, amount: amount}));
    }

    /**
     * Withdraws the entire amount back to the vault
     *
     * @notice since some of the amount may be deposited into EthAnchor, this
     * call may not withdraw all the funds right away. It will start a redeem
     * process on EthAnchor, but this function must be called again a second
     * time once that is finished.
     */
    function withdrawAllToVault() external override(IStrategy) restricted {
        uint256 aUstBalance = _getAUstBalance();
        if (aUstBalance > 0) {
            initRedeemStable(aUstBalance);
        }
    }

    /**
     * Withdraws a specified amount back to the vault
     *
     * @notice this function only considers the
     * amount currently not invested, but only what is currently held by the
     * strategy
     *
     * @param amount Amount to withdraw
     */
    function withdrawToVault(uint256 amount)
        external
        override(IStrategy)
        restricted
    {
        underlying.safeTransfer(vault, amount);
    }

    /**
     * Updates the performance fee
     *
     * @notice Can only be called by governance
     *
     * @param _perfFeePct The new performance fee %
     */
    function setPerfFeePct(uint16 _perfFeePct) external restricted {
        require(PercentMath.validPerc(_perfFeePct), "invalid pct");
        perfFeePct = _perfFeePct;
        emit PerfFeePctUpdated(_perfFeePct);
    }

    /**
     * Amount, expressed in the underlying currency, currently in the strategy
     *
     * @notice both held and invested amounts are included here, using the
     * latest known exchange rates to the underlying currency
     *
     * @return The total amount of underlying
     */
    function investedAssets()
        external
        view
        virtual
        override(IStrategy)
        returns (uint256);

    /**
     * Calls EthAnchor with a pending redeem ID, and attempts to finish it.
     *
     * @notice Must be called some time after `initRedeemStable()`. Will only work if
     * the EthAnchor bridge has finished processing the deposit.
     *
     * @param idx Id of the pending redeem operation
     */
    function _finishRedeemStable(uint256 idx) internal returns (uint256) {
        require(redeemOperations.length > idx, "not running");
        Operation storage operation = redeemOperations[idx];
        uint256 aUstBalance = _getAUstBalance() + pendingRedeems;
        uint256 originalUst = (convertedUst * operation.amount) / aUstBalance;

        ethAnchorRouter.finishRedeemStable(operation.operator);

        uint256 redeemedAmount = _getUstBalance();
        uint256 perfFee = redeemedAmount > originalUst
            ? (redeemedAmount - originalUst).percOf(perfFeePct)
            : 0;
        if (perfFee > 0) {
            ustToken.safeTransfer(treasury, perfFee);
            emit PerfFeeClaimed(perfFee);
        }
        convertedUst -= originalUst;
        pendingRedeems -= operation.amount;

        operation.operator = redeemOperations[redeemOperations.length - 1]
            .operator;
        operation.amount = redeemOperations[redeemOperations.length - 1].amount;
        redeemOperations.pop();

        return redeemedAmount - perfFee;
    }

    // Amount of underlying tokens in the strategy
    function _getUnderlyingBalance() internal view returns (uint256) {
        return underlying.balanceOf(address(this));
    }

    // Amount of UST tokens in the strategy
    function _getUstBalance() internal view returns (uint256) {
        return ustToken.balanceOf(address(this));
    }

    // Amount of aUST tokens in the strategy
    function _getAUstBalance() internal view returns (uint256) {
        return aUstToken.balanceOf(address(this));
    }

    // Amount of pending deposit operations
    function depositOperationLength() external view returns (uint256) {
        return depositOperations.length;
    }

    // Amount of pending redeem operations
    function redeemOperationLength() external view returns (uint256) {
        return redeemOperations.length;
    }

    // Calculate performance fee in UST with aUST balance and exchange rate
    function _performanceUstFeeWithInfo(
        uint256 aUstBalance,
        uint256 exchangeRate
    ) private view returns (uint256) {
        uint256 estimatedUstAmount = (exchangeRate * aUstBalance) / 1e18;
        if (estimatedUstAmount > convertedUst) {
            return (estimatedUstAmount - convertedUst).percOf(perfFeePct);
        }
        return 0;
    }

    /**
     * Calculate current performance fee amount
     *
     * @notice Performance fee is in UST
     *
     * @return current performance fee
     */
    function currentPerformanceFee() external view returns (uint256) {
        if (convertedUst == 0) {
            return 0;
        }

        uint256 aUstBalance = _getAUstBalance() + pendingRedeems;

        return
            _performanceUstFeeWithInfo(
                aUstBalance,
                exchangeRateFeeder.exchangeRateOf(address(ustToken), true)
            );
    }

    // Get UST value of current aUST balance
    function _estimateAUstBalanceInUstMinusFee()
        internal
        view
        returns (uint256)
    {
        uint256 aUstBalance = _getAUstBalance() + pendingRedeems;

        if (aUstBalance == 0) {
            return 0;
        }

        uint256 exchangeRate = exchangeRateFeeder.exchangeRateOf(
            address(ustToken),
            true
        );

        return
            ((exchangeRate * aUstBalance) / 1e18) -
            _performanceUstFeeWithInfo(aUstBalance, exchangeRate);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Strategies can be plugged into vaults to invest and manage their underlying funds
 *
 * @notice It's up to the strategy to decide what do to with investable assets provided by a vault
 *
 * @notice It's up to the vault to decide how much to invest from the total pool
 */
interface IStrategy {
    /**
     * The underlying ERC20 token stored by the vault
     *
     * @return The ERC20 token address
     */
    function underlying() external view returns (IERC20);

    /**
     * The vault linked to this stragegy
     *
     * @return The vault's address
     */
    function vault() external view returns (address);

    /**
     * Withdraws all underlying back to vault.
     *
     * @notice If underlying is currently invested, this also starts the
     * cross-chain process to redeem it. After that is done, this function
     * should be called a second time to finish the withdrawal of that portion.
     */
    function withdrawAllToVault() external;

    /**
     * Withdraws a specified amount back to the vault
     *
     * @notice Unlike `withdrawToVault`, this function only considers the
     * amount currently not invested, but only what is currently held by the
     * strategy
     *
     * @param amount Amount to withdraw
     */
    function withdrawToVault(uint256 amount) external;

    /**
     * Amount, expressed in the underlying currency, currently in the strategy
     *
     * @notice both held and invested amounts are included here, using the
     * latest known exchange rates to the underlying currency
     *
     * @return The total amount of underlying
     */
    function investedAssets() external view returns (uint256);

    /**
     * Initiates the process of investing the underlying currency
     */
    function doHardWork() external;

    /**
     * Calls EthAnchor with a pending redeem ID, and attempts to finish it.
     *
     * @notice Must be called some time after `initRedeemStable()`. Will only work if
     * the EthAnchor bridge has finished processing the deposit.
     *
     * @param idx Id of the pending redeem operation
     */
    function finishRedeemStable(uint256 idx) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./BaseStrategy.sol";
import "../lib/PercentMath.sol";

/**
 * A strategy that uses UST as the underlying currency
 *
 * @notice The base implementation for EthAnchorUSTBaseStrategy already handles
 * everything, since in this case _underlying and _ustToken are the same token
 */
contract USTStrategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using PercentMath for uint256;

    constructor(
        address _vault,
        address _treasury,
        address _ethAnchorRouter,
        address _exchangeRateFeeder,
        IERC20 _ustToken,
        IERC20 _aUstToken,
        uint16 _perfFeePct,
        address _owner
    )
        BaseStrategy(
            _vault,
            _treasury,
            _ethAnchorRouter,
            _exchangeRateFeeder,
            _ustToken,
            _aUstToken,
            _perfFeePct,
            _owner
        )
    {
        require(underlying == _ustToken, "invalid underlying");
    }

    /**
     * Initiates a deposit of all the currently held UST into EthAnchor
     *
     * @notice since EthAnchor uses an asynchronous model, this function
     * only starts the deposit process, but does not finish it.
     */
    function doHardWork() external override restricted {
        _initDepositStable();
    }

    /**
     * Calls EthAnchor with a pending redeem ID, and attempts to finish it.
     *
     * @notice Must be called some time after `initRedeemStable()`. Will only work if
     * the EthAnchor bridge has finished processing the deposit.
     *
     * @param idx Id of the pending redeem operation
     */
    function finishRedeemStable(uint256 idx) external restricted {
        uint256 amount = _finishRedeemStable(idx);
        ustToken.safeTransfer(vault, amount);
    }

    /**
     * Amount, expressed in the underlying currency, currently in the strategy
     *
     * @notice both held and invested amounts are included here, using the
     * latest known exchange rates to the underlying currency
     *
     * @return The total amount of underlying
     */
    function investedAssets() external view override returns (uint256) {
        return pendingDeposits + _estimateAUstBalanceInUstMinusFee();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

interface IEthAnchorRouter {
    function initDepositStable(uint256 _amount) external returns (address);

    function finishDepositStable(address _operation) external;

    function initRedeemStable(uint256 _amount) external returns (address);

    function finishRedeemStable(address _operation) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

interface IExchangeRateFeeder {
    function exchangeRateOf(address _token, bool _simulate)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVault {
    //
    // Structs
    //
    struct ClaimParams {
        uint16 pct;
        address beneficiary;
        bytes data;
    }

    struct DepositParams {
        uint256 amount;
        ClaimParams[] claims;
        uint256 lockedUntil;
    }

    //
    // Events
    //

    event DepositMinted(
        uint256 indexed id,
        uint256 groupId,
        uint256 amount,
        uint256 shares,
        address indexed depositor,
        address indexed claimer,
        uint256 claimerId,
        uint256 lockedUntil
    );

    event DepositBurned(uint256 indexed id, uint256 shares, address indexed to);

    event InvestPercentageUpdated(uint256 percentage);

    event Invested(uint256 amount);

    //
    // Public API
    //

    /**
     * Update the invested amount;
     */
    function updateInvested() external;

    /**
     * Calculates underlying investable amount.
     *
     * @return the investable amount
     */
    function investableAmount() external view returns (uint256);

    /**
     * Update invest percentage
     *
     * Emits {InvestPercentageUpdated} event
     *
     * @param _investPct the new invest percentage
     */
    function setInvestPerc(uint16 _investPct) external;

    /**
     * Percentage of the total underlying to invest in the strategy
     */
    function investPerc() external view returns (uint256);

    /**
     * Underlying ERC20 token accepted by the vault
     */
    function underlying() external view returns (IERC20);

    /**
     * Minimum lock period for each deposit
     */
    function minLockPeriod() external view returns (uint256);

    /**
     * Total amount of underlying currently controlled by the
     * vault and the its strategy.
     */
    function totalUnderlying() external view returns (uint256);

    /**
     * Total amount of shares
     */
    function totalShares() external view returns (uint256);

    /**
     * Computes the amount of yield available for an an address.
     *
     * @param _to address to consider.
     *
     * @return amount of yield for @param _to.
     */
    function yieldFor(address _to) external view returns (uint256);

    /**
     * Transfers all the yield generated for the caller to
     *
     * @param _to Address that will receive the yield.
     */
    function claimYield(address _to) external;

    /**
     * Creates a new deposit
     *
     * @param _params Deposit params
     */
    function deposit(DepositParams calldata _params) external;

    /**
     * Withdraws the principal from the deposits with the ids provided in @param _ids and sends it to @param _to.
     *
     * It fails if the vault is underperforming and there are not enough funds
     * to withdraw the expected amount.
     *
     * @param _to Address that will receive the funds.
     * @param _ids Array with the ids of the deposits.
     */
    function withdraw(address _to, uint256[] memory _ids) external;

    /**
     * Withdraws the principal from the deposits with the ids provided in @param _ids and sends it to @param _to.
     *
     * When the vault is underperforming it withdraws the funds with a loss.
     *
     * @param _to Address that will receive the funds.
     * @param _ids Array with the ids of the deposits.
     */
    function forceWithdraw(address _to, uint256[] memory _ids) external;

    /**
     * Changes the strategy used by the vault.
     *
     * @param _strategy the new strategy's address.
     */
    function setStrategy(address _strategy) external;
}