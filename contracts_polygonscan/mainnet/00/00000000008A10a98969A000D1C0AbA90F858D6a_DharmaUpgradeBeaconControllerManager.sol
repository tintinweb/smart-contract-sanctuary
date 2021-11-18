/**
 *Submitted for verification at polygonscan.com on 2021-11-17
*/

pragma solidity 0.5.11; // optimization runs: 200, evm version: petersburg


interface DharmaUpgradeBeaconControllerManagerInterface {
  // Fire an event whenever the Adharma Contingency is activated or exited.
  event AdharmaContingencyActivated();
  event AdharmaContingencyExited();

  // Store timestamp and last implementation in case of Adharma Contingency.
  struct AdharmaContingency {
    bool armed;
    bool activated;
    uint256 activationTime;
  }

  // Store all prior implementations and allow for blocking rollbacks to them.
  struct PriorImplementation {
    address implementation;
    bool rollbackBlocked;
  }

  function initiateUpgrade(
    address controller,
    address beacon,
    address implementation,
    uint256 extraTime
  ) external;

  function upgrade(
    address controller, address beacon, address implementation
  ) external;

  function agreeToAcceptControllerOwnership(
    address controller, bool willAcceptOwnership
  ) external;

  function initiateTransferControllerOwnership(
    address controller, address newOwner, uint256 extraTime
  ) external;

  function transferControllerOwnership(
    address controller, address newOwner
  ) external;

  function heartbeat() external;

  function newHeartbeater(address heartbeater) external;

  function armAdharmaContingency(bool armed) external;

  function activateAdharmaContingency() external;

  function rollback(address controller, address beacon, uint256 index) external;

  function blockRollback(
    address controller, address beacon, uint256 index
  ) external;

  function exitAdharmaContingency(
    address smartWalletImplementation, address keyRingImplementation
  ) external;

  function getTotalPriorImplementations(
    address controller, address beacon
  ) external view returns (uint256 totalPriorImplementations);

  function getPriorImplementation(
    address controller, address beacon, uint256 index
  ) external view returns (address priorImplementation, bool rollbackAllowed);

  function contingencyStatus() external view returns (
    bool armed, bool activated, uint256 activationTime
  );

  function heartbeatStatus() external view returns (
    bool expired, uint256 expirationTime
  );
}


interface UpgradeBeaconControllerInterface {
  function upgrade(address beacon, address implementation) external;
}


interface TimelockerModifiersInterface {
  function initiateModifyTimelockInterval(
    bytes4 functionSelector, uint256 newTimelockInterval, uint256 extraTime
  ) external;

  function modifyTimelockInterval(
    bytes4 functionSelector, uint256 newTimelockInterval
  ) external;

  function initiateModifyTimelockExpiration(
    bytes4 functionSelector, uint256 newTimelockExpiration, uint256 extraTime
  ) external;

  function modifyTimelockExpiration(
    bytes4 functionSelector, uint256 newTimelockExpiration
  ) external;
}


interface IndestructibleRegistryCheckerInterface {
  function isRegisteredAsIndestructible(
    address target
  ) external view returns (bool registeredAsIndestructible);
}


library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, "SafeMath: division by zero");
    uint256 c = a / b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath: modulo by zero");
    return a % b;
  }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 *
 * In order to transfer ownership, a recipient must be specified, at which point
 * the specified recipient can call `acceptOwnership` and take ownership.
 */
contract TwoStepOwnable {
  address private _owner;

  address private _newPotentialOwner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initialize contract by setting transaction submitter as initial owner.
   */
  constructor() internal {
    _owner = tx.origin;
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
    require(isOwner(), "TwoStepOwnable: caller is not the owner.");
    _;
  }

  /**
   * @dev Returns true if the caller is the current owner.
   */
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows a new account (`newOwner`) to accept ownership.
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(
      newOwner != address(0),
      "TwoStepOwnable: new potential owner is the zero address."
    );

    _newPotentialOwner = newOwner;
  }

  /**
   * @dev Cancel a transfer of ownership to a new account.
   * Can only be called by the current owner.
   */
  function cancelOwnershipTransfer() public onlyOwner {
    delete _newPotentialOwner;
  }

  /**
   * @dev Transfers ownership of the contract to the caller.
   * Can only be called by a new potential owner set by the current owner.
   */
  function acceptOwnership() public {
    require(
      msg.sender == _newPotentialOwner,
      "TwoStepOwnable: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    emit OwnershipTransferred(_owner, msg.sender);

    _owner = msg.sender;
  }
}


/**
 * @title Timelocker
 * @author 0age
 * @notice This contract allows contracts that inherit it to implement timelocks
 * on functions, where the `_setTimelock` internal function must first be called
 * and passed the target function selector and arguments. Then, a given time
 * interval must first fully transpire before the timelock functions can be
 * successfully called. Furthermore, once a timelock is complete, it will expire
 * after a period of time. In order to change timelock intervals or expirations,
 * the inheriting contract needs to implement `modifyTimelockInterval` and
 * `modifyTimelockExpiration` functions, respectively, as well as functions that
 * call `_setTimelock` in order to initiate the timelocks for those functions.
 * To make a function timelocked, use the `_enforceTimelock` internal function.
 * To set initial defult minimum timelock intervals and expirations, use the
 * `_setInitialTimelockInterval` and `_setInitialTimelockExpiration` internal
 * functions - they can only be used during contract creation. Finally, there
 * are three public getters: `getTimelock`, `getDefaultTimelockInterval`, and
 * `getDefaultTimelockExpiration`.
 */
