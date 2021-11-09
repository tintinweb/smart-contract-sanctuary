// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import './TimelockExecutorBase.sol';

contract ArcTimelock is TimelockExecutorBase {
  address private _ethereumGovernanceExecutor;

  event EthereumGovernanceExecutorUpdate(
    address previousEthereumGovernanceExecutor,
    address newEthereumGovernanceExecutor
  );

  modifier onlyEthereumGovernanceExecutor() {
    require(msg.sender == _ethereumGovernanceExecutor, 'UNAUTHORIZED_EXECUTOR');
    _;
  }

  constructor(
    address ethereumGovernanceExecutor,
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay,
    address guardian
  ) TimelockExecutorBase(delay, gracePeriod, minimumDelay, maximumDelay, guardian) {
    _ethereumGovernanceExecutor = ethereumGovernanceExecutor;
  }

  /**
   * @dev Queue the message in the Executor
   * @param targets list of contracts called by each action's associated transaction
   * @param values list of value in wei for each action's  associated transaction
   * @param signatures list of function signatures (can be empty) to be used when created the callData
   * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
   * @param withDelegatecalls boolean, true = transaction delegatecalls the taget, else calls the target
   **/
  function queue(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    bool[] memory withDelegatecalls
  ) external onlyEthereumGovernanceExecutor {
    _queue(targets, values, signatures, calldatas, withDelegatecalls);
  }

  /**
   * @dev Update the address of the Ethereum Governance Executor contract responsible for sending transactions to ARC
   * @param ethereumGovernanceExecutor the address of the Ethereum Governance Executor contract
   **/
  function updateEthereumGovernanceExecutor(address ethereumGovernanceExecutor) external onlyThis {
    emit EthereumGovernanceExecutorUpdate(_ethereumGovernanceExecutor, ethereumGovernanceExecutor);
    _ethereumGovernanceExecutor = ethereumGovernanceExecutor;
  }

  /**
   * @dev get the current address of ethereumGovernanceExecutor
   * @return the address of the Ethereum Governance Executor contract
   **/
  function getEthereumGovernanceExecutor() external view returns (address) {
    return _ethereumGovernanceExecutor;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import '../dependencies/SafeMath.sol';
import '../interfaces/ITimelockExecutor.sol';

abstract contract TimelockExecutorBase is ITimelockExecutor {
  using SafeMath for uint256;

  uint256 private _delay;
  uint256 private _gracePeriod;
  uint256 private _minimumDelay;
  uint256 private _maximumDelay;
  address private _guardian;
  uint256 private _actionsSetCounter;

  mapping(uint256 => ActionsSet) private _actionsSets;
  mapping(bytes32 => bool) private _queuedActions;

  modifier onlyGuardian() {
    require(msg.sender == _guardian, 'ONLY_BY_GUARDIAN');
    _;
  }

  modifier onlyThis() {
    require(msg.sender == address(this), 'UNAUTHORIZED_ORIGIN_ONLY_THIS');
    _;
  }

  constructor(
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay,
    address guardian
  ) {
    require(delay >= minimumDelay, 'DELAY_SHORTER_THAN_MINIMUM');
    require(delay <= maximumDelay, 'DELAY_LONGER_THAN_MAXIMUM');
    _delay = delay;
    _gracePeriod = gracePeriod;
    _minimumDelay = minimumDelay;
    _maximumDelay = maximumDelay;
    _guardian = guardian;
  }

  /// @inheritdoc ITimelockExecutor
  function execute(uint256 actionsSetId) external payable override {
    require(getCurrentState(actionsSetId) == ActionsSetState.Queued, 'ONLY_QUEUED_ACTIONS');

    ActionsSet storage actionsSet = _actionsSets[actionsSetId];
    require(block.timestamp >= actionsSet.executionTime, 'TIMELOCK_NOT_FINISHED');

    actionsSet.executed = true;
    uint256 actionCount = actionsSet.targets.length;

    bytes[] memory returnedData = new bytes[](actionCount);
    for (uint256 i = 0; i < actionCount; i++) {
      returnedData[i] = _executeTransaction(
        actionsSet.targets[i],
        actionsSet.values[i],
        actionsSet.signatures[i],
        actionsSet.calldatas[i],
        actionsSet.executionTime,
        actionsSet.withDelegatecalls[i]
      );
    }
    emit ActionsSetExecuted(actionsSetId, msg.sender, returnedData);
  }

  /// @inheritdoc ITimelockExecutor
  function cancel(uint256 actionsSetId) external override onlyGuardian {
    ActionsSetState state = getCurrentState(actionsSetId);
    require(state == ActionsSetState.Queued, 'ONLY_BEFORE_EXECUTED');

    ActionsSet storage actionsSet = _actionsSets[actionsSetId];
    actionsSet.canceled = true;
    for (uint256 i = 0; i < actionsSet.targets.length; i++) {
      _cancelTransaction(
        actionsSet.targets[i],
        actionsSet.values[i],
        actionsSet.signatures[i],
        actionsSet.calldatas[i],
        actionsSet.executionTime,
        actionsSet.withDelegatecalls[i]
      );
    }

    emit ActionsSetCanceled(actionsSetId);
  }

  /// @inheritdoc ITimelockExecutor
  function getActionsSetById(uint256 actionsSetId)
    external
    view
    override
    returns (ActionsSet memory)
  {
    return _actionsSets[actionsSetId];
  }

  /// @inheritdoc ITimelockExecutor
  function getCurrentState(uint256 actionsSetId) public view override returns (ActionsSetState) {
    require(_actionsSetCounter >= actionsSetId, 'INVALID_ACTION_ID');
    ActionsSet storage actionsSet = _actionsSets[actionsSetId];
    if (actionsSet.canceled) {
      return ActionsSetState.Canceled;
    } else if (actionsSet.executed) {
      return ActionsSetState.Executed;
    } else if (block.timestamp > actionsSet.executionTime.add(_gracePeriod)) {
      return ActionsSetState.Expired;
    } else {
      return ActionsSetState.Queued;
    }
  }

  /// @inheritdoc ITimelockExecutor
  function isActionQueued(bytes32 actionHash) public view override returns (bool) {
    return _queuedActions[actionHash];
  }

  function receiveFunds() external payable {}

  /// @inheritdoc ITimelockExecutor
  function updateGuardian(address guardian) external override onlyThis {
    emit GuardianUpdate(_guardian, guardian);
    _guardian = guardian;
  }

  /// @inheritdoc ITimelockExecutor
  function updateDelay(uint256 delay) external override onlyThis {
    _validateDelay(delay);
    emit DelayUpdate(_delay, delay);
    _delay = delay;
  }

  /// @inheritdoc ITimelockExecutor
  function updateGracePeriod(uint256 gracePeriod) external override onlyThis {
    emit GracePeriodUpdate(_gracePeriod, gracePeriod);
    _gracePeriod = gracePeriod;
  }

  /// @inheritdoc ITimelockExecutor
  function updateMinimumDelay(uint256 minimumDelay) external override onlyThis {
    uint256 previousMinimumDelay = _minimumDelay;
    _minimumDelay = minimumDelay;
    _validateDelay(_delay);
    emit MinimumDelayUpdate(previousMinimumDelay, minimumDelay);
  }

  /// @inheritdoc ITimelockExecutor
  function updateMaximumDelay(uint256 maximumDelay) external override onlyThis {
    uint256 previousMaximumDelay = _maximumDelay;
    _maximumDelay = maximumDelay;
    _validateDelay(_delay);
    emit MaximumDelayUpdate(previousMaximumDelay, maximumDelay);
  }

  /// @inheritdoc ITimelockExecutor
  function getDelay() external view override returns (uint256) {
    return _delay;
  }

  /// @inheritdoc ITimelockExecutor
  function getGracePeriod() external view override returns (uint256) {
    return _gracePeriod;
  }

  /// @inheritdoc ITimelockExecutor
  function getMinimumDelay() external view override returns (uint256) {
    return _minimumDelay;
  }

  /// @inheritdoc ITimelockExecutor
  function getMaximumDelay() external view override returns (uint256) {
    return _maximumDelay;
  }

  /// @inheritdoc ITimelockExecutor
  function getGuardian() external view override returns (address) {
    return _guardian;
  }

  /// @inheritdoc ITimelockExecutor
  function getActionsSetCount() external view override returns (uint256) {
    return _actionsSetCounter;
  }

  /**
   * @dev target.delegatecall cannot be provided a value directly and is sent
   * with the entire available msg.value. In this instance, we only want each proposed action
   * to execute with exactly the value defined in the proposal. By splitting executeDelegateCall
   * into a seperate function, it can be called from this contract with a defined amout of value,
   * reducing the risk that a delegatecall is executed with more value than intended
   * @return success - boolean indicating it the delegate call was successfull
   * @return resultdata - bytes returned by the delegate call
   **/
  function executeDelegateCall(address target, bytes calldata data)
    external
    payable
    onlyThis
    returns (bool, bytes memory)
  {
    bool success;
    bytes memory resultData;
    // solium-disable-next-line security/no-call-value
    (success, resultData) = target.delegatecall(data);
    return (success, resultData);
  }

  /**
   * @dev Queue the ActionsSet
   * @param targets list of contracts called by each action's associated transaction
   * @param values list of value in wei for each action's  associated transaction
   * @param signatures list of function signatures (can be empty) to be used when created the callData
   * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
   * @param withDelegatecalls boolean, true = transaction delegatecalls the taget, else calls the target
   **/
  function _queue(
    address[] memory targets,
    uint256[] memory values,
    string[] memory signatures,
    bytes[] memory calldatas,
    bool[] memory withDelegatecalls
  ) internal {
    require(targets.length != 0, 'INVALID_EMPTY_TARGETS');
    require(
      targets.length == values.length &&
        targets.length == signatures.length &&
        targets.length == calldatas.length &&
        targets.length == withDelegatecalls.length,
      'INCONSISTENT_PARAMS_LENGTH'
    );

    uint256 actionsSetId = _actionsSetCounter;
    uint256 executionTime = block.timestamp.add(_delay);
    _actionsSetCounter++;

    for (uint256 i = 0; i < targets.length; i++) {
      bytes32 actionHash =
        keccak256(
          abi.encode(
            targets[i],
            values[i],
            signatures[i],
            calldatas[i],
            executionTime,
            withDelegatecalls[i]
          )
        );
      require(!isActionQueued(actionHash), 'DUPLICATED_ACTION');
      _queuedActions[actionHash] = true;
    }

    ActionsSet storage actionsSet = _actionsSets[actionsSetId];
    actionsSet.targets = targets;
    actionsSet.values = values;
    actionsSet.signatures = signatures;
    actionsSet.calldatas = calldatas;
    actionsSet.withDelegatecalls = withDelegatecalls;
    actionsSet.executionTime = executionTime;

    emit ActionsSetQueued(
      actionsSetId,
      targets,
      values,
      signatures,
      calldatas,
      withDelegatecalls,
      executionTime
    );
  }

  function _executeTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) internal returns (bytes memory) {
    require(address(this).balance >= value, 'NOT_ENOUGH_CONTRACT_BALANCE');

    bytes32 actionHash =
      keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall));
    _queuedActions[actionHash] = false;

    bytes memory callData;
    if (bytes(signature).length == 0) {
      callData = data;
    } else {
      callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
    }

    bool success;
    bytes memory resultData;
    if (withDelegatecall) {
      (success, resultData) = this.executeDelegateCall{value: value}(target, callData);
    } else {
      // solium-disable-next-line security/no-call-value
      (success, resultData) = target.call{value: value}(callData);
    }
    return _verifyCallResult(success, resultData);
  }

  function _cancelTransaction(
    address target,
    uint256 value,
    string memory signature,
    bytes memory data,
    uint256 executionTime,
    bool withDelegatecall
  ) internal {
    bytes32 actionHash =
      keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall));
    _queuedActions[actionHash] = false;
  }

  function _validateDelay(uint256 delay) internal view {
    require(delay >= _minimumDelay, 'DELAY_SHORTER_THAN_MINIMUM');
    require(delay <= _maximumDelay, 'DELAY_LONGER_THAN_MAXIMUM');
  }

  function _verifyCallResult(bool success, bytes memory returndata)
    private
    pure
    returns (bytes memory)
  {
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
        revert('FAILED_ACTION_EXECUTION');
      }
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

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
    require(c >= a, 'SafeMath: addition overflow');

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
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
    require(c / a == b, 'SafeMath: multiplication overflow');

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
    return div(a, b, 'SafeMath: division by zero');
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
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
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
    return mod(a, b, 'SafeMath: modulo by zero');
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
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.5;
pragma abicoder v2;

