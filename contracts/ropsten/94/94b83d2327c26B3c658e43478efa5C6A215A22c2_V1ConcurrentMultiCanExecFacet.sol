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

interface IGelatoSysAdmin {
    struct GelatoSysAdminInitialState {
        address gelatoGasPriceOracle;
        bytes oracleRequestData;
        uint256 gelatoMaxGas;
        uint256 internalGasRequirement;
        uint256 minExecutorStake;
        uint256 executorSuccessShare;
        uint256 sysAdminSuccessShare;
        uint256 totalSuccessShare;
    }

    // Events
    event LogGelatoGasPriceOracleSet(address indexed oldOracle, address indexed newOracle);
    event LogOracleRequestDataSet(bytes oldData, bytes newData);

    event LogGelatoMaxGasSet(uint256 oldMaxGas, uint256 newMaxGas);
    event LogInternalGasRequirementSet(uint256 oldRequirment, uint256 newRequirment);

    event LogMinExecutorStakeSet(uint256 oldMin, uint256 newMin);

    event LogExecutorSuccessShareSet(uint256 oldShare, uint256 newShare, uint256 total);
    event LogSysAdminSuccessShareSet(uint256 oldShare, uint256 newShare, uint256 total);

    event LogSysAdminFundsWithdrawn(uint256 oldBalance, uint256 newBalance);

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
    function withdrawSysAdminFunds(uint256 _amount, address payable _to) external returns(uint256);

    // State Reading
    /// @notice Unaccounted tx overhead that will be refunded to executors
    function EXEC_TX_OVERHEAD() external pure returns(uint256);

    /// @notice Addess of current Gelato Gas Price Oracle
    function gelatoGasPriceOracle() external view returns(address);

    /// @notice Getter for oracleRequestData state variable
    function oracleRequestData() external view returns(bytes memory);

    /// @notice Gas limit an executor has to submit to get refunded even if actions revert
    function gelatoMaxGas() external view returns(uint256);

    /// @notice Internal gas limit requirements ti ensure executor payout
    function internalGasRequirement() external view returns(uint256);

    /// @notice Minimum stake required from executors
    function minExecutorStake() external view returns(uint256);

    /// @notice % Fee executors get as a reward for a successful execution
    function executorSuccessShare() external view returns(uint256);

    /// @notice Total % Fee executors and sysAdmin collectively get as a reward for a successful execution
    /// @dev Saves a state read
    function totalSuccessShare() external view returns(uint256);

    /// @notice Get total fee providers pay executors for a successful execution
    /// @param _gas Gas consumed by transaction
    /// @param _gasPrice Current gelato gas price
    function executorSuccessFee(uint256 _gas, uint256 _gasPrice)
        external
        view
        returns(uint256);

    /// @notice % Fee sysAdmin gets as a reward for a successful execution
    function sysAdminSuccessShare() external view returns(uint256);

    /// @notice Get total fee providers pay sysAdmin for a successful execution
    /// @param _gas Gas consumed by transaction
    /// @param _gasPrice Current gelato gas price
    function sysAdminSuccessFee(uint256 _gas, uint256 _gasPrice)
        external
        view
        returns(uint256);