contract Timelocker {
  using SafeMath for uint256;

  // Fire an event any time a timelock is initiated.
  event TimelockInitiated(
    bytes4 functionSelector, // selector of the function
    uint256 timeComplete,    // timestamp at which the function can be called
    bytes arguments,         // abi-encoded function arguments to call with
    uint256 timeExpired      // timestamp where function can no longer be called
  );

  // Fire an event any time a minimum timelock interval is modified.
  event TimelockIntervalModified(
    bytes4 functionSelector, // selector of the function
    uint256 oldInterval,     // old minimum timelock interval for the function
    uint256 newInterval      // new minimum timelock interval for the function
  );

  // Fire an event any time a default timelock expiration is modified.
  event TimelockExpirationModified(
    bytes4 functionSelector, // selector of the function
    uint256 oldExpiration,   // old default timelock expiration for the function
    uint256 newExpiration    // new default timelock expiration for the function
  );

  // Each timelock has timestamps for when it is complete and when it expires.
  struct Timelock {
    uint128 complete;
    uint128 expires;
  }

  // Functions have a timelock interval and time from completion to expiration.
  struct TimelockDefaults {
    uint128 interval;
    uint128 expiration;
  }

  // Implement a timelock for each function and set of arguments.
  mapping(bytes4 => mapping(bytes32 => Timelock)) private _timelocks;

  // Implement default timelock intervals and expirations for each function.
  mapping(bytes4 => TimelockDefaults) private _timelockDefaults;

  // Only allow one new interval or expiration change at a time per function.
  mapping(bytes4 => mapping(bytes4 => bytes32)) private _protectedTimelockIDs;

  // Store modifyTimelockInterval function selector as a constant.
  bytes4 private constant _MODIFY_TIMELOCK_INTERVAL_SELECTOR = bytes4(
    0xe950c085
  );

  // Store modifyTimelockExpiration function selector as a constant.
  bytes4 private constant _MODIFY_TIMELOCK_EXPIRATION_SELECTOR = bytes4(
    0xd7ce3c6f
  );

  // Set a ridiculously high duration in order to protect against overflows.
  uint256 private constant _A_TRILLION_YEARS = 365000000000000 days;

  /**
   * @notice In the constructor, confirm that selectors specified as constants
   * are correct.
   */
  constructor() internal {
    TimelockerModifiersInterface modifiers;

    bytes4 targetModifyInterval = modifiers.modifyTimelockInterval.selector;
    require(
      _MODIFY_TIMELOCK_INTERVAL_SELECTOR == targetModifyInterval,
      "Incorrect modify timelock interval selector supplied."
    );

    bytes4 targetModifyExpiration = modifiers.modifyTimelockExpiration.selector;
    require(
      _MODIFY_TIMELOCK_EXPIRATION_SELECTOR == targetModifyExpiration,
      "Incorrect modify timelock expiration selector supplied."
    );
  }

  /**
   * @notice View function to check if a timelock for the specified function and
   * arguments has completed.
   * @param functionSelector function to be called.
   * @param arguments The abi-encoded arguments of the function to be called.
   * @return A boolean indicating if the timelock exists or not and the time at
   * which the timelock completes if it does exist.
   */
  function getTimelock(
    bytes4 functionSelector, bytes memory arguments
  ) public view returns (
    bool exists,
    bool completed,
    bool expired,
    uint256 completionTime,
    uint256 expirationTime
  ) {
    // Get timelock ID using the supplied function arguments.
    bytes32 timelockID = keccak256(abi.encodePacked(arguments));

    // Get information on the current timelock, if one exists.
    completionTime = uint256(_timelocks[functionSelector][timelockID].complete);
    exists = completionTime != 0;
    expirationTime = uint256(_timelocks[functionSelector][timelockID].expires);
    completed = exists && now > completionTime;
    expired = exists && now > expirationTime;
  }

  /**
   * @notice View function to check the current minimum timelock interval on a
   * given function.
   * @param functionSelector function to retrieve the timelock interval for.
   * @return The current minimum timelock interval for the given function.
   */
  function getDefaultTimelockInterval(
    bytes4 functionSelector
  ) public view returns (uint256 defaultTimelockInterval) {
    defaultTimelockInterval = uint256(
      _timelockDefaults[functionSelector].interval
    );
  }

  /**
   * @notice View function to check the current default timelock expiration on a
   * given function.
   * @param functionSelector function to retrieve the timelock expiration for.
   * @return The current default timelock expiration for the given function.
   */
  function getDefaultTimelockExpiration(
    bytes4 functionSelector
  ) public view returns (uint256 defaultTimelockExpiration) {
    defaultTimelockExpiration = uint256(
      _timelockDefaults[functionSelector].expiration
    );
  }

  /**
   * @notice Internal function that sets a timelock so that the specified
   * function can be called with the specified arguments. Note that existing
   * timelocks may be extended, but not shortened - this can also be used as a
   * method for "cancelling" a function call by extending the timelock to an
   * arbitrarily long duration. Keep in mind that new timelocks may be created
   * with a shorter duration on functions that already have other timelocks on
   * them, but only if they have different arguments.
   * @param functionSelector selector of the function to be called.
   * @param arguments The abi-encoded arguments of the function to be called.
   * @param extraTime Additional time in seconds to add to the minimum timelock
   * interval for the given function.
   */
  function _setTimelock(
    bytes4 functionSelector, bytes memory arguments, uint256 extraTime
  ) internal {
    // Ensure that the specified extra time will not cause an overflow error.
    require(extraTime < _A_TRILLION_YEARS, "Supplied extra time is too large.");

    // Get timelock ID using the supplied function arguments.
    bytes32 timelockID = keccak256(abi.encodePacked(arguments));

    // For timelock interval or expiration changes, first drop any existing
    // timelock for the function being modified if the argument has changed.
    if (
      functionSelector == _MODIFY_TIMELOCK_INTERVAL_SELECTOR ||
      functionSelector == _MODIFY_TIMELOCK_EXPIRATION_SELECTOR
    ) {
      // Determine the function that will be modified by the timelock.
      (bytes4 modifiedFunction, uint256 duration) = abi.decode(
        arguments, (bytes4, uint256)
      );

      // Ensure that the new timelock duration will not cause an overflow error.
      require(
        duration < _A_TRILLION_YEARS,
        "Supplied default timelock duration to modify is too large."
      );

      // Determine the current timelockID, if any, for the modified function.
      bytes32 currentTimelockID = (
        _protectedTimelockIDs[functionSelector][modifiedFunction]
      );

      // Determine if current timelockID differs from what is currently set.
      if (currentTimelockID != timelockID) {
        // Drop existing timelock if one exists and has a different timelockID.
        if (currentTimelockID != bytes32(0)) {
          delete _timelocks[functionSelector][currentTimelockID];
        }

        // Register the new timelockID as the current protected timelockID.
        _protectedTimelockIDs[functionSelector][modifiedFunction] = timelockID;
      }
    }

    // Get timelock using current time, inverval for timelock ID, & extra time.
    uint256 timelock = uint256(
      _timelockDefaults[functionSelector].interval
    ).add(now).add(extraTime);

    // Get expiration time using timelock duration plus default expiration time.
    uint256 expiration = timelock.add(
      uint256(_timelockDefaults[functionSelector].expiration)
    );

    // Get the current timelock, if one exists.
    Timelock storage timelockStorage = _timelocks[functionSelector][timelockID];

    // Determine the duration of the current timelock.
    uint256 currentTimelock = uint256(timelockStorage.complete);

    // Ensure that the timelock duration does not decrease. Note that a new,
    // shorter timelock may still be set up on the same function in the event
    // that it is provided with different arguments. Also note that this can be
    // circumvented when modifying intervals or expirations by setting a new
    // timelock (removing the old one), then resetting the original timelock but
    // with a shorter duration.
    require(
      currentTimelock == 0 || timelock > currentTimelock,
      "Existing timelocks may only be extended."
    );

    // Set timelock completion and expiration using timelock ID and extra time.
    timelockStorage.complete = uint128(timelock);
    timelockStorage.expires = uint128(expiration);

    // Emit an event with all of the relevant information.
    emit TimelockInitiated(functionSelector, timelock, arguments, expiration);
  }

  /**
   * @notice Internal function for setting a new timelock interval for a given
   * function selector. The default for this function may also be modified, but
   * excessive values will cause the `modifyTimelockInterval` function to become
   * unusable.
   * @param functionSelector the selector of the function to set the timelock
   * interval for.
   * @param newTimelockInterval the new minimum timelock interval to set for the
   * given function.
   */
  function _modifyTimelockInterval(
    bytes4 functionSelector, uint256 newTimelockInterval
  ) internal {
    // Ensure that the timelock has been set and is completed.
    _enforceTimelockPrivate(
      _MODIFY_TIMELOCK_INTERVAL_SELECTOR,
      abi.encode(functionSelector, newTimelockInterval)
    );

    // Clear out the existing timelockID protection for the given function.
    delete _protectedTimelockIDs[
      _MODIFY_TIMELOCK_INTERVAL_SELECTOR
    ][functionSelector];

    // Set new timelock interval and emit a `TimelockIntervalModified` event.
    _setTimelockIntervalPrivate(functionSelector, newTimelockInterval);
  }

  /**
   * @notice Internal function for setting a new timelock expiration for a given
   * function selector. Once the minimum interval has elapsed, the timelock will
   * expire once the specified expiration time has elapsed. Setting this value
   * too low will result in timelocks that are very difficult to execute
   * correctly. Be sure to override the public version of this function with
   * appropriate access controls.
   * @param functionSelector the selector of the function to set the timelock
   * expiration for.
   * @param newTimelockExpiration the new minimum timelock expiration to set for
   * the given function.
   */
  function _modifyTimelockExpiration(
    bytes4 functionSelector, uint256 newTimelockExpiration
  ) internal {
    // Ensure that the timelock has been set and is completed.
    _enforceTimelockPrivate(
      _MODIFY_TIMELOCK_EXPIRATION_SELECTOR,
      abi.encode(functionSelector, newTimelockExpiration)
    );

    // Clear out the existing timelockID protection for the given function.
    delete _protectedTimelockIDs[
      _MODIFY_TIMELOCK_EXPIRATION_SELECTOR
    ][functionSelector];

    // Set new default expiration and emit a `TimelockExpirationModified` event.
    _setTimelockExpirationPrivate(functionSelector, newTimelockExpiration);
  }

  /**
   * @notice Internal function to set an initial timelock interval for a given
   * function selector. Only callable during contract creation.
   * @param functionSelector the selector of the function to set the timelock
   * interval for.
   * @param newTimelockInterval the new minimum timelock interval to set for the
   * given function.
   */
  function _setInitialTimelockInterval(
    bytes4 functionSelector, uint256 newTimelockInterval
  ) internal {
    // Ensure that this function is only callable during contract construction.
    assembly { if extcodesize(address) { revert(0, 0) } }

    // Set the timelock interval and emit a `TimelockIntervalModified` event.
    _setTimelockIntervalPrivate(functionSelector, newTimelockInterval);
  }

  /**
   * @notice Internal function to set an initial timelock expiration for a given
   * function selector. Only callable during contract creation.
   * @param functionSelector the selector of the function to set the timelock
   * expiration for.
   * @param newTimelockExpiration the new minimum timelock expiration to set for
   * the given function.
   */
  function _setInitialTimelockExpiration(
    bytes4 functionSelector, uint256 newTimelockExpiration
  ) internal {
    // Ensure that this function is only callable during contract construction.
    assembly { if extcodesize(address) { revert(0, 0) } }

    // Set the timelock interval and emit a `TimelockExpirationModified` event.
    _setTimelockExpirationPrivate(functionSelector, newTimelockExpiration);
  }

  /**
   * @notice Internal function to ensure that a timelock is complete or expired
   * and to clear the existing timelock if it is complete so it cannot later be
   * reused. The function to enforce the timelock on is inferred from `msg.sig`.
   * @param arguments The abi-encoded arguments of the function to be called.
   */
  function _enforceTimelock(bytes memory arguments) internal {
    // Enforce the relevant timelock.
    _enforceTimelockPrivate(msg.sig, arguments);
  }

  /**
   * @notice Private function to ensure that a timelock is complete or expired
   * and to clear the existing timelock if it is complete so it cannot later be
   * reused.
   * @param functionSelector function to be called.
   * @param arguments The abi-encoded arguments of the function to be called.
   */
  function _enforceTimelockPrivate(
    bytes4 functionSelector, bytes memory arguments
  ) private {
    // Get timelock ID using the supplied function arguments.
    bytes32 timelockID = keccak256(abi.encodePacked(arguments));

    // Get the current timelock, if one exists.
    Timelock memory timelock = _timelocks[functionSelector][timelockID];

    uint256 currentTimelock = uint256(timelock.complete);
    uint256 expiration = uint256(timelock.expires);

    // Ensure that the timelock is set and has completed.
    require(
      currentTimelock != 0 && currentTimelock <= now, "Timelock is incomplete."
    );

    // Ensure that the timelock has not expired.
    require(expiration > now, "Timelock has expired.");

    // Clear out the existing timelock so that it cannot be reused.
    delete _timelocks[functionSelector][timelockID];
  }

  /**
   * @notice Private function for setting a new timelock interval for a given
   * function selector.
   * @param functionSelector the selector of the function to set the timelock
   * interval for.
   * @param newTimelockInterval the new minimum timelock interval to set for the
   * given function.
   */
  function _setTimelockIntervalPrivate(
    bytes4 functionSelector, uint256 newTimelockInterval
  ) private {
    // Ensure that the new timelock interval will not cause an overflow error.
    require(
      newTimelockInterval < _A_TRILLION_YEARS,
      "Supplied minimum timelock interval is too large."
    );

    // Get the existing timelock interval, if any.
    uint256 oldTimelockInterval = uint256(
      _timelockDefaults[functionSelector].interval
    );

    // Update the timelock interval on the provided function.
    _timelockDefaults[functionSelector].interval = uint128(newTimelockInterval);

    // Emit a `TimelockIntervalModified` event with the appropriate arguments.
    emit TimelockIntervalModified(
      functionSelector, oldTimelockInterval, newTimelockInterval
    );
  }

  /**
   * @notice Private function for setting a new timelock expiration for a given
   * function selector.
   * @param functionSelector the selector of the function to set the timelock
   * interval for.
   * @param newTimelockExpiration the new default timelock expiration to set for
   * the given function.
   */
  function _setTimelockExpirationPrivate(
    bytes4 functionSelector, uint256 newTimelockExpiration
  ) private {
    // Ensure that the new timelock expiration will not cause an overflow error.
    require(
      newTimelockExpiration < _A_TRILLION_YEARS,
      "Supplied default timelock expiration is too large."
    );

    // Ensure that the new timelock expiration is not too short.
    require(
      newTimelockExpiration > 1 minutes,
      "New timelock expiration is too short."
    );

    // Get the existing timelock expiration, if any.
    uint256 oldTimelockExpiration = uint256(
      _timelockDefaults[functionSelector].expiration
    );

    // Update the timelock expiration on the provided function.
    _timelockDefaults[functionSelector].expiration = uint128(
      newTimelockExpiration
    );

    // Emit a `TimelockExpirationModified` event with the appropriate arguments.
    emit TimelockExpirationModified(
      functionSelector, oldTimelockExpiration, newTimelockExpiration
    );
  }
}


