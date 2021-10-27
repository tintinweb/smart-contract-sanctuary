//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.5;
pragma abicoder v2;

import './interfaces/IFxMessageProcessor.sol';
import './BridgeExecutorBase.sol';

contract PolygonBridgeExecutor is BridgeExecutorBase, IFxMessageProcessor {
  address private _fxRootSender;
  address private _fxChild;

  event FxRootSenderUpdate(address previousFxRootSender, address newFxRootSender);
  event FxChildUpdate(address previousFxChild, address newFxChild);

  modifier onlyFxChild() {
    require(msg.sender == _fxChild, 'UNAUTHORIZED_CHILD_ORIGIN');
    _;
  }

  constructor(
    address fxRootSender,
    address fxChild,
    uint256 delay,
    uint256 gracePeriod,
    uint256 minimumDelay,
    uint256 maximumDelay,
    address guardian
  ) BridgeExecutorBase(delay, gracePeriod, minimumDelay, maximumDelay, guardian) {
    _fxRootSender = fxRootSender;
    _fxChild = fxChild;
  }

  /// @inheritdoc IFxMessageProcessor
  function processMessageFromRoot(
    uint256 stateId,
    address rootMessageSender,
    bytes calldata data
  ) external override onlyFxChild {
    require(rootMessageSender == _fxRootSender, 'UNAUTHORIZED_ROOT_ORIGIN');

    address[] memory targets;
    uint256[] memory values;
    string[] memory signatures;
    bytes[] memory calldatas;
    bool[] memory withDelegatecalls;

    (targets, values, signatures, calldatas, withDelegatecalls) = abi.decode(
      data,
      (address[], uint256[], string[], bytes[], bool[])
    );

    _queue(targets, values, signatures, calldatas, withDelegatecalls);
  }

  /**
   * @dev Update the expected address of contract originating a cross-chain tranasaction
   * @param fxRootSender contract originating a cross-chain tranasaction - likely the aave governance executor
   **/
  function updateFxRootSender(address fxRootSender) external onlyThis {
    emit FxRootSenderUpdate(_fxRootSender, fxRootSender);
    _fxRootSender = fxRootSender;
  }

  /**
   * @dev Update the address of the FxChild contract
   * @param fxChild the address of the contract used to foward cross-chain transactions on Polygon
   **/
  function updateFxChild(address fxChild) external onlyThis {
    emit FxChildUpdate(_fxChild, fxChild);
    _fxChild = fxChild;
  }

  /**
   * @dev Get the address currently stored as fxRootSender
   * @return fxRootSender contract originating a cross-chain tranasaction - likely the aave governance executor
   **/
  function getFxRootSender() external view returns (address) {
    return _fxRootSender;
  }

  /**
   * @dev Get the address currently stored as fxChild
   * @return fxChild the address of the contract used to foward cross-chain transactions on Polygon
   **/
  function getFxChild() external view returns (address) {
    return _fxChild;
  }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.5;

interface IFxMessageProcessor {
  /**
   * @dev Process the cross-chain message from an FxChild contract through the ETH/Polygon StateSender
   * @param stateId Id of the cross-chain message created in the ETH/Polygon StateSender
   * @param rootMessageSender address that initally sent this message on ethereum
   * @param data the data from the abi-encoded cross-chain message
   **/
  function processMessageFromRoot(
    uint256 stateId,
    address rootMessageSender,
    bytes calldata data
  ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.7.5;
pragma abicoder v2;

import './dependencies/utilities/SafeMath.sol';
import './interfaces/IBridgeExecutor.sol';

abstract contract BridgeExecutorBase is IBridgeExecutor {
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

  /// @inheritdoc IBridgeExecutor
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

  /// @inheritdoc IBridgeExecutor
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

  /// @inheritdoc IBridgeExecutor
  function getActionsSetById(uint256 actionsSetId)
    external
    view
    override
    returns (ActionsSet memory)
  {
    return _actionsSets[actionsSetId];
  }

  /// @inheritdoc IBridgeExecutor
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

  /// @inheritdoc IBridgeExecutor
  function isActionQueued(bytes32 actionHash) public view override returns (bool) {
    return _queuedActions[actionHash];
  }

  function receiveFunds() external payable {}


  /// @inheritdoc IBridgeExecutor
  function updateGuardian(address guardian) external override onlyThis {
    emit GuardianUpdate(_guardian, guardian);
    _guardian = guardian;
  }


  /// @inheritdoc IBridgeExecutor
  function updateDelay(uint256 delay) external override onlyThis {
    _validateDelay(delay);
    emit DelayUpdate(_delay, delay);
    _delay = delay;
  }

  /// @inheritdoc IBridgeExecutor
  function updateGracePeriod(uint256 gracePeriod) external override onlyThis {
    emit GracePeriodUpdate(_gracePeriod, gracePeriod);
    _gracePeriod = gracePeriod;
  }

  /// @inheritdoc IBridgeExecutor
  function updateMinimumDelay(uint256 minimumDelay) external override onlyThis {
    uint256 previousMinimumDelay = _minimumDelay;
    _minimumDelay = minimumDelay;
    _validateDelay(_delay);
    emit MinimumDelayUpdate(previousMinimumDelay, minimumDelay);
  }

  /// @inheritdoc IBridgeExecutor
  function updateMaximumDelay(uint256 maximumDelay) external override onlyThis {
    uint256 previousMaximumDelay = _maximumDelay;
    _maximumDelay = maximumDelay;
    _validateDelay(_delay);
    emit MaximumDelayUpdate(previousMaximumDelay, maximumDelay);
  }

  /// @inheritdoc IBridgeExecutor
  function getDelay() external view override returns (uint256) {
    return _delay;
  }

  /// @inheritdoc IBridgeExecutor
  function getGracePeriod() external view override returns (uint256) {
    return _gracePeriod;
  }

  /// @inheritdoc IBridgeExecutor
  function getMinimumDelay() external view override returns (uint256) {
    return _minimumDelay;
  }

  /// @inheritdoc IBridgeExecutor
  function getMaximumDelay() external view override returns (uint256) {
    return _maximumDelay;
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
   * @dev Queue the ActionsSet - only callable by the BridgeMessageProvessor
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

interface IBridgeExecutor {
  enum ActionsSetState {Queued, Executed, Canceled, Expired}

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
   * @dev emitted when an ActionsSet is received from the bridge message processor and queued
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
   * @param returnedData address that triggered the ActionsSet execution
   **/
  event ActionsSetExecuted(uint256 id, address indexed initiatorExecution, bytes[] returnedData);

  /**
   * @dev emitted when an ActionsSet is cancelled by the guardian
   * @param id Id of the ActionsSet
   **/
  event ActionsSetCanceled(uint256 id);

  /**
   * @dev emitted when a new bridge is set
   * @param bridge address of the new admin
   * @param initiatorChange address of the creator of this change
   **/
  event NewBridge(address bridge, address indexed initiatorChange);

  /**
   * @dev emitted when a new admin is set
   * @param newAdmin address of the new admin
   **/
  event NewAdmin(address newAdmin);

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
   * @return The current state if the ActionsSet
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
}