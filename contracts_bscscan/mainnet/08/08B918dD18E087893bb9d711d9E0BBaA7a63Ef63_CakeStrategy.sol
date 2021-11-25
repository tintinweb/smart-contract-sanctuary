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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

import "./interfaces/IStrategy.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IBentoBoxMinimal.sol";
import "./libraries/UniswapV2Library.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract BaseStrategy is IStrategy, Ownable {
    using SafeERC20 for IERC20;

    address public immutable strategyToken;
    address public immutable bentoBox;
    address public immutable factory;
    address public immutable bridgeToken;

    bool public exited; /// @dev After bentobox 'exits' the strategy harvest, skim and withdraw functions can no loner be called
    uint256 public maxBentoBoxBalance; /// @dev Slippage protection when calling harvest
    mapping(address => bool) public strategyExecutors; /// @dev EOAs that can execute safeHarvest

    bytes32 internal immutable pairCodeHash;

    event LogConvert(address indexed server, address indexed token0, address indexed token1, uint256 amount0, uint256 amount1);
    event LogSetStrategyExecutor(address indexed executor, bool allowed);

    /** @param _strategyToken Address of the underlying token the strategy invests.
        @param _bentoBox BentoBox address.
        @param _factory SushiSwap factory.
        @param _bridgeToken An intermedieary token for swapping any rewards into the underlying token.
        @param _strategyExecutor an EOA that will execute the safeHarvest function.
        @param _pairCodeHash This hash is used to calculate the address of a uniswap-like pool
                                by providing only the addresses of the two ERC20 tokens.
        @dev factory and bridgeToken can be address(0) if we don't expect rewards we would need to swap
    */
    constructor(
        address _strategyToken,
        address _bentoBox,
        address _factory,
        address _bridgeToken,
        address _strategyExecutor,
        bytes32 _pairCodeHash
    ) {
        strategyToken = _strategyToken;
        bentoBox = _bentoBox;
        factory = _factory;
        bridgeToken = _bridgeToken;
        pairCodeHash = _pairCodeHash;

        if (_strategyExecutor != address(0)) {
            strategyExecutors[_strategyExecutor] = true;
            emit LogSetStrategyExecutor(_strategyExecutor, true);
        }
    }

    //** Strategy implementation: override the following functions: */

    /// @notice Invests the underlying asset.
    /// @param amount The amount of tokens to invest.
    /// @dev Assume the contract's balance is greater than the amount
    function _skim(uint256 amount) internal virtual;

    /// @notice Harvest any profits made and transfer them to address(this) or report a loss
    /// @param balance The amount of tokens that have been invested.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    /// @dev amountAdded can be left at 0 when reporting profits (gas savings).
    /// amountAdded should not reflect any rewards or tokens the strategy received.
    /// Calcualte the amount added based on what the current deposit is worth.
    /// (The Base Strategy harvest function accounts for rewards).
    function _harvest(uint256 balance) internal virtual returns (int256 amountAdded);

    /// @dev Withdraw the requested amount of the underlying tokens to address(this).
    /// @param amount The requested amount we want to withdraw.
    function _withdraw(uint256 amount) internal virtual;

    /// @notice Withdraw the maximum available amount of the invested assets to address(this).
    /// @dev This shouldn't revert (use try catch).
    function _exit() internal virtual;

    /// @notice Claim any rewards reward tokens and optionally sell them for the underlying token.
    /// @dev Doesn't need to be implemented if we don't expect any rewards.
    function _harvestRewards() internal virtual {}

    //** End strategy implementation */

    modifier isActive() {
        require(!exited, "BentoBox Strategy: exited");
        _;
    }

    modifier onlyBentoBox() {
        require(msg.sender == bentoBox, "BentoBox Strategy: only BentoBox");
        _;
    }

    modifier onlyExecutor() {
        require(strategyExecutors[msg.sender], "BentoBox Strategy: only Executors");
        _;
    }

    function setStrategyExecutor(address executor, bool value) external onlyOwner {
        strategyExecutors[executor] = value;
        emit LogSetStrategyExecutor(executor, value);
    }

    /// @inheritdoc IStrategy
    function skim(uint256 amount) external override {
        _skim(amount);
    }

    /// @notice Harvest profits while preventing a sandwich attack exploit.
    /// @param maxBalance The maximum balance of the underlying token that is allowed to be in BentoBox.
    /// @param rebalance Whether BentoBox should rebalance the strategy assets to acheive it's target allocation.
    /// @param maxChangeAmount When rebalancing - the maximum amount that will be deposited to or withdrawn from a strategy to BentoBox.
    /// @param harvestRewards If we want to claim any accrued reward tokens
    /// @dev maxBalance can be set to 0 to keep the previous value.
    /// @dev maxChangeAmount can be set to 0 to allow for full rebalancing.
    function safeHarvest(
        uint256 maxBalance,
        bool rebalance,
        uint256 maxChangeAmount,
        bool harvestRewards
    ) external onlyExecutor {
        if (harvestRewards) {
            _harvestRewards();
        }

        if (maxBalance > 0) {
            maxBentoBoxBalance = maxBalance;
        }

        IBentoBoxMinimal(bentoBox).harvest(strategyToken, rebalance, maxChangeAmount);
    }

    /** @inheritdoc IStrategy
    @dev Only BentoBox can call harvest on this strategy.
    @dev Ensures that (1) the caller was this contract (called through the safeHarvest function)
        and (2) that we are not being frontrun by a large BentoBox deposit when harvesting profits. */
    function harvest(uint256 balance, address sender) external override isActive onlyBentoBox returns (int256) {
        /** @dev Don't revert if conditions aren't met in order to allow
            BentoBox to continiue execution as it might need to do a rebalance. */

        if (sender == address(this) && IBentoBoxMinimal(bentoBox).totals(strategyToken).elastic <= maxBentoBoxBalance && balance > 0) {
            int256 amount = _harvest(balance);

            /** @dev Since harvesting of rewards is accounted for seperately we might also have
            some underlying tokens in the contract that the _harvest call doesn't report. 
            E.g. reward tokens that have been sold into the underlying tokens which are now sitting in the contract.
            Meaning the amount returned by the internal _harvest function isn't necessary the final profit/loss amount */

            uint256 contractBalance = IERC20(strategyToken).balanceOf(address(this));

            if (amount >= 0) {
                // _harvest reported a profit

                if (contractBalance > 0) {
                    IERC20(strategyToken).safeTransfer(bentoBox, contractBalance);
                }

                return int256(contractBalance);
            } else if (contractBalance > 0) {
                // _harvest reported a loss but we have some tokens sitting in the contract

                int256 diff = amount + int256(contractBalance);

                if (diff > 0) {
                    // we still made some profit

                    /// @dev send the profit to BentoBox and reinvest the rest
                    IERC20(strategyToken).safeTransfer(bentoBox, uint256(diff));
                    _skim(uint256(-amount));
                } else {
                    // we made a loss but we have some tokens we can reinvest

                    _skim(contractBalance);
                }

                return diff;
            } else {
                // we made a loss

                return amount;
            }
        }

        return int256(0);
    }

    /// @inheritdoc IStrategy
    function withdraw(uint256 amount) external override isActive onlyBentoBox returns (uint256 actualAmount) {
        _withdraw(amount);
        /// @dev Make sure we send and report the exact same amount of tokens by using balanceOf.
        actualAmount = IERC20(strategyToken).balanceOf(address(this));
        IERC20(strategyToken).safeTransfer(bentoBox, actualAmount);
    }

    /// @inheritdoc IStrategy
    /// @dev do not use isActive modifier here; allow bentobox to call strategy.exit() multiple times
    function exit(uint256 balance) external override onlyBentoBox returns (int256 amountAdded) {
        _exit();
        /// @dev Check balance of token on the contract.
        uint256 actualBalance = IERC20(strategyToken).balanceOf(address(this));
        /// @dev Calculate tokens added (or lost).
        amountAdded = int256(actualBalance) - int256(balance);
        /// @dev Transfer all tokens to bentoBox.
        IERC20(strategyToken).safeTransfer(bentoBox, actualBalance);
        /// @dev Flag as exited, allowing the owner to manually deal with any amounts available later.
        exited = true;
    }

    /** @dev After exited, the owner can perform ANY call. This is to rescue any funds that didn't
        get released during exit or got earned afterwards due to vesting or airdrops, etc. */
    function afterExit(
        address to,
        uint256 value,
        bytes memory data
    ) public onlyOwner returns (bool success) {
        require(exited, "BentoBox Strategy: not exited");
        (success, ) = to.call{value: value}(data);
    }

    /// @notice Swap some tokens in the contract for the underlying and deposits them to address(this)
    function swapExactTokensForUnderlying(uint256 amountOutMin, address inputToken) public onlyExecutor returns (uint256 amountOut) {
        require(factory != address(0), "BentoBox Strategy: cannot swap");
        require(inputToken != strategyToken, "BentoBox Strategy: invalid swap");

        ///@dev Construct a path array consisting of the input (reward token),
        /// underlying token and a potential bridge token
        bool useBridge = bridgeToken != address(0);

        address[] memory path = new address[](useBridge ? 3 : 2);

        path[0] = inputToken;

        if (useBridge) {
            path[1] = bridgeToken;
        }

        path[path.length - 1] = strategyToken;

        uint256 amountIn = IERC20(path[0]).balanceOf(address(this));

        uint256[] memory amounts = UniswapV2Library.getAmountsOut(factory, amountIn, path, pairCodeHash);

        amountOut = amounts[amounts.length - 1];

        require(amountOut >= amountOutMin, "BentoBox Strategy: insufficient output");

        IERC20(path[0]).safeTransfer(UniswapV2Library.pairFor(factory, path[0], path[1], pairCodeHash), amounts[0]);

        _swap(amounts, path, address(this));

        emit LogConvert(msg.sender, inputToken, strategyToken, amountIn, amountOut);
    }

    /// @dev requires the initial amount to have already been sent to the first pair
    function _swap(
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            address token0 = input < output ? input : output;
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
            address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory, output, path[i + 2], pairCodeHash) : _to;
            IUniswapV2Pair(UniswapV2Library.pairFor(factory, input, output, pairCodeHash)).swap(amount0Out, amount1Out, to, new bytes(0));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

