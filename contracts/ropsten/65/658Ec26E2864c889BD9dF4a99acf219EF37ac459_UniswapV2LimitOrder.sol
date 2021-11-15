// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.6.10;
pragma experimental ABIEncoderV2;

/// @title IGelatoCondition - solidity interface of GelatoConditionsStandard
/// @notice all the APIs of GelatoConditionsStandard
/// @dev all the APIs are implemented inside GelatoConditionsStandard
interface IGelatoCondition {

    /// @notice GelatoCore calls this to verify securely the specified Condition securely
    /// @dev Be careful only to encode a Task's condition.data as is and not with the
    ///  "ok" selector or _taskReceiptId, since those two things are handled by GelatoCore.
    /// @param _taskReceiptId This is passed by GelatoCore so we can rely on it as a secure
    ///  source of Task identification.
    /// @param _conditionData This is the Condition.data field developers must encode their
    ///  Condition's specific parameters in.
    /// @param _cycleId For Tasks that are executed as part of a cycle.
    function ok(uint256 _taskReceiptId, bytes calldata _conditionData, uint256 _cycleId)
        external
        view
        returns(string memory);
}

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.6.10;
pragma experimental ABIEncoderV2;

import {IGelatoProviderModule} from "../../gelato_provider_modules/IGelatoProviderModule.sol";
import {IGelatoCondition} from "../../gelato_conditions/IGelatoCondition.sol";

struct Provider {
    address addr;  //  if msg.sender == provider => self-Provider
    IGelatoProviderModule module;  //  can be IGelatoProviderModule(0) for self-Providers
}

struct Condition {
    IGelatoCondition inst;  // can be AddressZero for self-conditional Actions
    bytes data;  // can be bytes32(0) for self-conditional Actions
}

enum Operation { Call, Delegatecall }

enum DataFlow { None, In, Out, InAndOut }

struct Action {
    address addr;
    bytes data;
    Operation operation;
    DataFlow dataFlow;
    uint256 value;
    bool termsOkCheck;
}

struct Task {
    Condition[] conditions;  // optional
    Action[] actions;
    uint256 selfProviderGasLimit;  // optional: 0 defaults to gelatoMaxGas
    uint256 selfProviderGasPriceCeil;  // optional: 0 defaults to NO_CEIL
}

struct TaskReceipt {
    uint256 id;
    address userProxy;
    Provider provider;
    uint256 index;
    Task[] tasks;
    uint256 expiryDate;
    uint256 cycleId;  // auto-filled by GelatoCore. 0 for non-cyclic/chained tasks
    uint256 submissionsLeft;
}

interface IGelatoCore {
    event LogTaskSubmitted(
        uint256 indexed taskReceiptId,
        bytes32 indexed taskReceiptHash,
        TaskReceipt taskReceipt
    );

    event LogExecSuccess(
        address indexed executor,
        uint256 indexed taskReceiptId,
        uint256 executorSuccessFee,
        uint256 sysAdminSuccessFee
    );
    event LogCanExecFailed(
        address indexed executor,
        uint256 indexed taskReceiptId,
        string reason
    );
    event LogExecReverted(
        address indexed executor,
        uint256 indexed taskReceiptId,
        uint256 executorRefund,
        string reason
    );

    event LogTaskCancelled(uint256 indexed taskReceiptId, address indexed cancellor);

    /// @notice API to query whether Task can be submitted successfully.
    /// @dev In submitTask the msg.sender must be the same as _userProxy here.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _userProxy The userProxy from which the task will be submitted.
    /// @param _task Selected provider, conditions, actions, expiry date of the task
    function canSubmitTask(
        address _userProxy,
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    )
        external
        view
        returns(string memory);

    /// @notice API to submit a single Task.
    /// @dev You can let users submit multiple tasks at once by batching calls to this.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task A Gelato Task object: provider, conditions, actions.
    /// @param _expiryDate From then on the task cannot be executed. 0 for infinity.
    function submitTask(
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    )
        external;


    /// @notice A Gelato Task Cycle consists of 1 or more Tasks that automatically submit
    ///  the next one, after they have been executed.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _tasks This can be a single task or a sequence of tasks.
    /// @param _expiryDate  After this no task of the sequence can be executed any more.
    /// @param _cycles How many full cycles will be submitted
    function submitTaskCycle(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        external;


    /// @notice A Gelato Task Cycle consists of 1 or more Tasks that automatically submit
    ///  the next one, after they have been executed.
    /// @dev CAUTION: _sumOfRequestedTaskSubmits does not mean the number of cycles.
    /// @dev If _sumOfRequestedTaskSubmits = 1 && _tasks.length = 2, only the first task
    ///  would be submitted, but not the second
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _tasks This can be a single task or a sequence of tasks.
    /// @param _expiryDate  After this no task of the sequence can be executed any more.
    /// @param _sumOfRequestedTaskSubmits The TOTAL number of Task auto-submits
    ///  that should have occured once the cycle is complete:
    ///  _sumOfRequestedTaskSubmits = 0 => One Task will resubmit the next Task infinitly
    ///  _sumOfRequestedTaskSubmits = 1 => One Task will resubmit no other task
    ///  _sumOfRequestedTaskSubmits = 2 => One Task will resubmit 1 other task
    ///  ...
    function submitTaskChain(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    )
        external;

    // ================  Exec Suite =========================
    /// @notice Off-chain API for executors to check, if a TaskReceipt is executable
    /// @dev GelatoCore checks this during execution, in order to safeguard the Conditions
    /// @param _TR TaskReceipt, consisting of user task, user proxy address and id
    /// @param _gasLimit Task.selfProviderGasLimit is used for SelfProviders. All other
    ///  Providers must use gelatoMaxGas. If the _gasLimit is used by an Executor and the
    ///  tx reverts, a refund is paid by the Provider and the TaskReceipt is annulated.
    /// @param _execTxGasPrice Must be used by Executors. Gas Price fed by gelatoCore's
    ///  Gas Price Oracle. Executors can query the current gelatoGasPrice from events.
    function canExec(TaskReceipt calldata _TR, uint256 _gasLimit, uint256 _execTxGasPrice)
        external
        view
        returns(string memory);

    /// @notice Executors call this when Conditions allow it to execute submitted Tasks.
    /// @dev Executors get rewarded for successful Execution. The Task remains open until
    ///   successfully executed, or when the execution failed, despite of gelatoMaxGas usage.
    ///   In the latter case Executors are refunded by the Task Provider.
    /// @param _TR TaskReceipt: id, userProxy, Task.
    function exec(TaskReceipt calldata _TR) external;

    /// @notice Cancel task
    /// @dev Callable only by userProxy or selected provider
    /// @param _TR TaskReceipt: id, userProxy, Task.
    function cancelTask(TaskReceipt calldata _TR) external;

    /// @notice Cancel multiple tasks at once
    /// @dev Callable only by userProxy or selected provider
    /// @param _taskReceipts TaskReceipts: id, userProxy, Task.
    function multiCancelTasks(TaskReceipt[] calldata _taskReceipts) external;

    /// @notice Compute hash of task receipt
    /// @param _TR TaskReceipt, consisting of user task, user proxy address and id
    /// @return hash of taskReceipt
    function hashTaskReceipt(TaskReceipt calldata _TR) external pure returns(bytes32);

    // ================  Getters =========================
    /// @notice Returns the taskReceiptId of the last TaskReceipt submitted
    /// @return currentId currentId, last TaskReceiptId submitted
    function currentTaskReceiptId() external view returns(uint256);

    /// @notice Returns computed taskReceipt hash, used to check for taskReceipt validity
    /// @param _taskReceiptId Id of taskReceipt emitted in submission event
    /// @return hash of taskReceipt
    function taskReceiptHash(uint256 _taskReceiptId) external view returns(bytes32);
}

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.6.10;
pragma experimental ABIEncoderV2;

import {Action, Task} from "../gelato_core/interfaces/IGelatoCore.sol";

interface IGelatoProviderModule {