/**
 * @title DharmaUpgradeBeaconControllerManager
 * @author 0age
 * @notice This contract will be owned by DharmaUpgradeMultisig and will manage
 * upgrades to the global smart wallet and key ring implementation contracts via
 * dedicated control over the "upgrade beacon" controller contracts (and can
 * additionally be used to manage other upgrade beacon controllers). It contains
 * a set of timelocked functions, where the `setTimelock` function must first be
 * called, with the same arguments that the function will be supplied with.
 * Then, a given time interval must first fully transpire before the timelock
 * functions can be successfully called.
 *
 * The timelocked functions currently implemented include:
 *  upgrade(address controller, address implementation)
 *  transferControllerOwnership(address controller, address newOwner)
 *  modifyTimelockInterval(bytes4 functionSelector, uint256 newTimelockInterval)
 *  modifyTimelockExpiration(
 *    bytes4 functionSelector, uint256 newTimelockExpiration
 *  )
 *
 * This contract also allows for immediately triggering a "rollback" to a prior
 * implementation in the event that a new vulnerability is introduced. It can
 * roll back to any implementation for a given controller + upgrade beacon pair
 * unless that implementation has been explicitly "blocked" by the owner.
 *
 * It also specifies dedicated implementations for the Dharma Smart Wallet and
 * Dharma Key Ring upgrade beacons that can be triggered in an emergency or in
 * the event of an extended period of inactivity from Dharma. These contingency
 * implementations give the user the ability to withdraw any funds on their
 * smart wallet by submitting a transaction directly from the account of any of
 * their signing keys, but are otherwise kept as simple as possible. After 48
 * hours in the contingency state, the owner may bypass the standard upgrade
 * timelock and trigger upgrades to the smart wallet and key ring implementation
 * contracts. Note that triggering a rollback, or performing a standard upgrade,
 * will cause the contingency state to be exited if it is active at the time.
 *
 * This contract can transfer ownership of any upgrade beacon controller it owns
 * (subject to the timelock on `transferControllerOwnership`), in order to
 * introduce new upgrade conditions or to otherwise alter the way that upgrades
 * are carried out.
 */
