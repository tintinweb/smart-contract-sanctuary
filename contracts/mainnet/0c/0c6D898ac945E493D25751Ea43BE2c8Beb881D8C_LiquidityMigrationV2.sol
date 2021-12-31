//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0;

import { SafeERC20, IERC20 } from "../ecosystem/openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/IAdapter.sol";
import "./interfaces/IMigrationController.sol";
import "./interfaces/ILiquidityMigrationV2.sol";
import "../helpers/Timelocked.sol";

contract LiquidityMigrationV2 is ILiquidityMigrationV2, Timelocked {
    using SafeERC20 for IERC20;

    address public controller;
    address public genericRouter;
    address public migrationCoordinator;
    address public emergencyReceiver;

    bool public paused;
    mapping (address => bool) public adapters; // adapter -> bool
    mapping (address => uint256) public totalStaked; // lp -> total staked
    mapping (address => address) public strategies; // lp -> enso strategy
    mapping (address => mapping (address => uint256)) public staked; // user -> lp -> stake

    event Staked(address adapter, address strategy, uint256 amount, address account);
    event Migrated(address adapter, address lp, address strategy, address account);
    event Created(address adapter, address lp, address strategy, address account);
    event Refunded(address lp, uint256 amount, address account);
    event EmergencyMigration(address lp, uint256 amount, address receiver);

    /**
    * @dev Require adapter registered
    */
    modifier onlyRegistered(address adapter) {
        require(adapters[adapter], "Not registered");
        _;
    }

    /**
    * @dev Require adapter allows lp
    */
    modifier onlyWhitelisted(address adapter, address lp) {
        require(IAdapter(adapter).isWhitelisted(lp), "Not whitelist");
        _;
    }

    modifier onlyLocked() {
        require(block.timestamp < unlocked, "Unlocked");
        _;
    }

    modifier isPaused() {
        require(paused, "Not paused");
        _;
    }

    modifier notPaused() {
        require(!paused, "Paused");
        _;
    }

    constructor(
        address[] memory adapters_,
        uint256 unlock_,
        uint256 modify_
    )
        Timelocked(unlock_, modify_, msg.sender)
    {
        for (uint256 i = 0; i < adapters_.length; i++) {
            adapters[adapters_[i]] = true;
        }
    }

    function setStrategy(address lp, address strategy) external onlyOwner notPaused {
        require(
            IMigrationController(controller).initialized(strategy),
            "Not enso strategy"
        );
        if (strategies[lp] != address(0)) {
          // This value can be changed as long as no migration is in progress
          require(IERC20(strategies[lp]).balanceOf(address(this)) == 0, "Already set");
        }
        strategies[lp] = strategy;
    }

    function setStake(
        address user,
        address lp,
        address adapter,
        uint256 amount
    )
        external
        override
        notPaused
        onlyLocked
    {
        require(msg.sender == migrationCoordinator, "Wrong sender");
        _stake(user, lp, adapter, amount);
    }

    function stake(
        address lp,
        uint256 amount,
        address adapter
    )
        external
        notPaused
        onlyLocked
        onlyRegistered(adapter)
    {
        _transferFromAndStake(lp, adapter, amount);
    }

    function batchStake(
        address[] memory lps,
        uint256[] memory amounts,
        address adapter
    )
        external
        notPaused
        onlyLocked
        onlyRegistered(adapter)
    {
        require(lps.length == amounts.length, "Incorrect arrays");
        for (uint256 i = 0; i < lps.length; i++) {
            _transferFromAndStake(lps[i], adapter, amounts[i]);
        }
    }

    function buyAndStake(
        address lp,
        address adapter,
        address exchange,
        uint256 minAmountOut,
        uint256 deadline
    )
        external
        payable
        notPaused
        onlyLocked
        onlyRegistered(adapter)
        onlyWhitelisted(adapter, lp)
    {
        require(msg.value > 0, "No value");
        _buyAndStake(lp, msg.value, adapter, exchange, minAmountOut, deadline);
    }

    function migrateAll(
        address lp,
        address adapter
    )
        external
        override
        notPaused
        onlyOwner
        onlyUnlocked
        onlyRegistered(adapter)
        onlyWhitelisted(adapter, lp)
    {
        address strategy = strategies[lp];
        require(strategy != address(0), "Strategy not initialized");
        uint256 totalStake = totalStaked[lp];
        delete totalStaked[lp];
        uint256 strategyBalanceBefore = IStrategy(strategy).balanceOf(address(this));
        IERC20(lp).safeTransfer(genericRouter, totalStake);
        IMigrationController(controller).migrate(IStrategy(strategy), IStrategyRouter(genericRouter), IERC20(lp), IAdapter(adapter), totalStake);
        uint256 strategyBalanceAfter = IStrategy(strategy).balanceOf(address(this));
        assert((strategyBalanceAfter - strategyBalanceBefore) == totalStake);
    }

    function refund(address user, address lp) external onlyOwner {
        _refund(user, lp);
    }

    function withdraw(address lp) external {
        _refund(msg.sender, lp);
    }

    function claim(address lp) external {
        require(totalStaked[lp] == 0, "Not yet migrated");
        uint256 amount = staked[msg.sender][lp];
        require(amount > 0, "No claim");
        delete staked[msg.sender][lp];

        address strategy = strategies[lp];
        IERC20(strategy).safeTransfer(msg.sender, amount);
        emit Migrated(address(0), lp, strategy, msg.sender);
    }

    function emergencyMigrate(IERC20 lp) external isPaused onlyOwner {
        require(emergencyReceiver != address(0), "Emergency receiver not set");
        uint256 balance = lp.balanceOf(address(this));
        require(balance > 0, "No balance");
        lp.safeTransfer(emergencyReceiver, balance);
        emit EmergencyMigration(address(lp), balance, emergencyReceiver);
    }

    function pause() external notPaused onlyOwner {
        paused = true;
    }

    function unpause() external isPaused onlyOwner {
        paused = false;
    }

    function _stake(
        address user,
        address lp,
        address adapter,
        uint256 amount
    )
        internal
    {
        staked[user][lp] += amount;
        totalStaked[lp] += amount;
        emit Staked(adapter, lp, amount, user);
    }

    function _transferFromAndStake(
        address lp,
        address adapter,
        uint256 amount
    )
        internal
        onlyWhitelisted(adapter, lp)
    {
        require(amount > 0, "No amount");
        IERC20(lp).safeTransferFrom(msg.sender, address(this), amount);
        _stake(msg.sender, lp, adapter, amount);
    }

    function _buyAndStake(
        address lp,
        uint256 amount,
        address adapter,
        address exchange,
        uint256 minAmountOut,
        uint256 deadline
    )
        internal
    {
        uint256 balanceBefore = IERC20(lp).balanceOf(address(this));
        IAdapter(adapter).buy{value: amount}(lp, exchange, minAmountOut, deadline);
        uint256 amountAdded = IERC20(lp).balanceOf(address(this)) - balanceBefore;
        _stake(msg.sender, lp, adapter, amountAdded);
    }

    function _refund(address user, address lp) internal {
        require(totalStaked[lp] > 0, "Not refundable");
        uint256 amount = staked[user][lp];
        require(amount > 0, "No stake");
        delete staked[user][lp];
        totalStaked[lp] -= amount;

        IERC20(lp).safeTransfer(user, amount);
        emit Refunded(lp, amount, user);
    }

    function updateController(address newController)
        external
        onlyOwner
    {
        require(controller != newController, "Controller already exists");
        controller = newController;
    }

    function updateGenericRouter(address newGenericRouter)
        external
        onlyOwner
    {
        require(genericRouter != newGenericRouter, "GenericRouter already exists");
        genericRouter = newGenericRouter;
    }

    function updateCoordinator(address newCoordinator)
        external
        onlyOwner
    {
        require(migrationCoordinator != newCoordinator, "Coordinator already exists");
        migrationCoordinator = newCoordinator;
    }

    function updateEmergencyReceiver(address newReceiver)
        external
        onlyOwner
    {
        require(emergencyReceiver != newReceiver, "Receiver already exists");
        emergencyReceiver = newReceiver;
    }

    function addAdapter(address adapter)
        external
        onlyOwner
    {
        require(!adapters[adapter], "Adapter already exists");
        adapters[adapter] = true;
    }

    function removeAdapter(address adapter)
        external
        onlyOwner
    {
        require(adapters[adapter], "Adapter does not exist");
        adapters[adapter] = false;
    }

    function hasStaked(address account, address lp)
        external
        view
        returns(bool)
    {
        return staked[account][lp] > 0;
    }
}