interface ITimelockExecutor {
  enum ActionsSetState {
    Queued,
    Executed,
    Canceled,
    Expired
  }

  struct ActionsSet {
    address[] targets;
    uint256[] values;
    string[] signatures;
    bytes[] calldatas;
    bool[] withDelegatecalls;
    uint256 executionTime;
    bool executed;
    bool canceled;
  }

  /**
   * @dev emitted when an ActionsSet is queued
   * @param id Id of the ActionsSet
   * @param targets list of contracts called by each action's associated transaction
   * @param values list of value in wei for each action's  associated transaction
   * @param signatures list of function signatures (can be empty) to be used when created the callData
   * @param calldatas list of calldatas: if associated signature empty, calldata ready, else calldata is arguments
   * @param withDelegatecalls boolean, true = transaction delegatecalls the taget, else calls the target
   * @param executionTime the time these actions can be executed
   **/
  event ActionsSetQueued(
    uint256 id,
    address[] targets,
    uint256[] values,
    string[] signatures,
    bytes[] calldatas,
    bool[] withDelegatecalls,
    uint256 executionTime
  );

  /**
   * @dev emitted when an ActionsSet is executed successfully
   * @param id Id of the ActionsSet
   * @param initiatorExecution address that triggered the ActionsSet execution
   * @param returnedData returned data from the ActionsSet execution
   **/
  event ActionsSetExecuted(uint256 id, address indexed initiatorExecution, bytes[] returnedData);