/// @notice Minimal interface for BentoBox token vault interactions - `token` is aliased as `address` from `IERC20` for code simplicity.
interface IBentoBoxMinimal {

    struct Rebase {
        uint128 elastic;
        uint128 base;
    }

    struct StrategyData {
        uint64 strategyStartDate;
        uint64 targetPercentage;
        uint128 balance; // the balance of the strategy that BentoBox thinks is in there
    }

    function strategyData(address token) external view returns (StrategyData memory);

    /// @notice Balance per ERC-20 token per account in shares.
    function balanceOf(address, address) external view returns (uint256);

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param token_ The ERC-20 token to deposit.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function deposit(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param token_ The ERC-20 token to withdraw.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    /// @notice Transfer shares from a user account to another one.
    /// @param token The ERC-20 token to transfer.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param share The amount of `token` in shares.
    function transfer(
        address token,
        address from,
        address to,
        uint256 share
    ) external;

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param token The ERC-20 token.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    /// @dev Helper function to represent shares back into the `token` amount.
    /// @param token The ERC-20 token.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(
        address token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    /// @notice Registers this contract so that users can approve it for the BentoBox.
    function registerProtocol() external;

    function totals(address token) external view returns (Rebase memory);

    function harvest(
        address token,
        bool balance,
        uint256 maxChangeAmount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address user) external view returns (uint256 amount, uint256 rewardDebt);
    function emergencyWithdraw(uint256 _pid) external;
}

interface ICakeChef is IMasterChef {
    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

interface IStrategy {
    /// @notice Send the assets to the Strategy and call skim to invest them.
    /// @param amount The amount of tokens to invest.
    function skim(uint256 amount) external;