    /// @notice Check if provider agrees to pay for inputted task receipt
    /// @dev Enables arbitrary checks by provider
    /// @param _userProxy The smart contract account of the user who submitted the Task.
    /// @param _provider The account of the Provider who uses the ProviderModule.
    /// @param _task Gelato Task to be executed.
    /// @return "OK" if provider agrees
    function isProvided(address _userProxy, address _provider, Task calldata _task)
        external
        view
        returns(string memory);

    /// @notice Convert action specific payload into proxy specific payload
    /// @dev Encoded multiple actions into a multisend
    /// @param _taskReceiptId Unique ID of Gelato Task to be executed.
    /// @param _userProxy The smart contract account of the user who submitted the Task.
    /// @param _provider The account of the Provider who uses the ProviderModule.
    /// @param _task Gelato Task to be executed.
    /// @param _cycleId For Tasks that form part of a cycle/chain.
    /// @return Encoded payload that will be used for low-level .call on user proxy
    /// @return checkReturndata if true, fwd returndata from userProxy.call to ProviderModule
    function execPayload(
        uint256 _taskReceiptId,
        address _userProxy,
        address _provider,
        Task calldata _task,
        uint256 _cycleId
    )
        external
        view
        returns(bytes memory, bool checkReturndata);

    /// @notice Called by GelatoCore.exec to verifiy that no revert happend on userProxy
    /// @dev If a caught revert is detected, this fn should revert with the detected error
    /// @param _proxyReturndata Data from GelatoCore._exec.userProxy.call(execPayload)
    function execRevertCheck(bytes calldata _proxyReturndata) external pure;
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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
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
pragma solidity 0.8.3;

address constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import {IUniswapV2Router02} from "../interfaces/uniswap/IUniswapV2Router02.sol";
import {ETH} from "../constants/CTokens.sol";
import {_transferETHOrToken} from "../functions/FTransferUtils.sol";
import {_swapExactTokensForETH} from "../functions/FUniswapV2.sol";
import {IGelato} from "../interfaces/gelato/IGelato.sol";
import {IOracleAggregator} from "../interfaces/gelato/IOracleAggregator.sol";

function _payGelatoFee(
    address _gelato,
    IUniswapV2Router02 _uniRouter,
    address _feeToken,
    uint256 _feeAmt,
    uint256 _feeAmtOutMinIfSwapped
) returns (address feeToken, uint256 feeAmt) {
    if (_isTokenListed(_gelato, _feeToken, ETH, _feeAmt)) {
        _transferETHOrToken(payable(_gelato), _feeToken, _feeAmt);
    } else {
        address[] memory path = new address[](2);
        path[0] = _feeToken;
        path[1] = _uniRouter.WETH();
        feeAmt = _swapExactTokensForETH(
            _uniRouter,
            _feeAmt,
            _feeAmtOutMinIfSwapped,
            path,
            _gelato,
            block.timestamp + 1 // solhint-disable-line not-rely-on-time
        );
        feeToken = ETH;
    }
}

function _isTokenListed(
    address _gelato,
    address _inToken,
    address _outToken,
    uint256 _amt
) view returns (bool) {
    (uint256 amtOut, ) =
        IOracleAggregator(IGelato(_gelato).getOracleAggregator())
            .getExpectedReturnAmount(_amt, _inToken, _outToken);
    return amtOut != 0;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import {
    Address,
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ETH} from "../constants/CTokens.sol";

function _transferETHOrToken(
    address _token,
    address _to,
    uint256 _amt
) {
    if (_token == ETH) Address.sendValue(payable(_to), _amt);
    else SafeERC20.safeTransfer(IERC20(_token), _to, _amt);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import {
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {GelatoString} from "../lib/GelatoString.sol";
import {IUniswapV2Router02} from "../interfaces/uniswap/IUniswapV2Router02.sol";
import {ETH} from "../constants/CTokens.sol";

// solhint-disable-next-line function-max-lines
function _swapExactXForX(
    IUniswapV2Router02 _uniRouter,
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] memory _path,
    address _to,
    uint256 _deadline
) returns (uint256) {
    if (_path[0] == ETH) {
        _path[0] = _uniRouter.WETH();
        return
            _swapExactETHForTokens(
                _uniRouter,
                _amountIn,
                _amountOutMin,
                _path,
                _to,
                _deadline
            );
    }

    SafeERC20.safeIncreaseAllowance(
        IERC20(_path[0]),
        address(_uniRouter),
        _amountIn
    );

    if (_path[_path.length - 1] == ETH) {
        _path[_path.length - 1] = _uniRouter.WETH();
        return
            _swapExactTokensForETH(
                _uniRouter,
                _amountIn,
                _amountOutMin,
                _path,
                _to,
                _deadline
            );
    }

    return
        _swapExactTokensForTokens(
            _uniRouter,
            _amountIn,
            _amountOutMin,
            _path,
            _to,
            _deadline
        );
}

// solhint-disable-next-line function-max-lines
function _swapExactETHForTokens(
    IUniswapV2Router02 _uniRouter,
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] memory _path, // must be ETH-WETH SANITIZED!
    address _to,
    uint256 _deadline
) returns (uint256 amountOut) {
    try
        _uniRouter.swapExactETHForTokens{value: _amountIn}(
            _amountOutMin,
            _path,
            _to,
            _deadline
        )
    returns (uint256[] memory amounts) {
        amountOut = amounts[amounts.length - 1];
    } catch Error(string memory error) {
        GelatoString.revertWithInfo(error, "_swapExactETHForTokens:");
    } catch {
        revert("_swapExactETHForTokens:undefined");
    }
}

function _swapExactTokensForETH(
    IUniswapV2Router02 _uniRouter,
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] memory _path, // must be ETH-WETH SANITIZED!
    address _to,
    uint256 _deadline
) returns (uint256 amountOut) {
    try
        _uniRouter.swapExactTokensForETH(
            _amountIn,
            _amountOutMin,
            _path,
            _to,
            _deadline
        )
    returns (uint256[] memory amounts) {
        amountOut = amounts[amounts.length - 1];
    } catch Error(string memory error) {
        GelatoString.revertWithInfo(error, "_swapExactTokensForETH:");
    } catch {
        revert("_swapExactTokensForETH:undefined");
    }
}

function _swapExactTokensForTokens(
    IUniswapV2Router02 _uniRouter,
    uint256 _amountIn,
    uint256 _amountOutMin,
    address[] memory _path, // must be ETH-WETH SANITIZED!
    address _to,
    uint256 _deadline
) returns (uint256 amountOut) {
    try
        _uniRouter.swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            _path,
            _to,
            _deadline
        )
    returns (uint256[] memory amounts) {
        amountOut = amounts[amounts.length - 1];
    } catch Error(string memory error) {
        GelatoString.revertWithInfo(error, "_swapExactTokensForTokens:");
    } catch {
        revert("_swapExactTokensForTokens:undefined");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import {IDiamondCut} from "./standard/IDiamondCut.sol";
import {IDiamondLoupe} from "./standard/IDiamondLoupe.sol";
import {
    TaskReceipt
} from "@gelatonetwork/core/contracts/gelato_core/interfaces/IGelatoCore.sol";
import {IGelatoV1} from "./IGelatoV1.sol";

// solhint-disable ordering

/// @dev includes the interfaces of all facets
interface IGelato {
    // ########## Diamond Cut Facet #########
    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    function diamondCut(
        IDiamondCut.FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    // ########## DiamondLoupeFacet #########
    function facets()
        external
        view
        returns (IDiamondLoupe.Facet[] memory facets_);

    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);

    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool);

    // ########## Ownership Facet #########
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function transferOwnership(address _newOwner) external;

    function owner() external view returns (address owner_);

    // ########## AddressFacet #########
    event LogSetOracleAggregator(address indexed oracleAggregator);
    event LogSetGasPriceOracle(address indexed gasPriceOracle);

    function setOracleAggregator(address _oracleAggregator)
        external
        returns (address);

    function setGasPriceOracle(address _gasPriceOracle)
        external
        returns (address);

    function getOracleAggregator() external view returns (address);

    function getGasPriceOracle() external view returns (address);

    // ########## ConcurrentCanExecFacet #########
    enum SlotStatus {Open, Closing, Closed}

    function setSlotLength(uint256 _slotLength) external;

    function slotLength() external view returns (uint256);

    function concurrentCanExec(uint256 _buffer) external view returns (bool);

    function getCurrentExecutorIndex()
        external
        view
        returns (uint256 executorIndex, uint256 remainingBlocksInSlot);

    function currentExecutor()
        external
        view
        returns (
            address executor,
            uint256 executorIndex,
            uint256 remainingBlocksInSlot
        );

    function mySlotStatus(uint256 _buffer) external view returns (SlotStatus);

    function calcExecutorIndex(
        uint256 _currentBlock,
        uint256 _blocksPerSlot,
        uint256 _numberOfExecutors
    )
        external
        pure
        returns (uint256 executorIndex, uint256 remainingBlocksInSlot);

    // ########## ExecFacet #########
    event LogExecSuccess(
        address indexed executor,
        address indexed service,
        bool indexed wasExecutorPaid
    );

    event LogSetGasMargin(uint256 oldGasMargin, uint256 newGasMargin);

    function addExecutors(address[] calldata _executors) external;

    function removeExecutors(address[] calldata _executors) external;

    function setGasMargin(uint256 _gasMargin) external;

    function exec(
        address _service,
        bytes calldata _data,
        address _creditToken
    ) external;

    function estimateExecGasDebit(
        address _service,
        bytes calldata _data,
        address _creditToken
    ) external returns (uint256 gasDebitInETH, uint256 gasDebitInCreditToken);

    function canExec(address _executor) external view returns (bool);

    function isExecutor(address _executor) external view returns (bool);

    function executors() external view returns (address[] memory);

    function numberOfExecutors() external view returns (uint256);

    function gasMargin() external view returns (uint256);

    // ########## GelatoV1Facet #########
    struct Response {
        uint256 taskReceiptId;
        uint256 taskGasLimit;
        string response;
    }

    function stakeExecutor(IGelatoV1 _gelatoCore) external payable;

    function unstakeExecutor(IGelatoV1 _gelatoCore, address payable _to)
        external;

    function multiReassignProviders(
        IGelatoV1 _gelatoCore,
        address[] calldata _providers,
        address _newExecutor
    ) external;

    function providerRefund(
        IGelatoV1 _gelatoCore,
        address _provider,
        uint256 _amount
    ) external;

    function withdrawExcessExecutorStake(
        IGelatoV1 _gelatoCore,
        uint256 _withdrawAmount,
        address payable _to
    ) external;

    function v1ConcurrentMultiCanExec(
        address _gelatoCore,
        TaskReceipt[] calldata _taskReceipts,
        uint256 _gelatoGasPrice,
        uint256 _buffer
    )
        external
        view
        returns (
            bool canExecRes,
            uint256 blockNumber,
            Response[] memory responses
        );

    function v1MultiCanExec(
        address _gelatoCore,
        TaskReceipt[] calldata _taskReceipts,
        uint256 _gelatoGasPrice
    ) external view returns (uint256 blockNumber, Response[] memory responses);

    function getGasLimit(
        TaskReceipt calldata _taskReceipt,
        uint256 _gelatoMaxGas
    ) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
// solhint-disable
pragma solidity >=0.6.10;
pragma experimental ABIEncoderV2;

import {
    Action,
    Provider,
    Task,
    DataFlow,
    TaskReceipt
} from "@gelatonetwork/core/contracts/gelato_core/interfaces/IGelatoCore.sol";

// TaskSpec - Will be whitelised by providers and selected by users
struct TaskSpec {
    IGelatoCondition[] conditions; // Address: optional AddressZero for self-conditional actions
    Action[] actions;
    uint256 gasPriceCeil;
}

interface IGelatoV1 {
    /// @notice API to query whether Task can be submitted successfully.
    /// @dev In submitTask the msg.sender must be the same as _userProxy here.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _userProxy The userProxy from which the task will be submitted.
    /// @param _task Selected provider, conditions, actions, expiry date of the task
    function canSubmitTask(
        address _userProxy,
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    ) external view returns (string memory);

    /// @notice API to submit a single Task.
    /// @dev You can let users submit multiple tasks at once by batching calls to this.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task A Gelato Task object: provider, conditions, actions.
    /// @param _expiryDate From then on the task cannot be executed. 0 for infinity.
    function submitTask(
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    ) external;

    /// @notice A Gelato Task Cycle consists of 1 or more Tasks that automatically submit
    ///  the next one, after they have been executed.
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _tasks This can be a single task or a sequence of tasks.
    /// @param _expiryDate  After this no task of the sequence can be executed any more.
    /// @param _cycles How many full cycles will be submitted
    function submitTaskCycle(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    ) external;

    /// @notice A Gelato Task Cycle consists of 1 or more Tasks that automatically submit
    ///  the next one, after they have been executed.
    /// @dev CAUTION: _sumOfRequestedTaskSubmits does not mean the number of cycles.
    /// @dev If _sumOfRequestedTaskSubmits = 1 && _tasks.length = 2, only the first task
    ///  would be submitted, but not the second
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _tasks This can be a single task or a sequence of tasks.
    /// @param _expiryDate  After this no task of the sequence can be executed any more.
    /// @param _sumOfRequestedTaskSubmits The TOTAL number of Task auto-submits
    ///  that should have occured once the cycle is complete:
    ///  _sumOfRequestedTaskSubmits = 0 => One Task will resubmit the next Task infinitly
    ///  _sumOfRequestedTaskSubmits = 1 => One Task will resubmit no other task
    ///  _sumOfRequestedTaskSubmits = 2 => One Task will resubmit 1 other task
    ///  ...
    function submitTaskChain(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    ) external;

    // ================  Exec Suite =========================
    /// @notice Off-chain API for executors to check, if a TaskReceipt is executable
    /// @dev GelatoCore checks this during execution, in order to safeguard the Conditions
    /// @param _TR TaskReceipt, consisting of user task, user proxy address and id
    /// @param _gasLimit Task.selfProviderGasLimit is used for SelfProviders. All other
    ///  Providers must use gelatoMaxGas. If the _gasLimit is used by an Executor and the
    ///  tx reverts, a refund is paid by the Provider and the TaskReceipt is annulated.
    /// @param _execTxGasPrice Must be used by Executors. Gas Price fed by gelatoCore's
    ///  Gas Price Oracle. Executors can query the current gelatoGasPrice from events.
    function canExec(
        TaskReceipt calldata _TR,
        uint256 _gasLimit,
        uint256 _execTxGasPrice
    ) external view returns (string memory);

    /// @notice Executors call this when Conditions allow it to execute submitted Tasks.
    /// @dev Executors get rewarded for successful Execution. The Task remains open until
    ///   successfully executed, or when the execution failed, despite of gelatoMaxGas usage.
    ///   In the latter case Executors are refunded by the Task Provider.
    /// @param _TR TaskReceipt: id, userProxy, Task.
    function exec(TaskReceipt calldata _TR) external;

    /// @notice Cancel task
    /// @dev Callable only by userProxy or selected provider
    /// @param _TR TaskReceipt: id, userProxy, Task.
    function cancelTask(TaskReceipt calldata _TR) external;

    /// @notice Cancel multiple tasks at once
    /// @dev Callable only by userProxy or selected provider
    /// @param _taskReceipts TaskReceipts: id, userProxy, Task.
    function multiCancelTasks(TaskReceipt[] calldata _taskReceipts) external;

    /// @notice Compute hash of task receipt
    /// @param _TR TaskReceipt, consisting of user task, user proxy address and id
    /// @return hash of taskReceipt
    function hashTaskReceipt(TaskReceipt calldata _TR)
        external
        pure
        returns (bytes32);

    // ================  Getters =========================
    /// @notice Returns the taskReceiptId of the last TaskReceipt submitted
    /// @return currentId currentId, last TaskReceiptId submitted
    function currentTaskReceiptId() external view returns (uint256);

    /// @notice Returns computed taskReceipt hash, used to check for taskReceipt validity
    /// @param _taskReceiptId Id of taskReceipt emitted in submission event
    /// @return hash of taskReceipt
    function taskReceiptHash(uint256 _taskReceiptId)
        external
        view
        returns (bytes32);

    /// @notice Stake on Gelato to become a whitelisted executor
    /// @dev Msg.value has to be >= minExecutorStake
    function stakeExecutor() external payable;

    /// @notice Unstake on Gelato to become de-whitelisted and withdraw minExecutorStake
    function unstakeExecutor() external;

    /// @notice Re-assigns multiple providers to other executors
    /// @dev Executors must re-assign all providers before being able to unstake
    /// @param _providers List of providers to re-assign
    /// @param _newExecutor Address of new executor to assign providers to
    function multiReassignProviders(
        address[] calldata _providers,
        address _newExecutor
    ) external;

    /// @notice Withdraw excess Execur Stake
    /// @dev Can only be called if executor is isExecutorMinStaked
    /// @param _withdrawAmount Amount to withdraw
    /// @return Amount that was actually withdrawn
    function withdrawExcessExecutorStake(uint256 _withdrawAmount)
        external
        returns (uint256);

    // =========== GELATO PROVIDER APIs ==============

    /// @notice Validation that checks whether Task Spec is being offered by the selected provider
    /// @dev Checked in submitTask(), unless provider == userProxy
    /// @param _provider Address of selected provider
    /// @param _taskSpec Task Spec
    /// @return Expected to return "OK"
    function isTaskSpecProvided(address _provider, TaskSpec calldata _taskSpec)
        external
        view
        returns (string memory);

    /// @notice Validates that provider has provider module whitelisted + conducts isProvided check in ProviderModule
    /// @dev Checked in submitTask() if provider == userProxy
    /// @param _userProxy userProxy passed by GelatoCore during submission and exec
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task Task defined in IGelatoCore
    /// @return Expected to return "OK"
    function providerModuleChecks(
        address _userProxy,
        Provider calldata _provider,
        Task calldata _task
    ) external view returns (string memory);

    /// @notice Validate if provider module and seleced TaskSpec is whitelisted by provider
    /// @dev Combines "isTaskSpecProvided" and providerModuleChecks
    /// @param _userProxy userProxy passed by GelatoCore during submission and exec
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task Task defined in IGelatoCore
    /// @return res Expected to return "OK"
    function isTaskProvided(
        address _userProxy,
        Provider calldata _provider,
        Task calldata _task
    ) external view returns (string memory res);

    /// @notice Validate if selected TaskSpec is whitelisted by provider and that current gelatoGasPrice is below GasPriceCeil
    /// @dev If gasPriceCeil is != 0, Task Spec is whitelisted
    /// @param _userProxy userProxy passed by GelatoCore during submission and exec
    /// @param _provider Gelato Provider object: provider address and module.
    /// @param _task Task defined in IGelatoCore
    /// @param _gelatoGasPrice Task Receipt defined in IGelatoCore
    /// @return res Expected to return "OK"
    function providerCanExec(
        address _userProxy,
        Provider calldata _provider,
        Task calldata _task,
        uint256 _gelatoGasPrice
    ) external view returns (string memory res);

    // =========== PROVIDER STATE WRITE APIs ==============
    // Provider Funding
    /// @notice Deposit ETH as provider on Gelato
    /// @param _provider Address of provider who receives ETH deposit
    function provideFunds(address _provider) external payable;

    /// @notice Withdraw provider funds from gelato
    /// @param _withdrawAmount Amount
    /// @return amount that will be withdrawn
    function unprovideFunds(uint256 _withdrawAmount) external returns (uint256);

    /// @notice Assign executor as provider
    /// @param _executor Address of new executor
    function providerAssignsExecutor(address _executor) external;

    /// @notice Assign executor as previous selected executor
    /// @param _provider Address of provider whose executor to change
    /// @param _newExecutor Address of new executor
    function executorAssignsExecutor(address _provider, address _newExecutor)
        external;

    // (Un-)provide Task Spec

    /// @notice Whitelist TaskSpecs (A combination of a Condition, Action(s) and a gasPriceCeil) that users can select from
    /// @dev If gasPriceCeil is == 0, Task Spec will be executed at any gas price (no ceil)
    /// @param _taskSpecs Task Receipt List defined in IGelatoCore
    function provideTaskSpecs(TaskSpec[] calldata _taskSpecs) external;

    /// @notice De-whitelist TaskSpecs (A combination of a Condition, Action(s) and a gasPriceCeil) that users can select from
    /// @dev If gasPriceCeil was set to NO_CEIL, Input NO_CEIL constant as GasPriceCeil
    /// @param _taskSpecs Task Receipt List defined in IGelatoCore
    function unprovideTaskSpecs(TaskSpec[] calldata _taskSpecs) external;

    /// @notice Update gasPriceCeil of selected Task Spec
    /// @param _taskSpecHash Result of hashTaskSpec()
    /// @param _gasPriceCeil New gas price ceil for Task Spec
    function setTaskSpecGasPriceCeil(
        bytes32 _taskSpecHash,
        uint256 _gasPriceCeil
    ) external;

    // Provider Module
    /// @notice Whitelist new provider Module(s)
    /// @param _modules Addresses of the modules which will be called during providerModuleChecks()
    function addProviderModules(IGelatoProviderModule[] calldata _modules)
        external;

    /// @notice De-Whitelist new provider Module(s)
    /// @param _modules Addresses of the modules which will be removed
    function removeProviderModules(IGelatoProviderModule[] calldata _modules)
        external;

    // Batch (un-)provide

    /// @notice Whitelist new executor, TaskSpec(s) and Module(s) in one tx
    /// @param _executor Address of new executor of provider
    /// @param _taskSpecs List of Task Spec which will be whitelisted by provider
    /// @param _modules List of module addresses which will be whitelisted by provider
    function multiProvide(
        address _executor,
        TaskSpec[] calldata _taskSpecs,
        IGelatoProviderModule[] calldata _modules
    ) external payable;

    /// @notice De-Whitelist TaskSpec(s), Module(s) and withdraw funds from gelato in one tx
    /// @param _withdrawAmount Amount to withdraw from ProviderFunds
    /// @param _taskSpecs List of Task Spec which will be de-whitelisted by provider
    /// @param _modules List of module addresses which will be de-whitelisted by provider
    function multiUnprovide(
        uint256 _withdrawAmount,
        TaskSpec[] calldata _taskSpecs,
        IGelatoProviderModule[] calldata _modules
    ) external;

    // =========== PROVIDER STATE READ APIs ==============
    // Provider Funding

    /// @notice Get balance of provider
    /// @param _provider Address of provider
    /// @return Provider Balance
    function providerFunds(address _provider) external view returns (uint256);

    /// @notice Get min stake required by all providers for executors to call exec
    /// @param _gelatoMaxGas Current gelatoMaxGas
    /// @param _gelatoGasPrice Current gelatoGasPrice
    /// @return How much provider balance is required for executor to submit exec tx
    function minExecProviderFunds(
        uint256 _gelatoMaxGas,
        uint256 _gelatoGasPrice
    ) external view returns (uint256);

    /// @notice Check if provider has sufficient funds for executor to call exec
    /// @param _provider Address of provider
    /// @param _gelatoMaxGas Currentt gelatoMaxGas
    /// @param _gelatoGasPrice Current gelatoGasPrice
    /// @return Whether provider is liquid (true) or not (false)
    function isProviderLiquid(
        address _provider,
        uint256 _gelatoMaxGas,
        uint256 _gelatoGasPrice
    ) external view returns (bool);

    // Executor Stake

    /// @notice Get balance of executor
    /// @param _executor Address of executor
    /// @return Executor Balance
    function executorStake(address _executor) external view returns (uint256);

    /// @notice Check if executor has sufficient stake on gelato
    /// @param _executor Address of provider
    /// @return Whether executor has sufficient stake (true) or not (false)
    function isExecutorMinStaked(address _executor)
        external
        view
        returns (bool);

    /// @notice Get executor of provider
    /// @param _provider Address of provider
    /// @return Provider's executor
    function executorByProvider(address _provider)
        external
        view
        returns (address);

    /// @notice Get num. of providers which haved assigned an executor
    /// @param _executor Address of executor
    /// @return Count of how many providers assigned the executor
    function executorProvidersCount(address _executor)
        external
        view
        returns (uint256);

    /// @notice Check if executor has one or more providers assigned
    /// @param _executor Address of provider
    /// @return Where 1 or more providers have assigned the executor
    function isExecutorAssigned(address _executor) external view returns (bool);

    // Task Spec and Gas Price Ceil
    /// @notice The maximum gas price the transaction will be executed with
    /// @param _provider Address of provider
    /// @param _taskSpecHash Hash of provider TaskSpec
    /// @return Max gas price an executor will execute the transaction with in wei
    function taskSpecGasPriceCeil(address _provider, bytes32 _taskSpecHash)
        external
        view
        returns (uint256);

    /// @notice Returns the hash of the formatted TaskSpec.
    /// @dev The action.data field of each Action is stripped before hashing.
    /// @param _taskSpec TaskSpec
    /// @return keccak256 hash of encoded condition address and Action List
    function hashTaskSpec(TaskSpec calldata _taskSpec)
        external
        view
        returns (bytes32);

    /// @notice Constant used to specify the highest gas price available in the gelato system
    /// @dev Input 0 as gasPriceCeil and it will be assigned to NO_CEIL
    /// @return MAX_UINT
    function NO_CEIL() external pure returns (uint256);

    // Providers' Module Getters

    /// @notice Check if inputted module is whitelisted by provider
    /// @param _provider Address of provider
    /// @param _module Address of module
    /// @return true if it is whitelisted
    function isModuleProvided(address _provider, IGelatoProviderModule _module)
        external
        view
        returns (bool);

    /// @notice Get all whitelisted provider modules from a given provider
    /// @param _provider Address of provider
    /// @return List of whitelisted provider modules
    function providerModules(address _provider)
        external
        view
        returns (IGelatoProviderModule[] memory);

    // State Writing

    /// @notice Assign new gas price oracle
    /// @dev Only callable by sysAdmin
    /// @param _newOracle Address of new oracle
    function setGelatoGasPriceOracle(address _newOracle) external;

    /// @notice Assign new gas price oracle
    /// @dev Only callable by sysAdmin
    /// @param _requestData The encoded payload for the staticcall to the oracle.
    function setOracleRequestData(bytes calldata _requestData) external;

    /// @notice Assign new maximum gas limit providers can consume in executionWrapper()
    /// @dev Only callable by sysAdmin
    /// @param _newMaxGas New maximum gas limit
    function setGelatoMaxGas(uint256 _newMaxGas) external;

    /// @notice Assign new interal gas limit requirement for exec()
    /// @dev Only callable by sysAdmin
    /// @param _newRequirement New internal gas requirement
    function setInternalGasRequirement(uint256 _newRequirement) external;

    /// @notice Assign new minimum executor stake
    /// @dev Only callable by sysAdmin
    /// @param _newMin New minimum executor stake
    function setMinExecutorStake(uint256 _newMin) external;

    /// @notice Assign new success share for executors to receive after successful execution
    /// @dev Only callable by sysAdmin
    /// @param _percentage New % success share of total gas consumed
    function setExecutorSuccessShare(uint256 _percentage) external;

    /// @notice Assign new success share for sysAdmin to receive after successful execution
    /// @dev Only callable by sysAdmin
    /// @param _percentage New % success share of total gas consumed
    function setSysAdminSuccessShare(uint256 _percentage) external;

    /// @notice Withdraw sysAdmin funds
    /// @dev Only callable by sysAdmin
    /// @param _amount Amount to withdraw
    /// @param _to Address to receive the funds
    function withdrawSysAdminFunds(uint256 _amount, address payable _to)
        external
        returns (uint256);

    // State Reading
    /// @notice Unaccounted tx overhead that will be refunded to executors
    function EXEC_TX_OVERHEAD() external pure returns (uint256);

    /// @notice Addess of current Gelato Gas Price Oracle
    function gelatoGasPriceOracle() external view returns (address);

    /// @notice Getter for oracleRequestData state variable
    function oracleRequestData() external view returns (bytes memory);

    /// @notice Gas limit an executor has to submit to get refunded even if actions revert
    function gelatoMaxGas() external view returns (uint256);

    /// @notice Internal gas limit requirements ti ensure executor payout
    function internalGasRequirement() external view returns (uint256);

    /// @notice Minimum stake required from executors
    function minExecutorStake() external view returns (uint256);

    /// @notice % Fee executors get as a reward for a successful execution
    function executorSuccessShare() external view returns (uint256);

    /// @notice Total % Fee executors and sysAdmin collectively get as a reward for a successful execution
    /// @dev Saves a state read
    function totalSuccessShare() external view returns (uint256);

    /// @notice Get total fee providers pay executors for a successful execution
    /// @param _gas Gas consumed by transaction
    /// @param _gasPrice Current gelato gas price
    function executorSuccessFee(uint256 _gas, uint256 _gasPrice)
        external
        view
        returns (uint256);

    /// @notice % Fee sysAdmin gets as a reward for a successful execution
    function sysAdminSuccessShare() external view returns (uint256);

    /// @notice Get total fee providers pay sysAdmin for a successful execution
    /// @param _gas Gas consumed by transaction
    /// @param _gasPrice Current gelato gas price
    function sysAdminSuccessFee(uint256 _gas, uint256 _gasPrice)
        external
        view
        returns (uint256);

    /// @notice Get sysAdminds funds
    function sysAdminFunds() external view returns (uint256);
}

/// @title IGelatoCondition - solidity interface of GelatoConditionsStandard
/// @notice all the APIs of GelatoConditionsStandard
/// @dev all the APIs are implemented inside GelatoConditionsStandard
interface IGelatoCondition {
    /// @notice GelatoCore calls this to verify securely the specified Condition securely
    /// @dev Be careful only to encode a Task's condition.data as is and not with the
    ///  "ok" selector or _taskReceiptId, since those two things are handled by GelatoCore.
    /// @param _taskReceiptId This is passed by GelatoCore so we can rely on it as a secure
    ///  source of Task identification.
    /// @param _conditionData This is the Condition.data field developers must encode their
    ///  Condition's specific parameters in.
    /// @param _cycleId For Tasks that are executed as part of a cycle.
    function ok(
        uint256 _taskReceiptId,
        bytes calldata _conditionData,
        uint256 _cycleId
    ) external view returns (string memory);
}

/// @notice all the APIs and events of GelatoActionsStandard
/// @dev all the APIs are implemented inside GelatoActionsStandard
interface IGelatoAction {
    /// @notice Providers can use this for pre-execution sanity checks, to prevent reverts.
    /// @dev GelatoCore checks this in canExec and passes the parameters.
    /// @param _taskReceiptId The id of the task from which all arguments are passed.
    /// @param _userProxy The userProxy of the task. Often address(this) for delegatecalls.
    /// @param _actionData The encoded payload to be used in the Action.
    /// @param _dataFlow The dataFlow of the Action.
    /// @param _value A special param for ETH sending Actions. If the Action sends ETH
    ///  in its Action function implementation, one should expect msg.value therein to be
    ///  equal to _value. So Providers can check in termsOk that a valid ETH value will
    ///  be used because they also have access to the same value when encoding the
    ///  execPayload on their ProviderModule.
    /// @param _cycleId For tasks that are part of a Cycle.
    /// @return Returns OK, if Task can be executed safely according to the Provider's
    ///  terms laid out in this function implementation.
    function termsOk(
        uint256 _taskReceiptId,
        address _userProxy,
        bytes calldata _actionData,
        DataFlow _dataFlow,
        uint256 _value,
        uint256 _cycleId
    ) external view returns (string memory);
}

interface IGelatoProviderModule {
    /// @notice Check if provider agrees to pay for inputted task receipt
    /// @dev Enables arbitrary checks by provider
    /// @param _userProxy The smart contract account of the user who submitted the Task.
    /// @param _provider The account of the Provider who uses the ProviderModule.
    /// @param _task Gelato Task to be executed.
    /// @return "OK" if provider agrees
    function isProvided(
        address _userProxy,
        address _provider,
        Task calldata _task
    ) external view returns (string memory);

    /// @notice Convert action specific payload into proxy specific payload
    /// @dev Encoded multiple actions into a multisend
    /// @param _taskReceiptId Unique ID of Gelato Task to be executed.
    /// @param _userProxy The smart contract account of the user who submitted the Task.
    /// @param _provider The account of the Provider who uses the ProviderModule.
    /// @param _task Gelato Task to be executed.
    /// @param _cycleId For Tasks that form part of a cycle/chain.
    /// @return Encoded payload that will be used for low-level .call on user proxy
    /// @return checkReturndata if true, fwd returndata from userProxy.call to ProviderModule
    function execPayload(
        uint256 _taskReceiptId,
        address _userProxy,
        address _provider,
        Task calldata _task,
        uint256 _cycleId
    ) external view returns (bytes memory, bool checkReturndata);

    /// @notice Called by GelatoCore.exec to verifiy that no revert happend on userProxy
    /// @dev If a caught revert is detected, this fn should revert with the detected error
    /// @param _proxyReturndata Data from GelatoCore._exec.userProxy.call(execPayload)
    function execRevertCheck(bytes calldata _proxyReturndata) external pure;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @dev Interface of the Oracle Aggregator Contract
 */
interface IOracleAggregator {
    function getExpectedReturnAmount(
        uint256 amount,
        address tokenAddressA,
        address tokenAddressB
    ) external view returns (uint256 returnAmount, uint256 decimals);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.3;

interface IUniswapV2Router02 {
    function swapExactETHForTokens(
        uint256 minAmountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 minAmountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 minAmountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function factory() external pure returns (address);

    // solhint-disable-next-line func-name-mixedcase
    function WETH() external pure returns (address);
}

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.3;

library GelatoString {
    function startsWithOK(string memory _str) internal pure returns (bool) {
        if (
            bytes(_str).length >= 2 &&
            bytes(_str)[0] == "O" &&
            bytes(_str)[1] == "K"
        ) return true;
        return false;
    }

    function revertWithInfo(string memory _error, string memory _tracingInfo)
        internal
        pure
    {
        revert(string(abi.encodePacked(_tracingInfo, _error)));
    }

    function prefix(string memory _second, string memory _first)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_first, _second));
    }

    function suffix(string memory _first, string memory _second)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(_first, _second));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import {ASimpleServiceStandard} from "./abstract/ASimpleServiceStandard.sol";
import {IUniswapV2Router02} from "../interfaces/uniswap/IUniswapV2Router02.sol";
import {
    Address,
    IERC20,
    SafeERC20
} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ETH} from "./../constants/CTokens.sol";
import {_swapExactXForX} from "./../functions/FUniswapV2.sol";
import {_transferETHOrToken} from "./../functions/FTransferUtils.sol";
import {Fee} from "./../structs/SGelato.sol";

contract UniswapV2LimitOrder is ASimpleServiceStandard {
    using Address for address payable;
    using SafeERC20 for IERC20;

    struct Order {
        address[] path;
        uint256 amtIn;
        uint256 amtOutMin;
    }

    event LogSubmit(uint256 indexed id, address indexed user, Order order);

    event LogCancel(uint256 indexed id, address indexed user);

    event LogSwap(
        address indexed user,
        address indexed inToken,
        address indexed outToken,
        uint256 amtIn,
        uint256 amtOut
    );

    constructor(address _gelato, IUniswapV2Router02 _uni)
        ASimpleServiceStandard(_gelato, _uni)
    {} // solhint-disable-line no-empty-blocks

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    // ################ End User APIs ################
    function submit(Order calldata _o)
        external
        payable
        gelatoSubmit(_getPayload(_o))
    {
        if (_o.path[0] == ETH) {
            require(
                msg.value == _o.amtIn,
                "UniswapV2LimitOrder.submit: msg.value != _o.amtIn"
            );
        }
        emit LogSubmit(taskId(), msg.sender, _o);
    }

    function cancel(uint256 _id, Order calldata _o)
        external
        gelatoCancel(_id, _getPayload(_o))
    {
        if (_o.path[0] == ETH) payable(msg.sender).sendValue(_o.amtIn);
        emit LogCancel(_id, msg.sender);
    }

    // solhint-disable-next-line code-complexity
    function modify(
        uint256 _id,
        Order calldata _old,
        Order calldata _new
    ) external payable gelatoModify(_id, _getPayload(_old), _getPayload(_new)) {
        if (_old.path[0] == ETH && _new.path[0] == ETH) {
            if (_new.amtIn > _old.amtIn) {
                require(
                    msg.value == _new.amtIn - _old.amtIn,
                    "UniswapV2LimitOrder.submit: msg.value != _new.amtIn - _old.amtIn"
                );
            } else if (_new.amtIn < _old.amtIn) {
                payable(msg.sender).sendValue(_old.amtIn - _new.amtIn);
            }
        } else if (_old.path[0] == ETH) {
            payable(msg.sender).sendValue(_old.amtIn);
        } else if (_new.path[0] == ETH) {
            require(
                msg.value == _new.amtIn,
                "UniswapV2LimitOrder.modify: msg.value != _new.amtIn"
            );
        }

        emit LogSubmit(_id, msg.sender, _new);
    }

    // ################ Executor APIs ################
    // solhint-disable-next-line function-max-lines
    function exec(
        address _user,
        uint256 _id,
        Order calldata _o,
        Fee calldata _fee
    )
        external
        gelatofy(
            _user,
            _id,
            _getPayload(_o),
            _fee.isOutToken ? _o.path[_o.path.length - 1] : _o.path[0],
            _fee.amt,
            _fee.amtOutMinIfSwapped
        )
    {
        if (_o.path[0] != ETH)
            IERC20(_o.path[0]).safeTransferFrom(_user, address(this), _o.amtIn);

        uint256 amtOut =
            _swapExactXForX(
                UNI_ROUTER,
                _fee.isOutToken ? _o.amtIn : _o.amtIn - _fee.amt,
                _fee.isOutToken ? _o.amtOutMin + _fee.amt : _o.amtOutMin,
                _o.path,
                _fee.isOutToken ? address(this) : _user, // intercept outToken fee
                block.timestamp + 1 // solhint-disable-line not-rely-on-time
            );

        // Deduct Fee if it is paid with outToken and pay out user
        if (_fee.isOutToken) {
            amtOut = amtOut - _fee.amt;
            _transferETHOrToken(
                payable(_user),
                _o.path[_o.path.length - 1],
                amtOut
            );
        }

        emit LogSwap(
            _user,
            _o.path[0],
            _o.path[_o.path.length - 1],
            _fee.isOutToken ? _o.amtIn : _o.amtIn - _fee.amt,
            amtOut
        );
    }

    function isSubmitted(
        address _user,
        uint256 _id,
        Order calldata _o
    ) external view returns (bool) {
        return verifyTask(_user, hashTask(_id, _getPayload(_o)));
    }

    function _getPayload(Order calldata _o)
        private
        pure
        returns (bytes memory)
    {
        return abi.encode(_o);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import {ATaskStorage} from "./ATaskStorage.sol";
import {_transferETHOrToken} from "../../functions/FTransferUtils.sol";
import {Fee} from "../../structs/SGelato.sol";
import {
    IUniswapV2Router02
} from "../../interfaces/uniswap/IUniswapV2Router02.sol";
import {_payGelatoFee} from "../../functions/FGelato.sol";

abstract contract ASimpleServiceStandard is ATaskStorage {
    // solhint-disable  var-name-mixedcase
    address public immutable GELATO;
    IUniswapV2Router02 public immutable UNI_ROUTER;
    // solhint-enable var-name-mixed-case

    event LogExecSuccess(
        uint256 indexed taskId,
        address indexed executor,
        address indexed feeToken,
        uint256 feeAmt
    );

    modifier gelatoSubmit(bytes memory _payload) {
        _storeTask(msg.sender, _payload);
        _;
    }

    modifier gelatoCancel(uint256 _id, bytes memory _payload) {
        _removeTask(_id, msg.sender, _payload);
        _;
    }

    modifier gelatoModify(
        uint256 _taskId,
        bytes memory _payload,
        bytes memory _newPayload
    ) {
        _modifyTask(_taskId, msg.sender, _payload, _newPayload);
        _;
    }

    modifier gelatofy(
        address _user,
        uint256 _id,
        bytes memory _payload,
        address _feeToken,
        uint256 _feeAmt,
        uint256 _feeAmtOutMinIfSwapped
    ) {
        // Only GELATO vetted Executors can call
        require(
            address(GELATO) == msg.sender,
            "ASimpleServiceStandard: msg.sender != gelato"
        );

        // Verifies and removes task
        _removeTask(_id, _user, _payload);

        // Execute Logic
        _;

        // Pay Gelato
        (_feeToken, _feeAmt) = _payGelatoFee(
            GELATO,
            UNI_ROUTER,
            _feeToken,
            _feeAmt,
            _feeAmtOutMinIfSwapped
        );

        emit LogExecSuccess(_id, tx.origin, _feeToken, _feeAmt);
    }

    constructor(address _gelato, IUniswapV2Router02 _uni) {
        GELATO = _gelato;
        UNI_ROUTER = _uni;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

abstract contract ATaskStorage {
    mapping(bytes32 => address) private _taskOwner;
    uint256 private _taskId;

    event LogTaskStored(
        bytes32 indexed taskHash,
        address indexed owner,
        uint256 indexed id,
        bytes payload
    );
    event LogTaskRemoved(
        bytes32 indexed taskHash,
        address indexed owner,
        uint256 indexed id
    );

    function taskOwner(bytes32 _taskHash) public view returns (address) {
        return _taskOwner[_taskHash];
    }

    function taskId() public view returns (uint256) {
        return _taskId;
    }

    function verifyTask(address _owner, bytes32 _taskHash)
        public
        view
        returns (bool)
    {
        return _owner == taskOwner(_taskHash);
    }

    function hashTask(uint256 _id, bytes memory _payload)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_id, _payload));
    }

    function _storeTask(address _owner, bytes memory _payload)
        internal
        returns (uint256 newTaskId)
    {
        newTaskId = ++_taskId;

        bytes32 taskHash = hashTask(_taskId, _payload);
        _taskOwner[taskHash] = _owner;

        emit LogTaskStored(taskHash, _owner, _taskId, _payload);
    }

    function _removeTask(
        uint256 _id,
        address _owner,
        bytes memory _payload
    ) internal {
        bytes32 taskHash = hashTask(_id, _payload);
        require(
            verifyTask(_owner, taskHash),
            "ATaskStorage._removeTask: !taskOwner"
        );
        delete _taskOwner[taskHash];
        emit LogTaskRemoved(taskHash, msg.sender, _id);
    }

    function _modifyTask(
        uint256 _id,
        address _owner,
        bytes memory _payload,
        bytes memory _newPayload
    ) internal {
        _removeTask(_id, _owner, _payload);

        bytes32 taskHash = hashTask(_id, _newPayload);
        _taskOwner[taskHash] = _owner;

        emit LogTaskStored(taskHash, _owner, _id, _newPayload);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

struct Fee {
    bool isOutToken;
    uint256 amt;
    uint256 amtOutMinIfSwapped;
}