    /// @notice Get sysAdminds funds
    function sysAdminFunds() external view returns(uint256);
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

// "SPDX-License-Identifier: UNLICENSED"
pragma solidity >=0.6.10;

import {Task, TaskReceipt} from "../gelato_core/interfaces/IGelatoCore.sol";

library GelatoTaskReceipt {
    function task(TaskReceipt memory _TR) internal pure returns(Task memory) {
        return _TR.tasks[_TR.index];
    }

    function nextIndex(TaskReceipt memory _TR) internal pure returns(uint256) {
        return _TR.index == _TR.tasks.length - 1 ? 0 : _TR.index + 1;
    }

    function selfProvider(TaskReceipt memory _TR) internal pure returns(bool) {
        return _TR.provider.addr == _TR.userProxy;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {
    GelatoTaskReceipt
} from "@gelatonetwork/core/contracts/libraries/GelatoTaskReceipt.sol";
import {
    IGelatoCore,
    TaskReceipt
} from "@gelatonetwork/core/contracts/gelato_core/interfaces/IGelatoCore.sol";
import {
    IGelatoSysAdmin
} from "@gelatonetwork/core/contracts/gelato_core/interfaces/IGelatoSysAdmin.sol";
import {LibConcurrentCanExec} from "../libraries/LibConcurrentCanExec.sol";

contract V1ConcurrentMultiCanExecFacet {
    using GelatoTaskReceipt for TaskReceipt;
    using LibConcurrentCanExec for address;

    struct Response {
        uint256 taskReceiptId;
        uint256 taskGasLimit;
        string response;
    }

    function v1ConcurrentMultiCanExec(
        address _gelatoCore,
        TaskReceipt[] calldata _taskReceipts,
        uint256 _gelatoGasPrice,
        uint256 _buffer
    )
        external
        view
        returns (
            bool canExec,
            uint256 blockNumber,
            Response[] memory responses
        )
    {
        canExec = _gelatoCore.concurrentCanExec(_buffer);
        (blockNumber, responses) = v1MultiCanExec(
            _gelatoCore,
            _taskReceipts,
            _gelatoGasPrice
        );
    }

    function v1MultiCanExec(
        address _gelatoCore,
        TaskReceipt[] calldata _taskReceipts,
        uint256 _gelatoGasPrice
    ) public view returns (uint256 blockNumber, Response[] memory responses) {
        blockNumber = block.number;
        uint256 gelatoMaxGas = IGelatoSysAdmin(_gelatoCore).gelatoMaxGas();
        responses = new Response[](_taskReceipts.length);
        for (uint256 i = 0; i < _taskReceipts.length; i++) {
            uint256 taskGasLimit = getGasLimit(_taskReceipts[i], gelatoMaxGas);
            try
                IGelatoCore(_gelatoCore).canExec(
                    _taskReceipts[i],
                    taskGasLimit,
                    _gelatoGasPrice
                )
            returns (string memory response) {
                responses[i] = Response({
                    taskReceiptId: _taskReceipts[i].id,
                    taskGasLimit: taskGasLimit,
                    response: response
                });
            } catch {
                responses[i] = Response({
                    taskReceiptId: _taskReceipts[i].id,
                    taskGasLimit: taskGasLimit,
                    response: "PermissionedExecutors.multiCanExec: failed"
                });
            }
        }
    }

    function getGasLimit(
        TaskReceipt calldata _taskReceipt,
        uint256 _gelatoMaxGas
    ) public pure returns (uint256) {
        return
            _taskReceipt.selfProvider()
                ? _taskReceipt.task().selfProviderGasLimit
                : _gelatoMaxGas;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {LibExecutor} from "./LibExecutor.sol";

library LibConcurrentCanExec {
    using LibExecutor for address;

    enum SlotStatus {Open, Closing, Closed}

    struct ConcurrentExecStorage {
        uint256 slotLength;
    }

    bytes32 private constant _CONCURRENT_EXEC_STORAGE_POSITION =
        keccak256("gelato.diamond.concurrentexec.storage");

    function setSlotLength(uint256 _slotLength) internal {
        concurrentExecStorage().slotLength = _slotLength;
    }

    function slotLength() internal view returns (uint256) {
        return concurrentExecStorage().slotLength;
    }

    function concurrentCanExec(address _service, uint256 _buffer)
        internal
        view
        returns (bool)
    {
        return
            _service.canExec(msg.sender) &&
            mySlotStatus(_buffer) == LibConcurrentCanExec.SlotStatus.Open;
    }

    function getCurrentExecutorIndex()
        internal
        view
        returns (uint256 executorIndex, uint256 remainingBlocksInSlot)
    {
        uint256 numberOfExecutors = LibExecutor.numberOfExecutors();
        uint256 currentSlotLength = slotLength();
        require(
            numberOfExecutors > 0,
            "LibConcurrentCanExec.getCurrentExecutorIndex: 0 executors"
        );
        require(
            currentSlotLength > 0,
            "LibConcurrentCanExec.getCurrentExecutorIndex: 0 slotLength"
        );

        return
            calcExecutorIndex(
                block.number,
                currentSlotLength,
                numberOfExecutors
            );
    }

    function currentExecutor()
        internal
        view
        returns (
            address executor,
            uint256 executorIndex,
            uint256 remainingBlocksInSlot
        )
    {
        (executorIndex, remainingBlocksInSlot) = getCurrentExecutorIndex();
        executor = LibExecutor.executorAt(executorIndex);
    }

    function mySlotStatus(uint256 _buffer) internal view returns (SlotStatus) {
        (uint256 executorIndex, uint256 remainingBlocksInSlot) =
            getCurrentExecutorIndex();

        address executor = LibExecutor.executorAt(executorIndex);

        if (msg.sender != executor) return SlotStatus.Closed;

        return
            remainingBlocksInSlot <= _buffer
                ? SlotStatus.Closing
                : SlotStatus.Open;
    }

    // Example: blocksPerSlot = 3, numberOfExecutors = 2
    //
    // Block number          0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | ...
    //                      ---------------------------------------------
    // slotIndex             0 | 0 | 0 | 1 | 1 | 1 | 2 | 2 | 2 | 3 | ...
    //                      ---------------------------------------------
    // executorIndex         0 | 0 | 0 | 1 | 1 | 1 | 0 | 0 | 0 | 1 | ...
    // remainingBlocksInSlot 2 | 1 | 0 | 2 | 1 | 0 | 2 | 1 | 0 | 2 | ...
    //

    function calcExecutorIndex(
        uint256 _currentBlock,
        uint256 _blocksPerSlot,
        uint256 _numberOfExecutors
    )
        internal
        pure
        returns (uint256 executorIndex, uint256 remainingBlocksInSlot)
    {
        uint256 slotIndex = _currentBlock / _blocksPerSlot;
        return (
            slotIndex % _numberOfExecutors,
            (slotIndex + 1) * _blocksPerSlot - _currentBlock - 1
        );
    }

    function concurrentExecStorage()
        internal
        pure
        returns (ConcurrentExecStorage storage ces)
    {
        bytes32 position = _CONCURRENT_EXEC_STORAGE_POSITION;
        assembly {
            ces.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {
    EnumerableSet
} from "../../../vendor/openzeppelin/contracts/utils/EnumerableSet.sol";
import {LibService} from "./LibService.sol";

library LibExecutor {
    using EnumerableSet for EnumerableSet.AddressSet;
    using LibService for address;

    struct ExecutorStorage {
        EnumerableSet.AddressSet executors;
    }

    bytes32 private constant _EXECUTOR_STORAGE_POSITION =
        keccak256("gelato.diamond.executor.storage");

    function addExecutor(address _executor) internal returns (bool) {
        return executorStorage().executors.add(_executor);
    }

    function removeExecutor(address _executor) internal returns (bool) {
        return executorStorage().executors.remove(_executor);
    }

    function canExec(address _service, address _executor)
        internal
        view
        returns (bool)
    {
        return _service.isListedService() && isExecutor(_executor);
    }

    function isExecutor(address _executor) internal view returns (bool) {
        return executorStorage().executors.contains(_executor);
    }

    function executorAt(uint256 _index) internal view returns (address) {
        return executorStorage().executors.at(_index);
    }

    function executors() internal view returns (address[] memory executors_) {
        uint256 length = numberOfExecutors();
        executors_ = new address[](length);
        for (uint256 i; i < length; i++) executors_[i] = executorAt(i);
    }

    function numberOfExecutors() internal view returns (uint256) {
        return executorStorage().executors.length();
    }

    function executorStorage()
        internal
        pure
        returns (ExecutorStorage storage es)
    {
        bytes32 position = _EXECUTOR_STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import {
    EnumerableSet
} from "../../../vendor/openzeppelin/contracts/utils/EnumerableSet.sol";

library LibService {
    using EnumerableSet for EnumerableSet.AddressSet;

    bytes32 private constant _SERVICE_STORAGE =
        keccak256("gelato.diamond.service.storage");

    struct ServiceStorage {
        EnumerableSet.AddressSet services;
    }

    event LogList(address indexed _service);
    event LogUnlist(address indexed _service);

    function listService(address _service) internal returns (bool) {
        if (!serviceStorage().services.add(_service)) return false;
        emit LogList(_service);
        return true;
    }

    function unlistService(address _service) internal returns (bool) {
        if (!serviceStorage().services.remove(_service)) return false;
        emit LogUnlist(_service);
        return true;
    }

    function isListedService(address _service) internal view returns (bool) {
        return serviceStorage().services.contains(_service);
    }

    function listedServices()
        internal
        view
        returns (address[] memory acceptedServices_)
    {
        uint256 length = serviceStorage().services.length();
        acceptedServices_ = new address[](length);
        for (uint256 i; i < length; i++)
            acceptedServices_[i] = serviceStorage().services.at(i);
    }

    function serviceStorage()
        internal
        pure
        returns (ServiceStorage storage ss)
    {
        bytes32 position = _SERVICE_STORAGE;
        assembly {
            ss.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
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
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
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
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        require(
            set._values.length > index,
            "EnumerableSet: index out of bounds"
        );
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
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
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
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
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
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
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
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
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
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
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
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }
}