  /**
   * @dev emitted when an ActionsSet is cancelled by the guardian
   * @param id Id of the ActionsSet
   **/
  event ActionsSetCanceled(uint256 id);

  /**
   * @dev emitted when a new guardian is set
   * @param previousGuardian previous guardian
   * @param newGuardian new guardian
   **/
  event GuardianUpdate(address previousGuardian, address newGuardian);

  /**
   * @dev emitted when a new delay (between queueing and execution) is set
   * @param previousDelay previous delay
   * @param newDelay new delay
   **/
  event DelayUpdate(uint256 previousDelay, uint256 newDelay);

  /**
   * @dev emitted when a GracePeriod is updated
   * @param previousGracePeriod previous grace period
   * @param newGracePeriod new grace period
   **/
  event GracePeriodUpdate(uint256 previousGracePeriod, uint256 newGracePeriod);

  /**
   * @dev emitted when a Minimum Delay is updated
   * @param previousMinimumDelay previous minimum delay
   * @param newMinimumDelay new minimum delay
   **/
  event MinimumDelayUpdate(uint256 previousMinimumDelay, uint256 newMinimumDelay);

  /**
   * @dev emitted when a Maximum Delay is updated
   * @param previousMaximumDelay previous maximum delay
   * @param newMaximumDelay new maximum delay
   **/
  event MaximumDelayUpdate(uint256 previousMaximumDelay, uint256 newMaximumDelay);