    /// @notice Harvest any profits made converted to the asset and pass them to the caller.
    /// @param balance The amount of tokens the caller thinks it has invested.
    /// @param sender The address of the initiator of this transaction. Can be used for reimbursements, etc.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    function harvest(uint256 balance, address sender) external returns (int256 amountAdded);

    /// @notice Withdraw assets. The returned amount can differ from the requested amount due to rounding.
    /// @dev The `actualAmount` should be very close to the amount.
    /// The difference should NOT be used to report a loss. That's what harvest is for.
    /// @param amount The requested amount the caller wants to withdraw.
    /// @return actualAmount The real amount that is withdrawn.
    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    /// @notice Withdraw all assets in the safest way possible. This shouldn't fail.
    /// @param balance The amount of tokens the caller thinks it has invested.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    function exit(uint256 balance) external returns (int256 amountAdded);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

/// @notice Interface for SushiSwap.
interface ISushiSwap {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external pure returns (address);
    function token1() external pure returns (address);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

interface IUniswapV2Pair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

/// @notice Babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method).
library Babylonian {
    // computes square roots using the babylonian method
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

import "../interfaces/IUniswapV2Pair.sol";

/* 
The following library is modified from @sushiswap/core/contracts/uniswapv2/libraries/UniswapV2Library.sol

changes: 
    - remove SafeMathUniswap library and replace all usage of it with basic operations
    - change casting from uint to bytes20 in pair address calculation and shift by 96 bits before casting
 */

library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 pairCodeHash
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);

