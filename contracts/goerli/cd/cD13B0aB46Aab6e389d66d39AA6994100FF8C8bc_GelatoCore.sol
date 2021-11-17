// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * IMPORTANT: It is unsafe to assume that an address for which this
     * function returns false is an externally-owned account (EOA) and not a
     * contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;

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
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
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
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal virtual {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;

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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.10;

import {DataFlow} from "../gelato_core/interfaces/IGelatoCore.sol";

/// @title IGelatoAction - solidity interface of GelatoActionsStandard
/// @notice all the APIs and events of GelatoActionsStandard
/// @dev all the APIs are implemented inside GelatoActionsStandard
interface IGelatoAction {
    event LogOneWay(
        address origin,
        address sendToken,
        uint256 sendAmount,
        address destination
    );

    event LogTwoWay(
        address origin,
        address sendToken,
        uint256 sendAmount,
        address destination,
        address receiveToken,
        uint256 receiveAmount,
        address receiver
    );

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
    )
        external
        view
        returns(string memory);
}

// SPDX-License-Identifier: UNLICENSED
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {IGelatoCore, Provider, Task, TaskReceipt} from "./interfaces/IGelatoCore.sol";
import {GelatoExecutors} from "./GelatoExecutors.sol";
import {GelatoBytes} from "../libraries/GelatoBytes.sol";
import {GelatoTaskReceipt} from "../libraries/GelatoTaskReceipt.sol";
import {SafeMath} from "../external/SafeMath.sol";
import {IGelatoCondition} from "../gelato_conditions/IGelatoCondition.sol";
import {IGelatoAction} from "../gelato_actions/IGelatoAction.sol";
import {IGelatoProviderModule} from "../gelato_provider_modules/IGelatoProviderModule.sol";