  /**
   * @dev Execute the ActionsSet
   * @param actionsSetId id of the ActionsSet to execute
   **/
  function execute(uint256 actionsSetId) external payable;

  /**
   * @dev Cancel the ActionsSet
   * @param actionsSetId id of the ActionsSet to cancel
   **/
  function cancel(uint256 actionsSetId) external;

  /**
   * @dev Get the ActionsSet by Id
   * @param actionsSetId id of the ActionsSet
   * @return the ActionsSet requested
   **/
  function getActionsSetById(uint256 actionsSetId) external view returns (ActionsSet memory);

  /**
   * @dev Get the current state of an ActionsSet
   * @param actionsSetId id of the ActionsSet
   * @return The current state of the ActionsSet
   **/
  function getCurrentState(uint256 actionsSetId) external view returns (ActionsSetState);

  /**
   * @dev Returns whether an action (via actionHash) is queued
   * @param actionHash hash of the action to be checked
   * keccak256(abi.encode(target, value, signature, data, executionTime, withDelegatecall))
   * @return true if underlying action of actionHash is queued
   **/
  function isActionQueued(bytes32 actionHash) external view returns (bool);

  /**
   * @dev Update guardian
   * @param guardian address of the new guardian
   **/
  function updateGuardian(address guardian) external;

  /**
   * @dev Update the delay
   * @param delay delay between queue and execution of an ActionSet
   **/
  function updateDelay(uint256 delay) external;

  /**
   * @dev Set the grace period - time before a queued action will expire
   * @param gracePeriod The gracePeriod in seconds
   **/
  function updateGracePeriod(uint256 gracePeriod) external;

  /**
   * @dev Set the minimum allowed delay between queing and exection
   * @param minimumDelay The minimum delay in seconds
   **/
  function updateMinimumDelay(uint256 minimumDelay) external;

  /**
   * @dev Set the maximum allowed delay between queing and exection
   * @param maximumDelay The maximum delay in seconds
   **/
  function updateMaximumDelay(uint256 maximumDelay) external;

  /**
   * @dev Getter of the delay between queuing and execution
   * @return The delay in seconds
   **/
  function getDelay() external view returns (uint256);

  /**
   * @dev Getter of grace period constant
   * @return grace period in seconds
   **/
  function getGracePeriod() external view returns (uint256);

  /**
   * @dev Getter of minimum delay constant
   * @return minimum delay in seconds
   **/
  function getMinimumDelay() external view returns (uint256);

  /**
   * @dev Getter of maximum delay constant
   * @return maximum delay in seconds
   **/
  function getMaximumDelay() external view returns (uint256);

  /**
   * @dev Get guardian address
   * @return guardian address
   **/
  function getGuardian() external view returns (address);

  /**
   * @dev Get ActionSet count
   * @return current count of action sets processed
   **/
  function getActionsSetCount() external view returns (uint256);
}