        // Since Solidity 0.8.0 explicit conversions from literals larger than type(uint160).max to address are disallowed.
        // https://docs.soliditylang.org/en/develop/080-breaking-changes.html#new-restrictions
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            pairCodeHash // init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 pairCodeHash
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB, pairCodeHash)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = (amountA * reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = (reserveIn * 1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path,
        bytes32 pairCodeHash
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1], pairCodeHash);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path,
        bytes32 pairCodeHash
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i], pairCodeHash);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../BaseStrategy.sol";
import "../interfaces/ISushiSwap.sol";
import "../interfaces/IMasterChef.sol";
import "../libraries/Babylonian.sol";

contract CakeStrategy is BaseStrategy {
    using SafeERC20 for IERC20;

    event LpMinted(uint256 total, uint256 strategyAmount, uint256 feeAmount);

    uint256 private constant DEADLINE = 0xf000000000000000000000000000000000000000000000000000000000000000; // ~ placeholder for swap deadline
    uint256 private constant FEE = 10; // 10% fees on minted LP

    ICakeChef private immutable masterchef;

    address public feeCollector;

    /** @param _strategyToken Address of the underlying LP token the strategy invests.
        @param _bentoBox BentoBox address.
        @param _factory SushiSwap factory.
        @param _bridgeToken An intermediary token for swapping any rewards into it before swapping it to _inputPairToken
        @param _strategyExecutor an EOA that will execute the safeHarvest function.
    */
    constructor(
        address _strategyToken,
        address _bentoBox,
        address _factory,
        address _bridgeToken,
        address _strategyExecutor,
        ICakeChef _masterchef,
        bytes32 _pairCodeHash
    ) BaseStrategy(_strategyToken, _bentoBox, _factory, _bridgeToken, _strategyExecutor, _pairCodeHash) {

        masterchef = _masterchef;
        feeCollector = _msgSender();

        IERC20(_strategyToken).safeApprove(address(_masterchef), type(uint256).max);
    }

    function _skim(uint256 amount) internal override {
        masterchef.enterStaking(amount);
    }

    function _harvest(uint256) internal override returns (int256) {
        masterchef.leaveStaking(0);

        uint256 total = IERC20(strategyToken).balanceOf(address(this));
        uint256 feeAmount = (total * FEE) / 100;

        IERC20(strategyToken).safeTransfer(feeCollector, feeAmount);

        return int256(0);
    }

    function _withdraw(uint256 amount) internal override {
        masterchef.leaveStaking(amount);
    }

    function _exit() internal override {
        masterchef.emergencyWithdraw(0);
    }

    function setFeeCollector(address _feeCollector) external onlyOwner {
        feeCollector = _feeCollector;
    }
}