contract DharmaUpgradeBeaconControllerManager is
  DharmaUpgradeBeaconControllerManagerInterface,
  TimelockerModifiersInterface,
  TwoStepOwnable,
  Timelocker {
  using SafeMath for uint256;

  // Store prior implementation addresses for each controller + beacon pair.
  mapping(address => mapping (address => PriorImplementation[])) private _implementations;

  // New controller owners must accept ownership before a transfer can occur.
  mapping(address => mapping(address => bool)) private _willAcceptOwnership;

  // Store information on the current Adharma Contingency status.
  AdharmaContingency private _adharma;

  // Track the last heartbeat timestamp as well as the current heartbeat address
  uint256 private _lastHeartbeat;
  address private _heartbeater;

  // Store address of Smart Wallet Upgrade Beacon Controller as a constant.
  address private constant _SMART_WALLET_UPGRADE_BEACON_CONTROLLER = address(
    0x00000000002226C940b74d674B85E4bE05539663
  );

  // Store the address of the Dharma Smart Wallet Upgrade Beacon as a constant.
  address private constant _DHARMA_SMART_WALLET_UPGRADE_BEACON = address(
    0x000000000026750c571ce882B17016557279ADaa
  );

  // Store the Adharma Smart Wallet Contingency implementation.
  address private constant _ADHARMA_SMART_WALLET_IMPLEMENTATION = address(
    0x00000000009f22dA6fEB6735614563B9Af0339fB
  );

  // Store address of Key Ring Upgrade Beacon Controller as a constant.
  address private constant _KEY_RING_UPGRADE_BEACON_CONTROLLER = address(
    0x00000000011dF015e8aD00D7B2486a88C2Eb8210
  );

  // Store the address of the Dharma Key Ring Upgrade Beacon as a constant.
  address private constant _DHARMA_KEY_RING_UPGRADE_BEACON = address(
    0x0000000000BDA2152794ac8c76B2dc86cbA57cad
  );

  // Store the Adharma Key Ring Contingency implementation.
  address private constant _ADHARMA_KEY_RING_IMPLEMENTATION = address(
    0x000000000053d1F0F8aA88b9001Bec1B49445B3c
  );

  /**
   * @notice In the constructor, set tx.origin as initial owner, the initial
   * minimum timelock interval and expiration values, and some initial variable
   * values. The runtime code of the smart wallet and key ring upgrade beacons,
   * their controllers, and their contingency implementations are also verified.
   * Note that each contract in question has also been registered as
   * indestructible at indestructible.eth - this makes it impossible for their
   * runtime bytecode to be altered from the point of the deployment of this
   * contract.
   */
  constructor() public {
    // Declare variable in order to put constants on the stack for hash checks.
    address extcodehashTarget;

    // Get Smart Wallet Upgrade Beacon Controller runtime code hash.
    bytes32 smartWalletControllerHash;
    extcodehashTarget = _SMART_WALLET_UPGRADE_BEACON_CONTROLLER;
    assembly { smartWalletControllerHash := extcodehash(extcodehashTarget) }

    // Get Smart Wallet Upgrade Beacon runtime code hash.
    bytes32 smartWalletUpgradeBeaconHash;
    extcodehashTarget = _DHARMA_SMART_WALLET_UPGRADE_BEACON;
    assembly { smartWalletUpgradeBeaconHash := extcodehash(extcodehashTarget) }

    // Get Adharma Smart Wallet implementation runtime code hash.
    bytes32 adharmaSmartWalletHash;
    extcodehashTarget = _ADHARMA_SMART_WALLET_IMPLEMENTATION;
    assembly { adharmaSmartWalletHash := extcodehash(extcodehashTarget) }

    // Get Key Ring Upgrade Beacon Controller runtime code hash.
    bytes32 keyRingControllerHash;
    extcodehashTarget = _KEY_RING_UPGRADE_BEACON_CONTROLLER;
    assembly { keyRingControllerHash := extcodehash(extcodehashTarget) }

    // Get Key Ring Upgrade Beacon runtime code hash.
    bytes32 keyRingUpgradeBeaconHash;
    extcodehashTarget = _DHARMA_KEY_RING_UPGRADE_BEACON;
    assembly { keyRingUpgradeBeaconHash := extcodehash(extcodehashTarget) }

    // Get Adharma Key Ring implementation runtime code hash.
    bytes32 adharmaKeyRingHash;
    extcodehashTarget = _ADHARMA_KEY_RING_IMPLEMENTATION;
    assembly { adharmaKeyRingHash := extcodehash(extcodehashTarget) }

    // Verify the runtime hashes of smart wallet and key ring upgrade contracts.
    bool allRuntimeCodeHashesMatchExpectations = (
      smartWalletControllerHash == bytes32(
        0x6586626c057b68d99775ec4cae9aa5ce96907fb5f8d8c8046123f49f8ad93f1e
      ) &&
      smartWalletUpgradeBeaconHash == bytes32(
        0xca51e36cf6ab9af9a6f019a923588cd6df58aa1e58f5ac1639da46931167e436
      ) &&
      adharmaSmartWalletHash == bytes32(
        0xa8d641085d608420781e0b49768aa57d6e19dfeef227f839c33e2e00e2b8d82e
      ) &&
      keyRingControllerHash == bytes32(
        0xb98d105738145a629aeea247cee5f12bb25eabc1040eb01664bbc95f0e7e8d39
      ) &&
      keyRingUpgradeBeaconHash == bytes32(
        0xb65d03cdc199085ae86b460e897b6d53c08a6c6d436063ea29822ea80d90adc3
      ) &&
      adharmaKeyRingHash == bytes32(
        0xc5a2c3124a4bf13329ce188ce5813ad643bedd26058ae22958f6b23962070949
      )
    );

    // Ensure that the all of the runtime code hashes match expectations.
    require(
      allRuntimeCodeHashesMatchExpectations,
      "Runtime code hash of supplied upgradeability contracts is incorrect."
    );

    // Set up interface to check Indestructible registry for indestructibility.
    IndestructibleRegistryCheckerInterface indestructible;
    indestructible = IndestructibleRegistryCheckerInterface(
      0x0000000000f55ff05D0080fE17A63b16596Fd59f
    );

    // Ensure that each specified upgradeability contract is indestructible.
    require(
      indestructible.isRegisteredAsIndestructible(
        _SMART_WALLET_UPGRADE_BEACON_CONTROLLER
      ) &&
      indestructible.isRegisteredAsIndestructible(
        _DHARMA_SMART_WALLET_UPGRADE_BEACON
      ) &&
      indestructible.isRegisteredAsIndestructible(
        _ADHARMA_SMART_WALLET_IMPLEMENTATION
      ) &&
      indestructible.isRegisteredAsIndestructible(
        _KEY_RING_UPGRADE_BEACON_CONTROLLER
      ) &&
      indestructible.isRegisteredAsIndestructible(
        _DHARMA_KEY_RING_UPGRADE_BEACON
      ) &&
      indestructible.isRegisteredAsIndestructible(
        _ADHARMA_KEY_RING_IMPLEMENTATION
      ),
      "Supplied upgradeability contracts are not registered as indestructible."
    );

    // Set initial minimum timelock interval values.
    _setInitialTimelockInterval(
      this.transferControllerOwnership.selector, 4 weeks
    );
    _setInitialTimelockInterval(this.modifyTimelockInterval.selector, 4 weeks);
    _setInitialTimelockInterval(
      this.modifyTimelockExpiration.selector, 4 weeks
    );
    _setInitialTimelockInterval(this.upgrade.selector, 7 days);

    // Set initial default timelock expiration values.
    _setInitialTimelockExpiration(
      this.transferControllerOwnership.selector, 7 days
    );
    _setInitialTimelockExpiration(this.modifyTimelockInterval.selector, 7 days);
    _setInitialTimelockExpiration(
      this.modifyTimelockExpiration.selector, 7 days
    );
    _setInitialTimelockExpiration(this.upgrade.selector, 7 days);

    // Set the initial owner as the initial heartbeater and trigger a heartbeat.
    _heartbeater = tx.origin;
    _lastHeartbeat = now;
  }

  /**
   * @notice Initiates a timelocked upgrade process via a given controller and
   * upgrade beacon to a given implementation address. Only the owner may call
   * this function. Once the timelock period is complete (and before it has
   * expired) the owner may call `upgrade` to complete the process and trigger
   * the upgrade.
   * @param controller address of controller to call into that will trigger the
   * update to the specified upgrade beacon.
   * @param beacon address of upgrade beacon to set the new implementation on.
   * @param implementation the address of the new implementation.
   * @param extraTime Additional time in seconds to add to the timelock.
   */
  function initiateUpgrade(
    address controller,
    address beacon,
    address implementation,
    uint256 extraTime
  ) external onlyOwner {
    require(controller != address(0), "Must specify a controller address.");

    require(beacon != address(0), "Must specify a beacon address.");

    // Ensure that the implementaton contract is not the null address.
    require(
      implementation != address(0),
      "Implementation cannot be the null address."
    );

    // Ensure that the implementation contract has code via extcodesize.
    uint256 size;
    assembly {
      size := extcodesize(implementation)
    }
    require(size > 0, "Implementation must have contract code.");

    // Set the timelock and emit a `TimelockInitiated` event.
    _setTimelock(
      this.upgrade.selector,
      abi.encode(controller, beacon, implementation),
      extraTime
    );
  }

  /**
   * @notice Timelocked function to set a new implementation address on an
   * upgrade beacon contract. Note that calling this function will cause the
   * contincency state to be exited if it is currently active. Only the owner
   * may call this function.
   * @param controller address of controller to call into that will trigger the
   * update to the specified upgrade beacon.
   * @param beacon address of upgrade beacon to set the new implementation on.
   * @param implementation the address of the new implementation.
   */
  function upgrade(
    address controller, address beacon, address implementation
  ) external onlyOwner {
    // Ensure that the timelock has been set and is completed.
    _enforceTimelock(abi.encode(controller, beacon, implementation));

    // Exit contingency state if it is currently active and trigger a heartbeat.
    _exitAdharmaContingencyIfActiveAndTriggerHeartbeat();

    // Call controller with beacon to upgrade and implementation to upgrade to.
    _upgrade(controller, beacon, implementation);
  }

  /**
   * @notice Allow a new potential owner of an upgrade beacon controller to
   * accept ownership of the controller. Anyone may call this function, though
   * ownership transfer of the controller in question will only proceed once the
   * owner calls `transferControllerOwnership`.
   * @param controller address of controller to allow ownership transfer for.
   * @param willAcceptOwnership a boolean signifying if an ownership transfer to
   * the caller is acceptable.
   */
  function agreeToAcceptControllerOwnership(
    address controller, bool willAcceptOwnership
  ) external {
    require(controller != address(0), "Must specify a controller address.");

    // Register whether or not the new owner is willing to accept ownership.
    _willAcceptOwnership[controller][msg.sender] = willAcceptOwnership;
  }

  /**
   * @notice Initiates a timelock to set a new owner on an upgrade beacon
   * controller that is owned by this contract. Only the owner may call this
   * function.
   * @param controller address of controller to transfer ownership of.
   * @param newOwner address to assign ownership of the controller to.
   * @param extraTime Additional time in seconds to add to the timelock.
   */
  function initiateTransferControllerOwnership(
    address controller, address newOwner, uint256 extraTime
  ) external onlyOwner {
    require(controller != address(0), "No controller address provided.");

    require(newOwner != address(0), "No new owner address provided.");

    // Ensure that the new owner has confirmed that it can accept ownership.
    require(
      _willAcceptOwnership[controller][newOwner],
      "New owner must agree to accept ownership of the given controller."
    );

    // Set the timelock and emit a `TimelockInitiated` event.
    _setTimelock(
      this.transferControllerOwnership.selector,
      abi.encode(controller, newOwner),
      extraTime
    );
  }

  /**
   * @notice Timelocked function to set a new owner on an upgrade beacon
   * controller that is owned by this contract.
   * @param controller address of controller to transfer ownership of.
   * @param newOwner address to assign ownership of the controller to.
   */
  function transferControllerOwnership(
    address controller, address newOwner
  ) external onlyOwner {
    // Ensure that the new owner has confirmed that it can accept ownership.
    require(
      _willAcceptOwnership[controller][newOwner],
      "New owner must agree to accept ownership of the given controller."
    );

    // Ensure that the timelock has been set and is completed.
    _enforceTimelock(abi.encode(controller, newOwner));

    // Transfer ownership of the controller to the new owner.
    TwoStepOwnable(controller).transferOwnership(newOwner);
  }

  /**
   * @notice Send a new heartbeat. If 90 days pass without a heartbeat, anyone
   * may trigger the Adharma Contingency and force an upgrade to any controlled
   * upgrade beacon.
   */
  function heartbeat() external {
    require(msg.sender == _heartbeater, "Must be called from the heartbeater.");
    _lastHeartbeat = now;
  }

  /**
   * @notice Set a new heartbeater.
   * @param heartbeater address to designate as the heartbeating address.
   */
  function newHeartbeater(address heartbeater) external onlyOwner {
    require(heartbeater != address(0), "Must specify a heartbeater address.");
    _heartbeater = heartbeater;
  }

  /**
   * @notice Arm the Adharma Contingency upgrade. This is required as an extra
   * safeguard against accidentally triggering the Adharma Contingency. Note
   * that there is a possibility for griefing in the event that 90 days have
   * passed since the last heartbeat - this can be circumvented if necessary by
   * calling both `armAdharmaContingency` and `activateAdharmaContingency` as
   * part of the same transaction.
   * @param armed Boolean that signifies the desired armed status.
   */
  function armAdharmaContingency(bool armed) external {
    // Non-owners can only call if 90 days have passed since the last heartbeat.
    _ensureCallerIsOwnerOrDeadmansSwitchActivated();

    // Arm (or disarm) the Adharma Contingency.
    _adharma.armed = armed;
  }

  /**
   * @notice Trigger the Adharma Contingency upgrade. This requires that the
   * owner first call `armAdharmaContingency` and set `armed` to `true`. This is
   * only to be invoked in cases of a time-sensitive emergency, or if the owner
   * has become inactive for over 90 days. It also requires that the Upgrade
   * Beacon Controller Manager contract still owns the specified upgrade beacon
   * controllers. It will simultaneously upgrade the Smart Wallet and the Key
   * Ring implementations to their designated contingency implementations.
   */
  function activateAdharmaContingency() external {
    // Non-owners can only call if 90 days have passed since the last heartbeat.
    _ensureCallerIsOwnerOrDeadmansSwitchActivated();

    // Ensure that the Adharma Contingency has been armed.
    require(
      _adharma.armed,
      "Adharma Contingency is not armed - are SURE you meant to call this?"
    );

    // Ensure that the Adharma Contingency is not already active.
    require(!_adharma.activated, "Adharma Contingency is already activated.");

    // Ensure this contract still owns the required upgrade beacon controllers.
    _ensureOwnershipOfSmartWalletAndKeyRingControllers();

    // Mark the Adharma Contingency as having been activated.
    _adharma = AdharmaContingency({
      armed: false,
      activated: true,
      activationTime: now
    });

    // Trigger upgrades on both beacons to the Adharma implementation contracts.
    _upgrade(
      _SMART_WALLET_UPGRADE_BEACON_CONTROLLER,
      _DHARMA_SMART_WALLET_UPGRADE_BEACON,
      _ADHARMA_SMART_WALLET_IMPLEMENTATION
    );
    _upgrade(
      _KEY_RING_UPGRADE_BEACON_CONTROLLER,
      _DHARMA_KEY_RING_UPGRADE_BEACON,
      _ADHARMA_KEY_RING_IMPLEMENTATION
    );

    // Emit an event to signal that the Adharma Contingency has been activated.
    emit AdharmaContingencyActivated();
  }

  /**
   * @notice Roll back an upgrade to a prior implementation and exit from
   * contingency status if one currently exists. Note that you can also "roll
   * forward" a rollback to restore it to a more recent implementation that has
   * been rolled back from. If the Adharma Contingency state is activated,
   * triggering a rollback will cause it to be immediately exited - in that
   * event it is recommended to simultaneously roll back both the smart wallet
   * implementation and the key ring implementation.
   * @param controller address of controller to call into that will trigger the
   * rollback on the specified upgrade beacon.
   * @param beacon address of upgrade beacon to roll back to the last
   * implementation.
   * @param index uint256 the index of the implementation to roll back to.
   */
  function rollback(
    address controller, address beacon, uint256 index
  ) external onlyOwner {
    // Ensure that there is an implementation address to roll back to.
    require(
      _implementations[controller][beacon].length > index,
      "No implementation with the given index available to roll back to."
    );

    // Get the specified prior implementation.
    PriorImplementation memory priorImplementation = (
      _implementations[controller][beacon][index]
    );

    // Ensure rollbacks to the implementation have not already been blocked.
    require(
      !priorImplementation.rollbackBlocked,
      "Rollbacks to this implementation have been permanently blocked."
    );

    // Exit contingency state if it is currently active and trigger a heartbeat.
    _exitAdharmaContingencyIfActiveAndTriggerHeartbeat();

    // Upgrade to the specified implementation contract.
    _upgrade(controller, beacon, priorImplementation.implementation);
  }

  /**
   * @notice Permanently prevent a prior implementation from being rolled back
   * to. This can be used to prevent accidentally rolling back to an
   * implementation with a known vulnerability, or to remove the possibility of
   * a rollback once the security of more recent implementations has been firmly
   * established. Note that a blocked implementation can still be upgraded to in
   * the usual fashion, and after an additional upgrade it will become possible
   * to roll back to it unless it is blocked again. Only the owner may call this
   * function.
   * @param controller address of controller that was used to set the
   * implementation.
   * @param beacon address of upgrade beacon that the implementation was set on.
   * @param index uint256 the index of the implementation to block rollbacks to.
   */
  function blockRollback(
    address controller, address beacon, uint256 index
  ) external onlyOwner {
    // Ensure that there is an implementation address to roll back to.
    require(
      _implementations[controller][beacon].length > index,
      "No implementation with the given index available to block."
    );

    // Ensure rollbacks to the implementation have not already been blocked.
    require(
      !_implementations[controller][beacon][index].rollbackBlocked,
      "Rollbacks to this implementation are aleady blocked."
    );

    // Permanently lock rollbacks to the implementation in question.
    _implementations[controller][beacon][index].rollbackBlocked = true;
  }

  /**
   * @notice Exit the Adharma Contingency by upgrading to new smart wallet and
   * key ring implementation contracts. This requires that the contingency is
   * currently activated and that at least 48 hours has elapsed since it was
   * activated. Only the owner may call this function.
   * @param smartWalletImplementation Address of the new smart wallet
   * implementation.
   * @param keyRingImplementation Address of the new key ring implementation.
   */
  function exitAdharmaContingency(
    address smartWalletImplementation, address keyRingImplementation
  ) external onlyOwner {
    // Ensure that the Adharma Contingency is currently active.
    require(
      _adharma.activated, "Adharma Contingency is not currently activated."
    );

    // Ensure that at least 48 hours has elapsed since the contingency commenced.
    require(
      now > _adharma.activationTime + 48 hours,
      "Cannot exit contingency with a new upgrade until 48 hours have elapsed."
    );

    // Ensure this contract still owns the required upgrade beacon controllers.
    _ensureOwnershipOfSmartWalletAndKeyRingControllers();

    // Exit the contingency state and trigger a heartbeat.
    _exitAdharmaContingencyIfActiveAndTriggerHeartbeat();

    // Trigger upgrades on both beacons to the Adharma implementation contracts.
    _upgrade(
      _SMART_WALLET_UPGRADE_BEACON_CONTROLLER,
      _DHARMA_SMART_WALLET_UPGRADE_BEACON,
      smartWalletImplementation
    );
    _upgrade(
      _KEY_RING_UPGRADE_BEACON_CONTROLLER,
      _DHARMA_KEY_RING_UPGRADE_BEACON,
      keyRingImplementation
    );
  }

  /**
   * @notice Sets the timelock for a new timelock interval for a given function
   * selector. Only the owner may call this function.
   * @param functionSelector the selector of the function to set the timelock
   * interval for.
   * @param newTimelockInterval The new timelock interval to set for the given
   * function selector.
   * @param extraTime Additional time in seconds to add to the timelock.
   */
  function initiateModifyTimelockInterval(
    bytes4 functionSelector, uint256 newTimelockInterval, uint256 extraTime
  ) external onlyOwner {
    // Ensure that a function selector is specified (no 0x00000000 selector).
    require(
      functionSelector != bytes4(0),
      "Function selector cannot be empty."
    );

    // Ensure a timelock interval over eight weeks is not set on this function.
    if (functionSelector == this.modifyTimelockInterval.selector) {
      require(
        newTimelockInterval <= 8 weeks,
        "Timelock interval of modifyTimelockInterval cannot exceed eight weeks."
      );
    }

    // Set the timelock and emit a `TimelockInitiated` event.
    _setTimelock(
      this.modifyTimelockInterval.selector,
      abi.encode(functionSelector, newTimelockInterval),
      extraTime
    );
  }

  /**
   * @notice Sets a new timelock interval for a given function selector. The
   * default for this function may also be modified, but has a maximum allowable
   * value of eight weeks. Only the owner may call this function.
   * @param functionSelector the selector of the function to set the timelock
   * interval for.
   * @param newTimelockInterval The new timelock interval to set for the given
   * function selector.
   */
  function modifyTimelockInterval(
    bytes4 functionSelector, uint256 newTimelockInterval
  ) external onlyOwner {
    // Ensure that a function selector is specified (no 0x00000000 selector).
    require(
      functionSelector != bytes4(0),
      "Function selector cannot be empty."
    );

    // Continue via logic in the inherited `_modifyTimelockInterval` function.
    _modifyTimelockInterval(functionSelector, newTimelockInterval);
  }

  /**
   * @notice Sets a new timelock expiration for a given function selector. The
   * default Only the owner may call this function. New expiration durations may
   * not exceed one month.
   * @param functionSelector the selector of the function to set the timelock
   * expiration for.
   * @param newTimelockExpiration The new timelock expiration to set for the
   * given function selector.
   * @param extraTime Additional time in seconds to add to the timelock.
   */
  function initiateModifyTimelockExpiration(
    bytes4 functionSelector, uint256 newTimelockExpiration, uint256 extraTime
  ) external onlyOwner {
    // Ensure that a function selector is specified (no 0x00000000 selector).
    require(
      functionSelector != bytes4(0),
      "Function selector cannot be empty."
    );

    // Ensure that the supplied default expiration does not exceed 1 month.
    require(
      newTimelockExpiration <= 30 days,
      "New timelock expiration cannot exceed one month."
    );

    // Ensure a timelock expiration under one hour is not set on this function.
    if (functionSelector == this.modifyTimelockExpiration.selector) {
      require(
        newTimelockExpiration >= 60 minutes,
        "Expiration of modifyTimelockExpiration must be at least an hour long."
      );
    }

    // Set the timelock and emit a `TimelockInitiated` event.
    _setTimelock(
      this.modifyTimelockExpiration.selector,
      abi.encode(functionSelector, newTimelockExpiration),
      extraTime
    );
  }

  /**
   * @notice Sets a new timelock expiration for a given function selector. The
   * default for this function may also be modified, but has a minimum allowable
   * value of one hour. Only the owner may call this function.
   * @param functionSelector the selector of the function to set the timelock
   * expiration for.
   * @param newTimelockExpiration The new timelock expiration to set for the
   * given function selector.
   */
  function modifyTimelockExpiration(
    bytes4 functionSelector, uint256 newTimelockExpiration
  ) external onlyOwner {
    // Ensure that a function selector is specified (no 0x00000000 selector).
    require(
      functionSelector != bytes4(0),
      "Function selector cannot be empty."
    );

    // Continue via logic in the inherited `_modifyTimelockExpiration` function.
    _modifyTimelockExpiration(
      functionSelector, newTimelockExpiration
    );
  }

  /**
   * @notice Get a count of total prior implementations for a given controller
   * and upgrade beacon.
   * @param controller address of controller that was used to set the
   * implementations.
   * @param beacon address of upgrade beacon that the implementations were set
   * on.
   * @return The total number of prior implementations.
   */
  function getTotalPriorImplementations(
    address controller, address beacon
  ) external view returns (uint256 totalPriorImplementations) {
    // Get the total number of prior implementation contracts.
    totalPriorImplementations = _implementations[controller][beacon].length;
  }

  /**
   * @notice Get an implementation contract that has been used in the past for a
   * specific controller and beacon by index, and determine whether or not the
   * implementation can be rolled back to or not.
   * @param controller address of controller that was used to set the
   * implementation.
   * @param beacon address of upgrade beacon that the implementation was set on.
   * @param index uint256 the index of the implementation.
   * @return The address of the prior implementation if one exists and a boolean
   * representing whether or not the prior implementation can be rolled back to.
   */
  function getPriorImplementation(
    address controller, address beacon, uint256 index
  ) external view returns (address priorImplementation, bool rollbackAllowed) {
    // Ensure that there is an implementation address with the given index.
    require(
      _implementations[controller][beacon].length > index,
      "No implementation contract found with the given index."
    );

    // Get information on the specified prior implementation contract.
    PriorImplementation memory implementation = (
      _implementations[controller][beacon][index]
    );

    priorImplementation = implementation.implementation;
    rollbackAllowed = (
      priorImplementation != address(0) && !implementation.rollbackBlocked
    );
  }

  /**
   * @notice Determine if the Adharma Contingency state is currently armed or
   * activated, and if so, what time it was activated. An upgrade to arbitrary
   * smart wallet and key ring implementations can be performed by the owner
   * after 48 hours has elapsed in the contingency state.
   */
  function contingencyStatus() external view returns (
    bool armed, bool activated, uint256 activationTime
  ) {
    AdharmaContingency memory adharma = _adharma;

    armed = adharma.armed;
    activated = adharma.activated;
    activationTime = adharma.activationTime;
  }

  /**
   * @notice Determine if the deadman's switch has expired and get the time at
   * which it is set to expire (i.e. 90 days from the last heartbeat).
   * @return A boolean signifying whether the upgrade beacon controller is in an
   * expired state, as well as the expiration time.
   */
  function heartbeatStatus() external view returns (
    bool expired, uint256 expirationTime
  ) {
    (expired, expirationTime) = _heartbeatStatus();
  }

  /**
   * @notice Internal view function to determine if the deadman's switch has
   * expired and to get the time at which it is set to expire (i.e. 90 days from
   * the last heartbeat).
   * @return A boolean signifying whether the upgrade beacon controller is in an
   * expired state, as well as the expiration time.
   */
  function _heartbeatStatus() internal view returns (
    bool expired, uint256 expirationTime
  ) {
    expirationTime = _lastHeartbeat + 90 days;
    expired = now > expirationTime;
  }

  /**
   * @notice Private function that sets a new implementation address on an
   * upgrade beacon contract.
   * @param controller address of controller to call into that will trigger the
   * update to the specified upgrade beacon.
   * @param beacon address of upgrade beacon to set the new implementation on.
   * @param implementation the address of the new implementation.
   */
  function _upgrade(
    address controller, address beacon, address implementation
  ) private {
    // Ensure that the implementaton contract is not the null address.
    require(
      implementation != address(0),
      "Implementation cannot be the null address."
    );

    // Ensure that the implementation contract has code via extcodesize.
    uint256 size;
    assembly {
      size := extcodesize(implementation)
    }
    require(size > 0, "Implementation must have contract code.");

    // Try to get current implementation and store it as a prior implementation.
    (bool ok, bytes memory returnData) = beacon.call("");
    if (ok && returnData.length == 32) {
      address currentImplementation = abi.decode(returnData, (address));

      _implementations[controller][beacon].push(PriorImplementation({
        implementation: currentImplementation,
        rollbackBlocked: false
      }));
    }

    // Trigger the upgrade to the new implementation contract.
    UpgradeBeaconControllerInterface(controller).upgrade(
      beacon, implementation
    );
  }

  /**
   * @notice Private function that exits the Adharma Contingency if currently
   * active and triggers a heartbeat.
   */
  function _exitAdharmaContingencyIfActiveAndTriggerHeartbeat() private {
    // Exit the contingency state if there is currently one active or armed.
    if (_adharma.activated || _adharma.armed) {

      // Only emit an `AdharmaContingencyExited` if it is actually activated.
      if (_adharma.activated) {
        emit AdharmaContingencyExited();
      }

      delete _adharma;
    }

    // Reset the heartbeat to the current time.
    _lastHeartbeat = now;
  }

  /**
   * @notice Private view function to enforce that either the owner is the
   * caller, or that the deadman's switch has been activated as a result of 90
   * days passing without a heartbeat.
   */
  function _ensureCallerIsOwnerOrDeadmansSwitchActivated() private view {
    // Do not check if heartbeat has expired if the owner is the caller.
    if (!isOwner()) {
      // Determine if 90 days have passed since the last heartbeat.
      (bool expired, ) = _heartbeatStatus();

      // Ensure that the deadman's switch is active.
      require(
        expired,
        "Only callable by the owner or after 90 days without a heartbeat."
      );
    }
  }

  /**
   * @notice Private view function to enforce that this contract is still the
   * owner of the Dharma Smart Wallet Upgrade Beacon Controller and the Dharma
   * Key Ring Upgrade Beacon Controller prior to triggering the Adharma
   * Contingency, or prior to upgrading those contracts on exiting the Adharma
   * Contingency.
   */
  function _ensureOwnershipOfSmartWalletAndKeyRingControllers() private view {
    // Ensure this contract still owns the required upgrade beacon controllers.
    require(
      TwoStepOwnable(_SMART_WALLET_UPGRADE_BEACON_CONTROLLER).isOwner(),
      "This contract no longer owns the Smart Wallet Upgrade Beacon Controller."
    );
    require(
      TwoStepOwnable(_KEY_RING_UPGRADE_BEACON_CONTROLLER).isOwner(),
      "This contract no longer owns the Key Ring Upgrade Beacon Controller."
    );
  }
}