// SPDX-License-Identifier: WTFPL

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
        // solhint-disable-next-line max-line-length
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
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IAdapter {
    struct Call {
        address target;
        bytes callData;
    }

    function outputTokens(address inputToken) external view returns (address[] memory outputs);

    function encodeMigration(address _genericRouter, address _strategy, address _lp, uint256 _amount)
        external view returns (Call[] memory calls);

    function encodeWithdraw(address _lp, uint256 _amount) external view returns (Call[] memory calls);

    function buy(address _lp, address _exchange, uint256 _minAmountOut, uint256 _deadline) external payable;

    function getAmountOut(address _lp, address _exchange, uint256 _amountIn) external returns (uint256);

    function isWhitelisted(address _token) external view returns (bool);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

import "@enso/contracts/contracts/interfaces/IStrategy.sol";
import "@enso/contracts/contracts/interfaces/IStrategyRouter.sol";
import "../../interfaces/IAdapter.sol";
import "../libraries/SafeERC20Transfer.sol";

interface IMigrationController {
    function migrate(
        IStrategy strategy,
        IStrategyRouter genericRouter,
        IERC20 lpToken,
        IAdapter adapter,
        uint256 amount
    ) external;

    function initialized(address strategy) external view returns (bool);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

interface ILiquidityMigrationV2 {
    function setStake(address user, address lp, address adapter, uint256 amount) external;

    function migrateAll(address lp, address adapter) external;
}

// SPDX-License-Identifier: WTFPL
import "./Ownable.sol";
pragma solidity >=0.8.0;


contract Timelocked is Ownable {

    uint256 public unlocked; // timestamp unlock migration
    uint256 public modify;   // timestamp disallow changes

    /**
    * @dev Require unlock time met
    */
    modifier onlyUnlocked() {
        require(block.timestamp >= unlocked, "Timelock#onlyUnlocked: not unlocked");
        _;
    }

    /**
    * @dev Require modifier time not met
    */
    modifier onlyModify() {
        require(block.timestamp < modify, "Timelock#onlyModify: cannot modify");
        _;
    }

    constructor(uint256 unlock_, uint256 modify_, address owner_) {
        require(unlock_ > block.timestamp, 'Timelock#not greater');
        unlocked = unlock_;
        modify = modify_;
        _setOwner(owner_);
    }

    function updateUnlock(
        uint256 unlock_
    ) 
        public
        onlyOwner
        onlyModify
    {
        unlocked = unlock_;
    }
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.6.0 <0.9.0;

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

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.6.0 <0.9.0;

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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
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

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IStrategyToken.sol";
import "./IOracle.sol";
import "./IWhitelist.sol";
import "../helpers/StrategyTypes.sol";

interface IStrategy is IStrategyToken, StrategyTypes {
    function approveToken(
        address token,
        address account,
        uint256 amount
    ) external;

    function approveDebt(
        address token,
        address account,
        uint256 amount
    ) external;

    function approveSynths(
        address account,
        uint256 amount
    ) external;

    function setStructure(StrategyItem[] memory newItems) external;

    function setCollateral(address token) external;

    function withdrawAll(uint256 amount) external;

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external returns (uint256);

    function delegateSwap(
        address adapter,
        uint256 amount,
        address tokenIn,
        address tokenOut
    ) external;

    function settleSynths() external;

    function issueStreamingFee() external;

    function updateTokenValue(uint256 total, uint256 supply) external;

    function updatePerformanceFee(uint16 fee) external;

    function updateRebalanceThreshold(uint16 threshold) external;

    function updateTradeData(address item, TradeData memory data) external;

    function lock() external;

    function unlock() external;

    function locked() external view returns (bool);

    function items() external view returns (address[] memory);

    function synths() external view returns (address[] memory);

    function debt() external view returns (address[] memory);

    function rebalanceThreshold() external view returns (uint256);

    function performanceFee() external view returns (uint256);

    function getPercentage(address item) external view returns (int256);

    function getTradeData(address item) external view returns (TradeData memory);

    function getPerformanceFeeOwed(address account) external view returns (uint256);

    function controller() external view returns (address);

    function manager() external view returns (address);

    function oracle() external view returns (IOracle);

    function whitelist() external view returns (IWhitelist);

    function supportsSynths() external view returns (bool);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

import "../interfaces/IStrategyController.sol";

interface IStrategyRouter {
    enum RouterCategory {GENERIC, LOOP, SYNTH, BATCH}

    function rebalance(address strategy, bytes calldata data) external;

    function restructure(address strategy, bytes calldata data) external;

    function deposit(address strategy, bytes calldata data) external;

    function withdraw(address strategy, bytes calldata) external;

    function controller() external view returns (IStrategyController);

    function category() external view returns (RouterCategory);
}

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.6.0 <0.9.0;

import "../../ecosystem/openzeppelin/token/ERC20/IERC20.sol";
import "../../ecosystem/openzeppelin/utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Transfer {
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
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

import "./IERC20NonStandard.sol";

interface IStrategyToken is IERC20NonStandard {
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function nonces(address owner) external view returns (uint256);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./registries/ITokenRegistry.sol";
import "./IStrategy.sol";

interface IOracle {
    function weth() external view returns (address);

    function susd() external view returns (address);

    function tokenRegistry() external view returns (ITokenRegistry);

    function estimateStrategy(IStrategy strategy) external view returns (uint256, int256[] memory);

    function estimateItem(
        uint256 balance,
        address token
    ) external view returns (int256);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

interface IWhitelist {
    function approve(address account) external;

    function revoke(address account) external;

    function approved(address account) external view returns (bool);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

interface StrategyTypes {

    enum ItemCategory {BASIC, SYNTH, DEBT, RESERVE}
    enum EstimatorCategory {
      DEFAULT_ORACLE,
      CHAINLINK_ORACLE,
      UNISWAP_TWAP_ORACLE,
      SUSHI_TWAP_ORACLE,
      STRATEGY,
      BLOCKED,
      AAVE_V1,
      AAVE_V2,
      AAVE_DEBT,
      BALANCER,
      COMPOUND,
      CURVE,
      CURVE_GAUGE,
      SUSHI_LP,
      SUSHI_FARM,
      UNISWAP_V2_LP,
      UNISWAP_V3_LP,
      YEARN_V1,
      YEARN_V2
    }
    enum TimelockCategory {RESTRUCTURE, THRESHOLD, REBALANCE_SLIPPAGE, RESTRUCTURE_SLIPPAGE, TIMELOCK, PERFORMANCE}

    struct StrategyItem {
        address item;
        int256 percentage;
        TradeData data;
    }

    struct TradeData {
        address[] adapters;
        address[] path;
        bytes cache;
    }

    struct InitialState {
        uint32 timelock;
        uint16 rebalanceThreshold;
        uint16 rebalanceSlippage;
        uint16 restructureSlippage;
        uint16 performanceFee;
        bool social;
        bool set;
    }

    struct StrategyState {
        uint32 timelock;
        uint16 rebalanceSlippage;
        uint16 restructureSlippage;
        bool social;
        bool set;
    }

    /**
        @notice A time lock requirement for changing the state of this Strategy
        @dev WARNING: Only one TimelockCategory can be pending at a time
    */
    struct Timelock {
        TimelockCategory category;
        uint256 timestamp;
        bytes data;
    }
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

interface IERC20NonStandard {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

import "../IEstimator.sol";

interface ITokenRegistry {
    function itemCategories(address token) external view returns (uint256);

    function estimatorCategories(address token) external view returns (uint256);

    function estimators(uint256 categoryIndex) external view returns (IEstimator);

    function getEstimator(address token) external view returns (IEstimator);

    function addEstimator(uint256 estimatorCategoryIndex, address estimator) external;

    function addItem(uint256 itemCategoryIndex, uint256 estimatorCategoryIndex, address token) external;
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

interface IEstimator {
    function estimateItem(
        uint256 balance,
        address token
    ) external view returns (int256);
}

//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

import "./IStrategy.sol";
import "./IStrategyRouter.sol";
import "./IOracle.sol";
import "./IWhitelist.sol";
import "../helpers/StrategyTypes.sol";

interface IStrategyController is StrategyTypes {
    function setupStrategy(
        address manager_,
        address strategy_,
        InitialState memory state_,
        address router_,
        bytes memory data_
    ) external payable;

    function deposit(
        IStrategy strategy,
        IStrategyRouter router,
        uint256 amount,
        uint256 slippage,
        bytes memory data
    ) external payable;

    function withdrawETH(
        IStrategy strategy,
        IStrategyRouter router,
        uint256 amount,
        uint256 slippage,
        bytes memory data
    ) external;

    function withdrawWETH(
        IStrategy strategy,
        IStrategyRouter router,
        uint256 amount,
        uint256 slippage,
        bytes memory data
    ) external;

    function rebalance(
        IStrategy strategy,
        IStrategyRouter router,
        bytes memory data
    ) external;

    function restructure(
        IStrategy strategy,
        StrategyItem[] memory strategyItems
    ) external;

    function finalizeStructure(
        IStrategy strategy,
        IStrategyRouter router,
        bytes memory data
    ) external;

    function updateValue(
        IStrategy strategy,
        TimelockCategory category,
        uint256 newValue
    ) external;

    function finalizeValue(address strategy) external;

    function openStrategy(IStrategy strategy) external;

    function setStrategy(IStrategy strategy) external;

    function initialized(address strategy) external view returns (bool);

    function strategyState(address strategy) external view returns (StrategyState memory);

    function verifyStructure(address strategy, StrategyItem[] memory newItems)
        external
        view
        returns (bool);

    function oracle() external view returns (IOracle);

    function whitelist() external view returns (IWhitelist);
}

// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.0;

import "../ecosystem/openzeppelin/utils/Context.sol";

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
    function _setOwner(address owner_) 
        internal
    {
        _owner = owner_;
        emit OwnershipTransferred(address(0), owner_);
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

// SPDX-License-Identifier: WTFPL

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}