/// @title GelatoCore
/// @author Luis Schliesske & Hilmar Orth
/// @notice Task: submission, validation, execution, and cancellation
/// @dev Find all NatSpecs inside IGelatoCore
contract GelatoCore is IGelatoCore, GelatoExecutors {

    using GelatoBytes for bytes;
    using GelatoTaskReceipt for TaskReceipt;
    using SafeMath for uint256;

    // Setting State Vars for GelatoSysAdmin
    constructor(GelatoSysAdminInitialState memory _) public {
        gelatoGasPriceOracle = _.gelatoGasPriceOracle;
        oracleRequestData = _.oracleRequestData;
        gelatoMaxGas = _.gelatoMaxGas;
        internalGasRequirement = _.internalGasRequirement;
        minExecutorStake = _.minExecutorStake;
        executorSuccessShare = _.executorSuccessShare;
        sysAdminSuccessShare = _.sysAdminSuccessShare;
        totalSuccessShare = _.totalSuccessShare;
    }

    // ================  STATE VARIABLES ======================================
    // TaskReceiptIds
    uint256 public override currentTaskReceiptId;
    // taskReceipt.id => taskReceiptHash
    mapping(uint256 => bytes32) public override taskReceiptHash;

    // ================  SUBMIT ==============================================
    function canSubmitTask(
        address _userProxy,
        Provider memory _provider,
        Task memory _task,
        uint256 _expiryDate
    )
        external
        view
        override
        returns(string memory)
    {
        // EXECUTOR CHECKS
        if (!isExecutorMinStaked(executorByProvider[_provider.addr]))
            return "GelatoCore.canSubmitTask: executor not minStaked";

        // ExpiryDate
        if (_expiryDate != 0)
            if (_expiryDate < block.timestamp)
                return "GelatoCore.canSubmitTask: expiryDate";

        // Check Provider details
        string memory isProvided;
        if (_userProxy == _provider.addr) {
            if (_task.selfProviderGasLimit < internalGasRequirement.mul(2))
                return "GelatoCore.canSubmitTask:selfProviderGasLimit too low";
            isProvided = providerModuleChecks(_userProxy, _provider, _task);
        }
        else isProvided = isTaskProvided(_userProxy, _provider, _task);
        if (!isProvided.startsWithOK())
            return string(abi.encodePacked("GelatoCore.canSubmitTask.isProvided:", isProvided));

        // Success
        return OK;
    }

    function submitTask(
        Provider memory _provider,
        Task memory _task,
        uint256 _expiryDate
    )
        external
        override
    {
        Task[] memory singleTask = new Task[](1);
        singleTask[0] = _task;
        if (msg.sender == _provider.addr) _handleSelfProviderGasDefaults(singleTask);
        _storeTaskReceipt(false, msg.sender, _provider, 0, singleTask, _expiryDate, 0, 1);
    }

    function submitTaskCycle(
        Provider memory _provider,
        Task[] memory _tasks,
        uint256 _expiryDate,
        uint256 _cycles  // how many full cycles should be submitted
    )
        external
        override
    {
        if (msg.sender == _provider.addr) _handleSelfProviderGasDefaults(_tasks);
        _storeTaskReceipt(
            true, msg.sender, _provider, 0, _tasks, _expiryDate, 0, _cycles * _tasks.length
        );
    }

    function submitTaskChain(
        Provider memory _provider,
        Task[] memory _tasks,
        uint256 _expiryDate,
        uint256 _sumOfRequestedTaskSubmits  // see IGelatoCore for explanation
    )
        external
        override
    {
        if (_sumOfRequestedTaskSubmits != 0) {
            require(
                _sumOfRequestedTaskSubmits >= _tasks.length,
                "GelatoCore.submitTaskChain: less requested submits than tasks"
            );
        }
        if (msg.sender == _provider.addr) _handleSelfProviderGasDefaults(_tasks);
        _storeTaskReceipt(
            true, msg.sender, _provider, 0, _tasks, _expiryDate, 0, _sumOfRequestedTaskSubmits
        );
    }

    function _storeTaskReceipt(
        bool _newCycle,
        address _userProxy,
        Provider memory _provider,
        uint256 _index,
        Task[] memory _tasks,
        uint256 _expiryDate,
        uint256 _cycleId,
        uint256 _submissionsLeft
    )
        private
    {
        // Increment TaskReceipt ID storage
        uint256 nextTaskReceiptId = currentTaskReceiptId + 1;
        currentTaskReceiptId = nextTaskReceiptId;

        // Generate new Task Receipt
        TaskReceipt memory taskReceipt = TaskReceipt({
            id: nextTaskReceiptId,
            userProxy: _userProxy, // Smart Contract Accounts ONLY
            provider: _provider,
            index: _index,
            tasks: _tasks,
            expiryDate: _expiryDate,
            cycleId: _newCycle ? nextTaskReceiptId : _cycleId,
            submissionsLeft: _submissionsLeft // 0=infinity, 1=once, X=maxTotalExecutions
        });

        // Hash TaskReceipt
        bytes32 hashedTaskReceipt = hashTaskReceipt(taskReceipt);

        // Store TaskReceipt Hash
        taskReceiptHash[taskReceipt.id] = hashedTaskReceipt;

        emit LogTaskSubmitted(taskReceipt.id, hashedTaskReceipt, taskReceipt);
    }

    // ================  CAN EXECUTE EXECUTOR API ============================
    // _gasLimit must be gelatoMaxGas for all Providers except SelfProviders.
    function canExec(TaskReceipt memory _TR, uint256 _gasLimit, uint256 _gelatoGasPrice)
        public
        view
        override
        returns(string memory)
    {
        if (!isExecutorMinStaked(executorByProvider[_TR.provider.addr]))
            return "ExecutorNotMinStaked";

        if (!isProviderLiquid(_TR.provider.addr, _gasLimit, _gelatoGasPrice))
            return "ProviderIlliquidity";

        string memory res = providerCanExec(
            _TR.userProxy,
            _TR.provider,
            _TR.task(),
            _gelatoGasPrice
        );
        if (!res.startsWithOK()) return res;

        bytes32 hashedTaskReceipt = hashTaskReceipt(_TR);
        if (taskReceiptHash[_TR.id] != hashedTaskReceipt) return "InvalidTaskReceiptHash";

        if (_TR.expiryDate != 0 && _TR.expiryDate <= block.timestamp)
            return "TaskReceiptExpired";

        // Optional CHECK Condition for user proxies
        if (_TR.task().conditions.length != 0) {
            for (uint i; i < _TR.task().conditions.length; i++) {
                try _TR.task().conditions[i].inst.ok(
                    _TR.id,
                    _TR.task().conditions[i].data,
                    _TR.cycleId
                )
                    returns(string memory condition)
                {
                    if (!condition.startsWithOK())
                        return string(abi.encodePacked("ConditionNotOk:", condition));
                } catch Error(string memory error) {
                    return string(abi.encodePacked("ConditionReverted:", error));
                } catch {
                    return "ConditionReverted:undefined";
                }
            }
        }

        // Optional CHECK Action Terms
        for (uint i; i < _TR.task().actions.length; i++) {
            // Only check termsOk if specified, else continue
            if (!_TR.task().actions[i].termsOkCheck) continue;

            try IGelatoAction(_TR.task().actions[i].addr).termsOk(
                _TR.id,
                _TR.userProxy,
                _TR.task().actions[i].data,
                _TR.task().actions[i].dataFlow,
                _TR.task().actions[i].value,
                _TR.cycleId
            )
                returns(string memory actionTermsOk)
            {
                if (!actionTermsOk.startsWithOK())
                    return string(abi.encodePacked("ActionTermsNotOk:", actionTermsOk));
            } catch Error(string memory error) {
                return string(abi.encodePacked("ActionReverted:", error));
            } catch {
                return "ActionRevertedNoMessage";
            }
        }

        // Executor Validation
        if (msg.sender == address(this)) return OK;
        else if (msg.sender == executorByProvider[_TR.provider.addr]) return OK;
        else return "InvalidExecutor";
    }

    // ================  EXECUTE EXECUTOR API ============================
    enum ExecutionResult { ExecSuccess, CanExecFailed, ExecRevert }
    enum ExecutorPay { Reward, Refund }

    // Execution Entry Point: tx.gasprice must be greater or equal to _getGelatoGasPrice()
    function exec(TaskReceipt memory _TR) external override {

        // Store startGas for gas-consumption based cost and payout calcs
        uint256 startGas = gasleft();

        // memcopy of gelatoGasPrice, to avoid multiple storage reads
        uint256 gelatoGasPrice = _getGelatoGasPrice();

        // Only assigned executor can execute this function
        require(
            msg.sender == executorByProvider[_TR.provider.addr],
            "GelatoCore.exec: Invalid Executor"
        );

        // The gas stipend the executor must provide. Special case for SelfProviders.
        uint256 gasLimit
            = _TR.selfProvider() ? _TR.task().selfProviderGasLimit : gelatoMaxGas;

        ExecutionResult executionResult;
        string memory reason;

        try this.executionWrapper{
            gas: gasleft().sub(internalGasRequirement, "GelatoCore.exec: Insufficient gas")
        }(_TR, gasLimit, gelatoGasPrice)
            returns (ExecutionResult _executionResult, string memory _reason)
        {
            executionResult = _executionResult;
            reason = _reason;
        } catch Error(string memory error) {
            executionResult = ExecutionResult.ExecRevert;
            reason = error;
        } catch {
            // If any of the external calls in executionWrapper resulted in e.g. out of gas,
            // Executor is eligible for a Refund, but only if Executor sent gelatoMaxGas.
            executionResult = ExecutionResult.ExecRevert;
            reason = "GelatoCore.executionWrapper:undefined";
        }

        if (executionResult == ExecutionResult.ExecSuccess) {
            // END-1: SUCCESS => TaskReceipt was deleted in _exec & Reward
            (uint256 executorSuccessFee, uint256 sysAdminSuccessFee) = _processProviderPayables(
                _TR.provider.addr,
                ExecutorPay.Reward,
                startGas,
                gasLimit,
                gelatoGasPrice
            );
            emit LogExecSuccess(msg.sender, _TR.id, executorSuccessFee, sysAdminSuccessFee);

        } else if (executionResult == ExecutionResult.CanExecFailed) {
            // END-2: CanExecFailed => No TaskReceipt Deletion & No Refund
            emit LogCanExecFailed(msg.sender, _TR.id, reason);

        } else {
            // executionResult == ExecutionResult.ExecRevert
            // END-3.1: ExecReverted NO gelatoMaxGas => No TaskReceipt Deletion & No Refund
            if (startGas < gasLimit)
                emit LogExecReverted(msg.sender, _TR.id, 0, reason);
            else {
                // END-3.2: ExecReverted BUT gelatoMaxGas was used
                //  => TaskReceipt Deletion (delete in _exec was reverted) & Refund
                delete taskReceiptHash[_TR.id];
                (uint256 executorRefund,) = _processProviderPayables(
                    _TR.provider.addr,
                    ExecutorPay.Refund,
                    startGas,
                    gasLimit,
                    gelatoGasPrice
                );
                emit LogExecReverted(msg.sender, _TR.id, executorRefund, reason);
            }
        }
    }

    // Used by GelatoCore.exec(), to handle Out-Of-Gas from execution gracefully
    function executionWrapper(
        TaskReceipt memory taskReceipt,
        uint256 _gasLimit,  // gelatoMaxGas or task.selfProviderGasLimit
        uint256 _gelatoGasPrice
    )
        external
        returns(ExecutionResult, string memory)
    {
        require(msg.sender == address(this), "GelatoCore.executionWrapper:onlyGelatoCore");

        // canExec()
        string memory canExecRes = canExec(taskReceipt, _gasLimit, _gelatoGasPrice);
        if (!canExecRes.startsWithOK()) return (ExecutionResult.CanExecFailed, canExecRes);

        // Will revert if exec failed => will be caught in exec flow
        _exec(taskReceipt);

        // Execution Success: Executor REWARD
        return (ExecutionResult.ExecSuccess, "");
    }

    function _exec(TaskReceipt memory _TR) private {
        // INTERACTIONS
        // execPayload and proxyReturndataCheck values read from ProviderModule
        bytes memory execPayload;
        bool proxyReturndataCheck;

        try IGelatoProviderModule(_TR.provider.module).execPayload(
            _TR.id,
            _TR.userProxy,
            _TR.provider.addr,
            _TR.task(),
            _TR.cycleId
        )
            returns(bytes memory _execPayload, bool _proxyReturndataCheck)
        {
            execPayload = _execPayload;
            proxyReturndataCheck = _proxyReturndataCheck;
        } catch Error(string memory _error) {
            revert(string(abi.encodePacked("GelatoCore._exec.execPayload:", _error)));
        } catch {
            revert("GelatoCore._exec.execPayload:undefined");
        }

        // To prevent single task exec reentrancy we delete hash before external call
        delete taskReceiptHash[_TR.id];

        // Execution via UserProxy
        (bool success, bytes memory userProxyReturndata) = _TR.userProxy.call(execPayload);

        // Check if actions reverts were caught by userProxy
        if (success && proxyReturndataCheck) {
            try _TR.provider.module.execRevertCheck(userProxyReturndata) {
                // success: no revert from providerModule signifies no revert found
            } catch Error(string memory _error) {
                revert(string(abi.encodePacked("GelatoCore._exec.execRevertCheck:", _error)));
            } catch {
                revert("GelatoCore._exec.execRevertCheck:undefined");
            }
        }

        // SUCCESS
        if (success) {
            // Optional: Automated Cyclic Task Submissions
            if (_TR.submissionsLeft != 1) {
                _storeTaskReceipt(
                    false,  // newCycle?
                    _TR.userProxy,
                    _TR.provider,
                    _TR.nextIndex(),
                    _TR.tasks,
                    _TR.expiryDate,
                    _TR.cycleId,
                    _TR.submissionsLeft == 0 ? 0 : _TR.submissionsLeft - 1
                );
            }
        } else {
            // FAILURE: reverts, caught or uncaught in userProxy.call, were detected
            // We revert all state from _exec/userProxy.call and catch revert in exec flow
            // Caution: we also revert the deletion of taskReceiptHash.
            userProxyReturndata.revertWithErrorString("GelatoCore._exec:");
        }
    }

    function _processProviderPayables(
        address _provider,
        ExecutorPay _payType,
        uint256 _startGas,
        uint256 _gasLimit,  // gelatoMaxGas or selfProviderGasLimit
        uint256 _gelatoGasPrice
    )
        private
        returns(uint256 executorCompensation, uint256 sysAdminCompensation)
    {
        uint256 estGasUsed = _startGas - gasleft();

        // Provider payable Gas Refund capped at gelatoMaxGas
        //  (- consecutive state writes + gas refund from deletion)
        uint256 cappedGasUsed =
            estGasUsed < _gasLimit
                ? estGasUsed + EXEC_TX_OVERHEAD
                : _gasLimit + EXEC_TX_OVERHEAD;

        if (_payType == ExecutorPay.Reward) {
            executorCompensation = executorSuccessFee(cappedGasUsed, _gelatoGasPrice);
            sysAdminCompensation = sysAdminSuccessFee(cappedGasUsed, _gelatoGasPrice);
            // ExecSuccess: Provider pays ExecutorSuccessFee and SysAdminSuccessFee
            providerFunds[_provider] = providerFunds[_provider].sub(
                executorCompensation.add(sysAdminCompensation),
                "GelatoCore._processProviderPayables: providerFunds underflow"
            );
            executorStake[msg.sender] += executorCompensation;
            sysAdminFunds += sysAdminCompensation;
        } else {
            // ExecFailure: Provider REFUNDS estimated costs to executor
            executorCompensation = cappedGasUsed.mul(_gelatoGasPrice);
            providerFunds[_provider] = providerFunds[_provider].sub(
                executorCompensation,
                "GelatoCore._processProviderPayables: providerFunds underflow"
            );
            executorStake[msg.sender] += executorCompensation;
        }
    }

    // ================  CANCEL USER / EXECUTOR API ============================
    function cancelTask(TaskReceipt memory _TR) public override {
        // Checks
        require(
            msg.sender == _TR.userProxy || msg.sender == _TR.provider.addr,
            "GelatoCore.cancelTask: sender"
        );
        // Effects
        bytes32 hashedTaskReceipt = hashTaskReceipt(_TR);
        require(
            hashedTaskReceipt == taskReceiptHash[_TR.id],
            "GelatoCore.cancelTask: invalid taskReceiptHash"
        );
        delete taskReceiptHash[_TR.id];
        emit LogTaskCancelled(_TR.id, msg.sender);
    }

    function multiCancelTasks(TaskReceipt[] memory _taskReceipts) external override {
        for (uint i; i < _taskReceipts.length; i++) cancelTask(_taskReceipts[i]);
    }

    // Helpers
    function hashTaskReceipt(TaskReceipt memory _TR) public pure override returns(bytes32) {
        return keccak256(abi.encode(_TR));
    }

    function _handleSelfProviderGasDefaults(Task[] memory _tasks) private view {
        for (uint256 i; i < _tasks.length; i++) {
            if (_tasks[i].selfProviderGasLimit == 0) {
                _tasks[i].selfProviderGasLimit = gelatoMaxGas;
            } else {
                require(
                    _tasks[i].selfProviderGasLimit >= internalGasRequirement.mul(2),
                    "GelatoCore._handleSelfProviderGasDefaults:selfProviderGasLimit too low"
                );
            }
            if (_tasks[i].selfProviderGasPriceCeil == 0)
                _tasks[i].selfProviderGasPriceCeil = NO_CEIL;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {IGelatoExecutors} from "./interfaces/IGelatoExecutors.sol";
import {GelatoProviders} from "./GelatoProviders.sol";
import {Address} from  "../external/Address.sol";
import {SafeMath} from "../external/SafeMath.sol";
import {Math} from "../external/Math.sol";

/// @title GelatoExecutors
/// @author Luis Schliesske & Hilmar Orth
/// @notice Stake Management of executors & batch Unproving providers
/// @dev Find all NatSpecs inside IGelatoExecutors
abstract contract GelatoExecutors is IGelatoExecutors, GelatoProviders {

    using Address for address payable;  /// for sendValue method
    using SafeMath for uint256;

    // Executor De/Registrations and Staking
    function stakeExecutor() external payable override {
        uint256 currentStake = executorStake[msg.sender];
        uint256 newStake = currentStake + msg.value;
        require(
            newStake >= minExecutorStake,
            "GelatoExecutors.stakeExecutor: below minStake"
        );
        executorStake[msg.sender] = newStake;
        emit LogExecutorStaked(msg.sender, currentStake, newStake);
    }

    function unstakeExecutor() external override {
        require(
            !isExecutorAssigned(msg.sender),
            "GelatoExecutors.unstakeExecutor: msg.sender still assigned"
        );
        uint256 unbondedStake = executorStake[msg.sender];
        require(
            unbondedStake != 0,
            "GelatoExecutors.unstakeExecutor: already unstaked"
        );
        delete executorStake[msg.sender];
        msg.sender.sendValue(unbondedStake);
        emit LogExecutorUnstaked(msg.sender);
    }

    function withdrawExcessExecutorStake(uint256 _withdrawAmount)
        external
        override
        returns(uint256 realWithdrawAmount)
    {
        require(
            isExecutorMinStaked(msg.sender),
            "GelatoExecutors.withdrawExcessExecutorStake: not minStaked"
        );

        uint256 currentExecutorStake = executorStake[msg.sender];
        uint256 excessExecutorStake = currentExecutorStake - minExecutorStake;

        realWithdrawAmount = Math.min(_withdrawAmount, excessExecutorStake);

        uint256 newExecutorStake = currentExecutorStake - realWithdrawAmount;

        // Effects
        executorStake[msg.sender] = newExecutorStake;

        // Interaction
        msg.sender.sendValue(realWithdrawAmount);
        emit LogExecutorBalanceWithdrawn(msg.sender, realWithdrawAmount);
    }

    // To unstake, Executors must reassign ALL their Providers to another staked Executor
    function multiReassignProviders(address[] calldata _providers, address _newExecutor)
        external
        override
    {
        for (uint i; i < _providers.length; i++)
            executorAssignsExecutor(_providers[i], _newExecutor);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;
pragma experimental ABIEncoderV2;

import {IGelatoProviders, TaskSpec} from "./interfaces/IGelatoProviders.sol";
import {GelatoSysAdmin} from "./GelatoSysAdmin.sol";
import {Address} from "../external/Address.sol";
import {GelatoString} from "../libraries/GelatoString.sol";
import {Math} from "../external/Math.sol";
import {SafeMath} from "../external/SafeMath.sol";
import {IGelatoProviderModule} from "../gelato_provider_modules/IGelatoProviderModule.sol";
import {ProviderModuleSet} from "../libraries/ProviderModuleSet.sol";
import {
    Condition, Action, Operation, DataFlow, Provider, Task, TaskReceipt
} from "./interfaces/IGelatoCore.sol";
import {IGelatoCondition} from "../gelato_conditions/IGelatoCondition.sol";

/// @title GelatoProviders
/// @notice Provider Management API - Whitelist TaskSpecs
/// @dev Find all NatSpecs inside IGelatoProviders
abstract contract GelatoProviders is IGelatoProviders, GelatoSysAdmin {

    using Address for address payable;  /// for sendValue method
    using GelatoString for string;
    using ProviderModuleSet for ProviderModuleSet.Set;
    using SafeMath for uint256;

    // This is only for internal use by hashTaskSpec()
    struct NoDataAction {
        address addr;
        Operation operation;
        DataFlow dataFlow;
        bool value;
        bool termsOkCheck;
    }

    uint256 public constant override NO_CEIL = type(uint256).max;

    mapping(address => uint256) public override providerFunds;
    mapping(address => uint256) public override executorStake;
    mapping(address => address) public override executorByProvider;
    mapping(address => uint256) public override executorProvidersCount;
    // The Task-Spec Gas-Price-Ceil => taskSpecGasPriceCeil
    mapping(address => mapping(bytes32 => uint256)) public override taskSpecGasPriceCeil;
    mapping(address => ProviderModuleSet.Set) internal _providerModules;

    // GelatoCore: canSubmit
    function isTaskSpecProvided(address _provider, TaskSpec memory _taskSpec)
        public
        view
        override
        returns(string memory)
    {
        if (taskSpecGasPriceCeil[_provider][hashTaskSpec(_taskSpec)] == 0)
            return "TaskSpecNotProvided";
        return OK;
    }

    // IGelatoProviderModule: GelatoCore canSubmit & canExec
    function providerModuleChecks(
        address _userProxy,
        Provider memory _provider,
        Task memory _task
    )
        public
        view
        override
        returns(string memory)
    {
        if (!isModuleProvided(_provider.addr, _provider.module))
            return "InvalidProviderModule";

        if (_userProxy != _provider.addr) {
            IGelatoProviderModule providerModule = IGelatoProviderModule(
                _provider.module
            );

            try providerModule.isProvided(_userProxy, _provider.addr, _task)
                returns(string memory res)
            {
                return res;
            } catch {
                return "GelatoProviders.providerModuleChecks";
            }
        } else return OK;
    }

    // GelatoCore: canSubmit
    function isTaskProvided(
        address _userProxy,
        Provider memory _provider,
        Task memory _task
    )
        public
        view
        override
        returns(string memory res)
    {
        TaskSpec memory _taskSpec = _castTaskToSpec(_task);
        res = isTaskSpecProvided(_provider.addr, _taskSpec);
        if (res.startsWithOK())
            return providerModuleChecks(_userProxy, _provider, _task);
    }

    // GelatoCore canExec Gate
    function providerCanExec(
        address _userProxy,
        Provider memory _provider,
        Task memory _task,
        uint256 _gelatoGasPrice
    )
        public
        view
        override
        returns(string memory)
    {
        if (_userProxy == _provider.addr) {
            if (_task.selfProviderGasPriceCeil < _gelatoGasPrice)
                return "SelfProviderGasPriceCeil";
        } else {
            bytes32 taskSpecHash = hashTaskSpec(_castTaskToSpec(_task));
            if (taskSpecGasPriceCeil[_provider.addr][taskSpecHash] < _gelatoGasPrice)
                return "taskSpecGasPriceCeil-OR-notProvided";
        }
        return providerModuleChecks(_userProxy, _provider, _task);
    }

    // Provider Funding
    function provideFunds(address _provider) public payable override {
        require(msg.value > 0, "GelatoProviders.provideFunds: zero value");
        uint256 newProviderFunds = providerFunds[_provider].add(msg.value);
        emit LogFundsProvided(_provider, msg.value, newProviderFunds);
        providerFunds[_provider] = newProviderFunds;
    }

    // Unprovide funds
    function unprovideFunds(uint256 _withdrawAmount)
        public
        override
        returns(uint256 realWithdrawAmount)
    {
        uint256 previousProviderFunds = providerFunds[msg.sender];
        realWithdrawAmount = Math.min(_withdrawAmount, previousProviderFunds);

        uint256 newProviderFunds = previousProviderFunds - realWithdrawAmount;

        // Effects
        providerFunds[msg.sender] = newProviderFunds;

        // Interaction
        msg.sender.sendValue(realWithdrawAmount);

        emit LogFundsUnprovided(msg.sender, realWithdrawAmount, newProviderFunds);
    }

    // Called by Providers
    function providerAssignsExecutor(address _newExecutor) public override {
        address currentExecutor = executorByProvider[msg.sender];

        // CHECKS
        require(
            currentExecutor != _newExecutor,
            "GelatoProviders.providerAssignsExecutor: already assigned."
        );
        if (_newExecutor != address(0)) {
            require(
                isExecutorMinStaked(_newExecutor),
                "GelatoProviders.providerAssignsExecutor: isExecutorMinStaked()"
            );
        }

        // EFFECTS: Provider reassigns from currentExecutor to newExecutor (or no executor)
        if (currentExecutor != address(0)) executorProvidersCount[currentExecutor]--;
        executorByProvider[msg.sender] = _newExecutor;
        if (_newExecutor != address(0)) executorProvidersCount[_newExecutor]++;

        emit LogProviderAssignedExecutor(msg.sender, currentExecutor, _newExecutor);
    }

    // Called by Executors
    function executorAssignsExecutor(address _provider, address _newExecutor) public override {
        address currentExecutor = executorByProvider[_provider];

        // CHECKS
        require(
            currentExecutor == msg.sender,
            "GelatoProviders.executorAssignsExecutor: msg.sender is not assigned executor"
        );
        require(
            currentExecutor != _newExecutor,
            "GelatoProviders.executorAssignsExecutor: already assigned."
        );
        // Checks at the same time if _nexExecutor != address(0)
        require(
            isExecutorMinStaked(_newExecutor),
            "GelatoProviders.executorAssignsExecutor: isExecutorMinStaked()"
        );

        // EFFECTS: currentExecutor reassigns to newExecutor
        executorProvidersCount[currentExecutor]--;
        executorByProvider[_provider] = _newExecutor;
        executorProvidersCount[_newExecutor]++;

        emit LogExecutorAssignedExecutor(_provider, currentExecutor, _newExecutor);
    }

    // (Un-)provide Condition Action Combos at different Gas Price Ceils
    function provideTaskSpecs(TaskSpec[] memory _taskSpecs) public override {
        for (uint i; i < _taskSpecs.length; i++) {
            if (_taskSpecs[i].gasPriceCeil == 0) _taskSpecs[i].gasPriceCeil = NO_CEIL;
            bytes32 taskSpecHash = hashTaskSpec(_taskSpecs[i]);
            setTaskSpecGasPriceCeil(taskSpecHash, _taskSpecs[i].gasPriceCeil);
            emit LogTaskSpecProvided(msg.sender, taskSpecHash);
        }
    }

    function unprovideTaskSpecs(TaskSpec[] memory _taskSpecs) public override {
        for (uint i; i < _taskSpecs.length; i++) {
            bytes32 taskSpecHash = hashTaskSpec(_taskSpecs[i]);
            require(
                taskSpecGasPriceCeil[msg.sender][taskSpecHash] != 0,
                "GelatoProviders.unprovideTaskSpecs: redundant"
            );
            delete taskSpecGasPriceCeil[msg.sender][taskSpecHash];
            emit LogTaskSpecUnprovided(msg.sender, taskSpecHash);
        }
    }

    function setTaskSpecGasPriceCeil(bytes32 _taskSpecHash, uint256 _gasPriceCeil)
        public
        override
    {
            uint256 currentTaskSpecGasPriceCeil = taskSpecGasPriceCeil[msg.sender][_taskSpecHash];
            require(
                currentTaskSpecGasPriceCeil != _gasPriceCeil,
                "GelatoProviders.setTaskSpecGasPriceCeil: Already whitelisted with gasPriceCeil"
            );
            taskSpecGasPriceCeil[msg.sender][_taskSpecHash] = _gasPriceCeil;
            emit LogTaskSpecGasPriceCeilSet(
                msg.sender,
                _taskSpecHash,
                currentTaskSpecGasPriceCeil,
                _gasPriceCeil
            );
    }

    // Provider Module
    function addProviderModules(IGelatoProviderModule[] memory _modules) public override {
        for (uint i; i < _modules.length; i++) {
            require(
                !isModuleProvided(msg.sender, _modules[i]),
                "GelatoProviders.addProviderModules: redundant"
            );
            _providerModules[msg.sender].add(_modules[i]);
            emit LogProviderModuleAdded(msg.sender, _modules[i]);
        }
    }

    function removeProviderModules(IGelatoProviderModule[] memory _modules) public override {
        for (uint i; i < _modules.length; i++) {
            require(
                isModuleProvided(msg.sender, _modules[i]),
                "GelatoProviders.removeProviderModules: redundant"
            );
            _providerModules[msg.sender].remove(_modules[i]);
            emit LogProviderModuleRemoved(msg.sender, _modules[i]);
        }
    }

    // Batch (un-)provide
    function multiProvide(
        address _executor,
        TaskSpec[] memory _taskSpecs,
        IGelatoProviderModule[] memory _modules
    )
        public
        payable
        override
    {
        if (msg.value != 0) provideFunds(msg.sender);
        if (_executor != address(0)) providerAssignsExecutor(_executor);
        provideTaskSpecs(_taskSpecs);
        addProviderModules(_modules);
    }

    function multiUnprovide(
        uint256 _withdrawAmount,
        TaskSpec[] memory _taskSpecs,
        IGelatoProviderModule[] memory _modules
    )
        public
        override
    {
        if (_withdrawAmount != 0) unprovideFunds(_withdrawAmount);
        unprovideTaskSpecs(_taskSpecs);
        removeProviderModules(_modules);
    }

    // Provider Liquidity
    function minExecProviderFunds(uint256 _gelatoMaxGas, uint256 _gelatoGasPrice)
        public
        view
        override
        returns(uint256)
    {
        uint256 maxExecTxCost = (EXEC_TX_OVERHEAD + _gelatoMaxGas) * _gelatoGasPrice;
        return maxExecTxCost + (maxExecTxCost * totalSuccessShare) / 100;
    }

    function isProviderLiquid(
        address _provider,
        uint256 _gelatoMaxGas,
        uint256 _gelatoGasPrice
    )
        public
        view
        override
        returns(bool)
    {
        return minExecProviderFunds(_gelatoMaxGas, _gelatoGasPrice) <= providerFunds[_provider];
    }

    // An Executor qualifies and remains registered for as long as he has minExecutorStake
    function isExecutorMinStaked(address _executor) public view override returns(bool) {
        return executorStake[_executor] >= minExecutorStake;
    }

    // Providers' Executor Assignment
    function isExecutorAssigned(address _executor) public view override returns(bool) {
        return executorProvidersCount[_executor] != 0;
    }

    // Helper fn that can also be called to query taskSpecHash off-chain
    function hashTaskSpec(TaskSpec memory _taskSpec) public view override returns(bytes32) {
        NoDataAction[] memory noDataActions = new NoDataAction[](_taskSpec.actions.length);
        for (uint i = 0; i < _taskSpec.actions.length; i++) {
            NoDataAction memory noDataAction = NoDataAction({
                addr: _taskSpec.actions[i].addr,
                operation: _taskSpec.actions[i].operation,
                dataFlow: _taskSpec.actions[i].dataFlow,
                value: _taskSpec.actions[i].value == 0 ? false : true,
                termsOkCheck: _taskSpec.actions[i].termsOkCheck
            });
            noDataActions[i] = noDataAction;
        }
        return keccak256(abi.encode(_taskSpec.conditions, noDataActions));
    }

    // Providers' Module Getters
    function isModuleProvided(address _provider, IGelatoProviderModule _module)
        public
        view
        override
        returns(bool)
    {
        return _providerModules[_provider].contains(_module);
    }

    function providerModules(address _provider)
        external
        view
        override
        returns(IGelatoProviderModule[] memory)
    {
        return _providerModules[_provider].enumerate();
    }

    // Internal helper for is isTaskProvided() and providerCanExec
    function _castTaskToSpec(Task memory _task)
        private
        pure
        returns(TaskSpec memory taskSpec)
    {
        taskSpec = TaskSpec({
            conditions: _stripConditionData(_task.conditions),
            actions: _task.actions,
            gasPriceCeil: 0  // default: provider can set gasPriceCeil dynamically.
        });
    }

    function _stripConditionData(Condition[] memory _conditionsWithData)
        private
        pure
        returns(IGelatoCondition[] memory conditionInstances)
    {
        conditionInstances = new IGelatoCondition[](_conditionsWithData.length);
        for (uint i; i < _conditionsWithData.length; i++)
            conditionInstances[i] = _conditionsWithData[i].inst;
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;

import {IGelatoSysAdmin} from "./interfaces/IGelatoSysAdmin.sol";
import {Ownable} from "../external/Ownable.sol";
import {Address} from "../external/Address.sol";
import {GelatoBytes} from "../libraries/GelatoBytes.sol";
import {SafeMath} from "../external/SafeMath.sol";
import {Math} from "../external/Math.sol";

abstract contract GelatoSysAdmin is IGelatoSysAdmin, Ownable {

    using Address for address payable;
    using GelatoBytes for bytes;
    using SafeMath for uint256;

    // Executor compensation for estimated tx costs not accounted for by startGas
    uint256 public constant override EXEC_TX_OVERHEAD = 55000;
    string internal constant OK = "OK";

    address public override gelatoGasPriceOracle;
    bytes public override oracleRequestData;
    uint256 public override gelatoMaxGas;
    uint256 public override internalGasRequirement;
    uint256 public override minExecutorStake;
    uint256 public override executorSuccessShare;
    uint256 public override sysAdminSuccessShare;
    uint256 public override totalSuccessShare;
    uint256 public override sysAdminFunds;

    // == The main functions of the Sys Admin (DAO) ==
    // The oracle defines the system-critical gelatoGasPrice
    function setGelatoGasPriceOracle(address _newOracle) external override onlyOwner {
        require(_newOracle != address(0), "GelatoSysAdmin.setGelatoGasPriceOracle: 0");
        emit LogGelatoGasPriceOracleSet(gelatoGasPriceOracle, _newOracle);
        gelatoGasPriceOracle = _newOracle;
    }

    function setOracleRequestData(bytes calldata _requestData) external override onlyOwner {
        emit LogOracleRequestDataSet(oracleRequestData, _requestData);
        oracleRequestData = _requestData;
    }

    // exec-tx gasprice: pulled in from the Oracle by the Executor during exec()
    function _getGelatoGasPrice() internal view returns(uint256) {
        (bool success, bytes memory returndata) = gelatoGasPriceOracle.staticcall(
            oracleRequestData
        );
        if (!success)
            returndata.revertWithErrorString("GelatoSysAdmin._getGelatoGasPrice:");
        int oracleGasPrice = abi.decode(returndata, (int256));
        if (oracleGasPrice <= 0) revert("GelatoSysAdmin._getGelatoGasPrice:0orBelow");
        return uint256(oracleGasPrice);
    }

    // exec-tx gas
    function setGelatoMaxGas(uint256 _newMaxGas) external override onlyOwner {
        emit LogGelatoMaxGasSet(gelatoMaxGas, _newMaxGas);
        gelatoMaxGas = _newMaxGas;
    }

    // exec-tx GelatoCore internal gas requirement
    function setInternalGasRequirement(uint256 _newRequirement) external override onlyOwner {
        emit LogInternalGasRequirementSet(internalGasRequirement, _newRequirement);
        internalGasRequirement = _newRequirement;
    }

    // Minimum Executor Stake Per Provider
    function setMinExecutorStake(uint256 _newMin) external override onlyOwner {
        emit LogMinExecutorStakeSet(minExecutorStake, _newMin);
        minExecutorStake = _newMin;
    }

    // Executors' profit share on exec costs
    function setExecutorSuccessShare(uint256 _percentage) external override onlyOwner {
        emit LogExecutorSuccessShareSet(
            executorSuccessShare,
            _percentage,
            _percentage + sysAdminSuccessShare
        );
        executorSuccessShare = _percentage;
        totalSuccessShare = _percentage + sysAdminSuccessShare;
    }

    // Sys Admin (DAO) Business Model
    function setSysAdminSuccessShare(uint256 _percentage) external override onlyOwner {
        emit LogSysAdminSuccessShareSet(
            sysAdminSuccessShare,
            _percentage,
            executorSuccessShare + _percentage
        );
        sysAdminSuccessShare = _percentage;
        totalSuccessShare = executorSuccessShare + _percentage;
    }

    function withdrawSysAdminFunds(uint256 _amount, address payable _to)
        external
        override
        onlyOwner
        returns(uint256 realWithdrawAmount)
    {
        uint256 currentBalance = sysAdminFunds;

        realWithdrawAmount = Math.min(_amount, currentBalance);

        uint256 newSysAdminFunds = currentBalance - realWithdrawAmount;

        // Effects
        sysAdminFunds = newSysAdminFunds;

        _to.sendValue(realWithdrawAmount);
        emit LogSysAdminFundsWithdrawn(currentBalance, newSysAdminFunds);
    }

    // Executors' total fee for a successful exec
    function executorSuccessFee(uint256 _gas, uint256 _gasPrice)
        public
        view
        override
        returns(uint256)
    {
        uint256 estExecCost = _gas.mul(_gasPrice);
        return estExecCost + estExecCost.mul(executorSuccessShare).div(
            100,
            "GelatoSysAdmin.executorSuccessFee: div error"
        );
    }

    function sysAdminSuccessFee(uint256 _gas, uint256 _gasPrice)
        public
        view
        override
        returns(uint256)
    {
        uint256 estExecCost = _gas.mul(_gasPrice);
        return
            estExecCost.mul(sysAdminSuccessShare).div(
            100,
            "GelatoSysAdmin.sysAdminSuccessShare: div error"
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.10;

interface IGelatoExecutors {
    event LogExecutorStaked(address indexed executor, uint256 oldStake, uint256 newStake);
    event LogExecutorUnstaked(address indexed executor);

    event LogExecutorBalanceWithdrawn(
        address indexed executor,
        uint256 withdrawAmount
    );

    /// @notice Stake on Gelato to become a whitelisted executor
    /// @dev Msg.value has to be >= minExecutorStake
    function stakeExecutor() external payable;

    /// @notice Unstake on Gelato to become de-whitelisted and withdraw minExecutorStake
    function unstakeExecutor() external;

    /// @notice Re-assigns multiple providers to other executors
    /// @dev Executors must re-assign all providers before being able to unstake
    /// @param _providers List of providers to re-assign
    /// @param _newExecutor Address of new executor to assign providers to
    function multiReassignProviders(address[] calldata _providers, address _newExecutor)
        external;


    /// @notice Withdraw excess Execur Stake
    /// @dev Can only be called if executor is isExecutorMinStaked
    /// @param _withdrawAmount Amount to withdraw
    /// @return Amount that was actually withdrawn
    function withdrawExcessExecutorStake(uint256 _withdrawAmount) external returns(uint256);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.10;
pragma experimental ABIEncoderV2;

import {IGelatoProviderModule} from "../../gelato_provider_modules/IGelatoProviderModule.sol";
import {Action, Provider, Task, TaskReceipt} from "./IGelatoCore.sol";
import {IGelatoCondition} from "../../gelato_conditions/IGelatoCondition.sol";

// TaskSpec - Will be whitelised by providers and selected by users
struct TaskSpec {
    IGelatoCondition[] conditions;   // Address: optional AddressZero for self-conditional actions
    Action[] actions;
    uint256 gasPriceCeil;
}

interface IGelatoProviders {
    // Provider Funding
    event LogFundsProvided(
        address indexed provider,
        uint256 amount,
        uint256 newProviderFunds
    );
    event LogFundsUnprovided(
        address indexed provider,
        uint256 realWithdrawAmount,
        uint256 newProviderFunds
    );

    // Executor By Provider
    event LogProviderAssignedExecutor(
        address indexed provider,
        address indexed oldExecutor,
        address indexed newExecutor
    );
    event LogExecutorAssignedExecutor(
        address indexed provider,
        address indexed oldExecutor,
        address indexed newExecutor
    );

    // Actions
    event LogTaskSpecProvided(address indexed provider, bytes32 indexed taskSpecHash);
    event LogTaskSpecUnprovided(address indexed provider, bytes32 indexed taskSpecHash);
    event LogTaskSpecGasPriceCeilSet(
        address indexed provider,
        bytes32 taskSpecHash,
        uint256 oldTaskSpecGasPriceCeil,
        uint256 newTaskSpecGasPriceCeil
    );

    // Provider Module
    event LogProviderModuleAdded(
        address indexed provider,
        IGelatoProviderModule indexed module
    );
    event LogProviderModuleRemoved(
        address indexed provider,
        IGelatoProviderModule indexed module
    );

    // =========== GELATO PROVIDER APIs ==============

    /// @notice Validation that checks whether Task Spec is being offered by the selected provider
    /// @dev Checked in submitTask(), unless provider == userProxy
    /// @param _provider Address of selected provider
    /// @param _taskSpec Task Spec
    /// @return Expected to return "OK"
    function isTaskSpecProvided(address _provider, TaskSpec calldata _taskSpec)
        external
        view
        returns(string memory);

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
    )
        external
        view
        returns(string memory);


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
    )
        external
        view
        returns(string memory res);


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
    )
        external
        view
        returns(string memory res);

    // =========== PROVIDER STATE WRITE APIs ==============
    // Provider Funding
    /// @notice Deposit ETH as provider on Gelato
    /// @param _provider Address of provider who receives ETH deposit
    function provideFunds(address _provider) external payable;

    /// @notice Withdraw provider funds from gelato
    /// @param _withdrawAmount Amount
    /// @return amount that will be withdrawn
    function unprovideFunds(uint256 _withdrawAmount) external returns(uint256);

    /// @notice Assign executor as provider
    /// @param _executor Address of new executor
    function providerAssignsExecutor(address _executor) external;

    /// @notice Assign executor as previous selected executor
    /// @param _provider Address of provider whose executor to change
    /// @param _newExecutor Address of new executor
    function executorAssignsExecutor(address _provider, address _newExecutor) external;

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
    function setTaskSpecGasPriceCeil(bytes32 _taskSpecHash, uint256 _gasPriceCeil) external;

    // Provider Module
    /// @notice Whitelist new provider Module(s)
    /// @param _modules Addresses of the modules which will be called during providerModuleChecks()
    function addProviderModules(IGelatoProviderModule[] calldata _modules) external;

    /// @notice De-Whitelist new provider Module(s)
    /// @param _modules Addresses of the modules which will be removed
    function removeProviderModules(IGelatoProviderModule[] calldata _modules) external;

    // Batch (un-)provide

    /// @notice Whitelist new executor, TaskSpec(s) and Module(s) in one tx
    /// @param _executor Address of new executor of provider
    /// @param _taskSpecs List of Task Spec which will be whitelisted by provider
    /// @param _modules List of module addresses which will be whitelisted by provider
    function multiProvide(
        address _executor,
        TaskSpec[] calldata _taskSpecs,
        IGelatoProviderModule[] calldata _modules
    )
        external
        payable;


    /// @notice De-Whitelist TaskSpec(s), Module(s) and withdraw funds from gelato in one tx
    /// @param _withdrawAmount Amount to withdraw from ProviderFunds
    /// @param _taskSpecs List of Task Spec which will be de-whitelisted by provider
    /// @param _modules List of module addresses which will be de-whitelisted by provider
    function multiUnprovide(
        uint256 _withdrawAmount,
        TaskSpec[] calldata _taskSpecs,
        IGelatoProviderModule[] calldata _modules
    )
        external;

    // =========== PROVIDER STATE READ APIs ==============
    // Provider Funding

    /// @notice Get balance of provider
    /// @param _provider Address of provider
    /// @return Provider Balance
    function providerFunds(address _provider) external view returns(uint256);

    /// @notice Get min stake required by all providers for executors to call exec
    /// @param _gelatoMaxGas Current gelatoMaxGas
    /// @param _gelatoGasPrice Current gelatoGasPrice
    /// @return How much provider balance is required for executor to submit exec tx
    function minExecProviderFunds(uint256 _gelatoMaxGas, uint256 _gelatoGasPrice)
        external
        view
        returns(uint256);

    /// @notice Check if provider has sufficient funds for executor to call exec
    /// @param _provider Address of provider
    /// @param _gelatoMaxGas Currentt gelatoMaxGas
    /// @param _gelatoGasPrice Current gelatoGasPrice
    /// @return Whether provider is liquid (true) or not (false)
    function isProviderLiquid(
        address _provider,
        uint256 _gelatoMaxGas,
        uint256 _gelatoGasPrice
    )
        external
        view
        returns(bool);

    // Executor Stake

    /// @notice Get balance of executor
    /// @param _executor Address of executor
    /// @return Executor Balance
    function executorStake(address _executor) external view returns(uint256);

    /// @notice Check if executor has sufficient stake on gelato
    /// @param _executor Address of provider
    /// @return Whether executor has sufficient stake (true) or not (false)
    function isExecutorMinStaked(address _executor) external view returns(bool);

    /// @notice Get executor of provider
    /// @param _provider Address of provider
    /// @return Provider's executor
    function executorByProvider(address _provider)
        external
        view
        returns(address);

    /// @notice Get num. of providers which haved assigned an executor
    /// @param _executor Address of executor
    /// @return Count of how many providers assigned the executor
    function executorProvidersCount(address _executor) external view returns(uint256);

    /// @notice Check if executor has one or more providers assigned
    /// @param _executor Address of provider
    /// @return Where 1 or more providers have assigned the executor
    function isExecutorAssigned(address _executor) external view returns(bool);

    // Task Spec and Gas Price Ceil
    /// @notice The maximum gas price the transaction will be executed with
    /// @param _provider Address of provider
    /// @param _taskSpecHash Hash of provider TaskSpec
    /// @return Max gas price an executor will execute the transaction with in wei
    function taskSpecGasPriceCeil(address _provider, bytes32 _taskSpecHash)
        external
        view
        returns(uint256);

    /// @notice Returns the hash of the formatted TaskSpec.
    /// @dev The action.data field of each Action is stripped before hashing.
    /// @param _taskSpec TaskSpec
    /// @return keccak256 hash of encoded condition address and Action List
    function hashTaskSpec(TaskSpec calldata _taskSpec) external view returns(bytes32);

    /// @notice Constant used to specify the highest gas price available in the gelato system
    /// @dev Input 0 as gasPriceCeil and it will be assigned to NO_CEIL
    /// @return MAX_UINT
    function NO_CEIL() external pure returns(uint256);

    // Providers' Module Getters

    /// @notice Check if inputted module is whitelisted by provider
    /// @param _provider Address of provider
    /// @param _module Address of module
    /// @return true if it is whitelisted
    function isModuleProvided(address _provider, IGelatoProviderModule _module)
        external
        view
        returns(bool);

    /// @notice Get all whitelisted provider modules from a given provider
    /// @param _provider Address of provider
    /// @return List of whitelisted provider modules
    function providerModules(address _provider)
        external
        view
        returns(IGelatoProviderModule[] memory);
}

// SPDX-License-Identifier: UNLICENSED
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

// SPDX-License-Identifier: UNLICENSED
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.10;

library GelatoBytes {
    function calldataSliceSelector(bytes calldata _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function memorySliceSelector(bytes memory _bytes)
        internal
        pure
        returns (bytes4 selector)
    {
        selector =
            _bytes[0] |
            (bytes4(_bytes[1]) >> 8) |
            (bytes4(_bytes[2]) >> 16) |
            (bytes4(_bytes[3]) >> 24);
    }

    function revertWithErrorString(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                revert(string(abi.encodePacked(_tracingInfo, string(_bytes))));
            } else {
                revert(
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"))
                );
            }
        } else {
            revert(
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"))
            );
        }
    }

    function returnError(bytes memory _bytes, string memory _tracingInfo)
        internal
        pure
        returns (string memory)
    {
        // 68: 32-location, 32-length, 4-ErrorSelector, UTF-8 err
        if (_bytes.length % 32 == 4) {
            bytes4 selector;
            assembly {
                selector := mload(add(0x20, _bytes))
            }
            if (selector == 0x08c379a0) {
                // Function selector for Error(string)
                assembly {
                    _bytes := add(_bytes, 68)
                }
                return string(abi.encodePacked(_tracingInfo, string(_bytes)));
            } else {
                return
                    string(abi.encodePacked(_tracingInfo, "NoErrorSelector"));
            }
        } else {
            return
                string(abi.encodePacked(_tracingInfo, "UnexpectedReturndata"));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.10;

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

// SPDX-License-Identifier: UNLICENSED
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.10;

import {IGelatoProviderModule} from "../gelato_provider_modules/IGelatoProviderModule.sol";


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
 * As of v2.5.0, only `IGelatoProviderModule` sets are supported.
 *
 * Include with `using EnumerableSet for EnumerableSet.Set;`.
 *
 * _Available since v2.5.0._
 *
 * @author Alberto Cuesta Cañada
 * @author Luis Schliessske (modified to ProviderModuleSet)
 */
library ProviderModuleSet {

    struct Set {
        // Position of the module in the `modules` array, plus 1 because index 0
        // means a module is not in the set.
        mapping (IGelatoProviderModule => uint256) index;
        IGelatoProviderModule[] modules;
    }

    /**
     * @dev Add a module to a set. O(1).
     * Returns false if the module was already in the set.
     */
    function add(Set storage set, IGelatoProviderModule module)
        internal
        returns (bool)
    {
        if (!contains(set, module)) {
            set.modules.push(module);
            // The element is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel module
            set.index[module] = set.modules.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a module from a set. O(1).
     * Returns false if the module was not present in the set.
     */
    function remove(Set storage set, IGelatoProviderModule module)
        internal
        returns (bool)
    {
        if (contains(set, module)){
            uint256 toDeleteIndex = set.index[module] - 1;
            uint256 lastIndex = set.modules.length - 1;

            // If the element we're deleting is the last one, we can just remove it without doing a swap
            if (lastIndex != toDeleteIndex) {
                IGelatoProviderModule lastValue = set.modules[lastIndex];

                // Move the last module to the index where the deleted module is
                set.modules[toDeleteIndex] = lastValue;
                // Update the index for the moved module
                set.index[lastValue] = toDeleteIndex + 1; // All indexes are 1-based
            }

            // Delete the index entry for the deleted module
            delete set.index[module];

            // Delete the old entry for the moved module
            set.modules.pop();

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the module is in the set. O(1).
     */
    function contains(Set storage set, IGelatoProviderModule module)
        internal
        view
        returns (bool)
    {
        return set.index[module] != 0;
    }

    /**
     * @dev Returns an array with all modules in the set. O(N).
     * Note that there are no guarantees on the ordering of modules inside the
     * array, and it may change when more modules are added or removed.

     * WARNING: This function may run out of gas on large sets: use {length} and
     * {get} instead in these cases.
     */
    function enumerate(Set storage set)
        internal
        view
        returns (IGelatoProviderModule[] memory)
    {
        IGelatoProviderModule[] memory output = new IGelatoProviderModule[](set.modules.length);
        for (uint256 i; i < set.modules.length; i++) output[i] = set.modules[i];
        return output;
    }

    /**
     * @dev Returns the number of elements on the set. O(1).
     */
    function length(Set storage set)
        internal
        view
        returns (uint256)
    {
        return set.modules.length;
    }

   /** @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of modules inside the
    * array, and it may change when more modules are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function get(Set storage set, uint256 index)
        internal
        view
        returns (IGelatoProviderModule)
    {
        return set.modules[index];
    }
}