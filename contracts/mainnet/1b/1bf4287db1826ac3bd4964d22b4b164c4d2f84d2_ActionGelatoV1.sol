// "SPDX-License-Identifier: UNLICENSED"
pragma solidity 0.8.0;

import {
    Address
} from "../../vendor/openzeppelin/contracts/utils/Address.sol";

// Gelato Data Types
struct Provider {
    address addr;  //  if msg.sender == provider => self-Provider
    address module;  //  e.g. DSA Provider Module
}

struct Condition {
    address inst;  // can be AddressZero for self-conditional Actions
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

struct TaskSpec {
    address[] conditions;   // Address: optional AddressZero for self-conditional actions
    Action[] actions;
    uint256 gasPriceCeil;
}

// Gelato Interface
interface IGelatoCore {

    /**
     * @dev API to submit a single Task.
    */
    function submitTask(
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    )
        external;


    /**
     * @dev A Gelato Task Cycle consists of 1 or more Tasks that automatically submit
     * the next one, after they have been executed, where the total number of tasks can
     * be only be an even number
    */
    function submitTaskCycle(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    )
        external;


    /**
     * @dev A Gelato Task Chain consists of 1 or more Tasks that automatically submit
     * the next one, after they have been executed, where the total number of tasks can
     * be an odd number
    */
    function submitTaskChain(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    )
        external;

    /**
     * @dev Cancel multiple tasks at once
    */
    function multiCancelTasks(TaskReceipt[] calldata _taskReceipts) external;

    /**
     * @dev Whitelist new executor, TaskSpec(s) and Module(s) in one tx
    */
    function multiProvide(
        address _executor,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules
    )
        external
        payable;


    /**
     * @dev De-Whitelist TaskSpec(s), Module(s) and withdraw funds from gelato in one tx
    */
    function multiUnprovide(
        uint256 _withdrawAmount,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules
    )
        external;


    /**
     * @dev Deposits funds on Gelato Core
    */
    function provideFunds(address _provider) external payable;

    /**
     * @dev Withdraws funds on Gelato Core
    */
    function unprovideFunds(uint256 _withdrawAmount) external returns(uint256);
}


/// @title ActionGelatoV1
/// @author Hilmar Orth
/// @notice Gelato Action that
contract ActionGelatoV1 {

    using Address for address payable;
    address constant GELATO_CORE = 0x025030BdAa159f281cAe63873E68313a703725A5;

    // ===== Gelato ENTRY APIs ======

    /**
     * @dev Enables first time users to  pre-fund eth, whitelist an executor & register the
     * ProviderModuleDSA.sol to be able to use Gelato
     * @param _executor address of single execot node or gelato'S decentralized execution market
     * @param _taskSpecs enables external providers to whitelist TaskSpecs on gelato
     * @param _modules address of ProviderModuleDSA
     * @param _ethToDeposit amount of eth to deposit on Gelato, only for self-providers
     */
    function multiProvide(
        address _executor,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules,
        uint256 _ethToDeposit
    ) external payable {
        uint256 ethToDeposit = _ethToDeposit == type(uint256).max
            ? address(this).balance
            : _ethToDeposit;

        IGelatoCore(GELATO_CORE).multiProvide{value: ethToDeposit}(
            _executor,
            _taskSpecs,
            _modules
        );
    }

    /**
     * @dev Deposit Funds on Gelato to a given address
     * @param _provider address of balance to top up on Gelato
     * @param _ethToDeposit amount of eth to deposit on Gelato
     */
    function provideFunds(
        address _provider,
        uint256 _ethToDeposit
    ) external payable {
        uint256 ethToDeposit = _ethToDeposit == type(uint256).max
            ? address(this).balance
            : _ethToDeposit;

        IGelatoCore(GELATO_CORE).provideFunds{value: ethToDeposit}(
            _provider
        );
    }

    /**
     * @dev Withdraw funds previously deposited on Gelato
     * @param _ethToWithdraw amount of eth to withdraw from Gelato
     */
    function unprovideFunds(
        uint256 _ethToWithdraw,
        address payable _receiver
    ) external payable {
        uint256 withdrawAmount = IGelatoCore(GELATO_CORE).unprovideFunds(
            _ethToWithdraw
        );
        if (_receiver != address(0) && _receiver != address(this))
            _receiver.sendValue(withdrawAmount);
    }

    /**
     * @dev Submits a single, one-time task to Gelato
     * @param _provider Consists of proxy module address (DSA) and provider address ()
     * who will pay for the transaction execution
     * @param _task Task specifying the condition and the action connectors
     * @param _expiryDate Default 0, othweise timestamp after which the task expires
     */
    function submitTask(
        Provider calldata _provider,
        Task calldata _task,
        uint256 _expiryDate
    ) external payable {
        IGelatoCore(GELATO_CORE).submitTask(_provider, _task, _expiryDate);
    }

    /**
     * @dev Submits single or mulitple Task Sequences to Gelato
     * @param _provider Consists of proxy module address (DSA) and provider address ()
     * who will pay for the transaction execution
     * @param _tasks A sequence of Tasks, can be a single or multiples
     * @param _expiryDate Default 0, othweise timestamp after which the task expires
     * @param _cycles How often the Task List should be executed, e.g. 5 times
     */
    function submitTaskCycle(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _cycles
    ) external payable {
        IGelatoCore(GELATO_CORE).submitTaskCycle(
            _provider,
            _tasks,
            _expiryDate,
            _cycles
        );
    }

    /**
     * @dev Submits single or mulitple Task Chains to Gelato
     * @param _provider Consists of proxy module address (DSA) and provider address ()
     * who will pay for the transaction execution
     * @param _tasks A sequence of Tasks, can be a single or multiples
     * @param _expiryDate Default 0, othweise timestamp after which the task expires
     * @param _sumOfRequestedTaskSubmits The TOTAL number of Task auto-submits
     * that should have occured once the cycle is complete
     */
    function submitTaskChain(
        Provider calldata _provider,
        Task[] calldata _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits
    ) external payable {
        IGelatoCore(GELATO_CORE).submitTaskChain(
            _provider,
            _tasks,
            _expiryDate,
            _sumOfRequestedTaskSubmits
        );
    }

    // ===== Gelato EXIT APIs ======

    /**
     * @dev Withdraws funds from Gelato, de-whitelists TaskSpecs and Provider Modules
     * in one tx
     * @param _withdrawAmount Amount of ETH to withdraw from Gelato
     * @param _taskSpecs List of Task Specs to de-whitelist, default empty []
     * @param _modules List of Provider Modules to de-whitelist, default empty []
     */
    function multiUnprovide(
        uint256 _withdrawAmount,
        TaskSpec[] calldata _taskSpecs,
        address[] calldata _modules
    ) external payable {

        IGelatoCore(GELATO_CORE).multiUnprovide(
            _withdrawAmount,
            _taskSpecs,
            _modules
        );
    }

    /**
     * @dev Cancels outstanding Tasks
     * @param _taskReceipts List of Task Receipts to cancel
     */
    function multiCancelTasks(TaskReceipt[] calldata _taskReceipts)
        external payable
    {
        IGelatoCore(GELATO_CORE).multiCancelTasks(_taskReceipts);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) =
            target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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