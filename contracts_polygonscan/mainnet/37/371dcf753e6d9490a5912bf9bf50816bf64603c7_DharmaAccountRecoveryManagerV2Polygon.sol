/**
 *Submitted for verification at polygonscan.com on 2021-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; // optimization runs: 200


interface DharmaAccountRecoveryManagerInterface {
  // Fires an event whenever a user signing key is recovered for an account.
  event Recovery(
    address indexed wallet, address oldUserSigningKey, address newUserSigningKey
  );

  // Fire an event whenever account recovery is disabled for an account.
  event RecoveryDisabled(address wallet);

  function initiateAccountRecovery(
    address smartWallet, address userSigningKey, uint256 extraTime
  ) external;

  function initiateAccountRecoveryDisablement(
    address smartWallet, uint256 extraTime
  ) external;

  function recover(address wallet, address newUserSigningKey) external;

  function disableAccountRecovery(address wallet) external;

  function accountRecoveryDisabled(
    address wallet
  ) external view returns (bool hasDisabledAccountRecovery);
}


interface DharmaAccountRecoveryManagerV2Interface {
  // Fires an event whenever a pending account recovery is cancelled.
  event RecoveryCancelled(
    address indexed wallet, address cancelledUserSigningKey
  );

  event RecoveryDisablementCancelled(address wallet);

  event RoleModified(Role indexed role, address account);

  event RolePaused(Role indexed role);

  event RoleUnpaused(Role indexed role);

  enum Role {
    OPERATOR,
    RECOVERER,
    CANCELLER,
    DISABLER,
    PAUSER
  }

  struct RoleStatus {
    address account;
    bool paused;
  }

  function cancelAccountRecovery(
    address smartWallet, address newUserSigningKey
  ) external;

  function cancelAccountRecoveryDisablement(address smartWallet) external;

  function setRole(Role role, address account) external;

  function removeRole(Role role) external;

  function pause(Role role) external;

  function unpause(Role role) external;

  function isPaused(Role role) external view returns (bool paused);

  function isRole(Role role) external view returns (bool hasRole);

  function getOperator() external view returns (address operator);

  function getRecoverer() external view returns (address recoverer);

  function getCanceller() external view returns (address canceller);

  function getDisabler() external view returns (address disabler);

  function getPauser() external view returns (address pauser);
}


interface DharmaSmartWalletRecoveryInterface {
  function recover(address newUserSigningKey) external;
  function getUserSigningKey() external view returns (address userSigningKey);
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


interface TimelockerInterface {
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

  function getTimelock(
    bytes4 functionSelector, bytes calldata arguments
  ) external view returns (
    bool exists,
    bool completed,
    bool expired,
    uint256 completionTime,
    uint256 expirationTime
  );

  function getDefaultTimelockInterval(
    bytes4 functionSelector
  ) external view returns (uint256 defaultTimelockInterval);

  function getDefaultTimelockExpiration(
    bytes4 functionSelector
  ) external view returns (uint256 defaultTimelockExpiration);
}


/**
 * @title TimelockerV2
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
 * functions - they can only be used during contract creation. Additionally,
 * there are three external getters (and internal equivalents): `getTimelock`,
 * `getDefaultTimelockInterval`, and `getDefaultTimelockExpiration`. Finally,
 * version two of the timelocker builds on version one by including an internal
 * `_expireTimelock` function for expiring an existing timelock, which can then
 * be reactivated as long as the completion time does not become shorter than
 * the original completion time.
 */
contract TimelockerV2 is TimelockerInterface {

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
  constructor() {
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
   * @param functionSelector Function to be called.
   * @param arguments The abi-encoded arguments of the function to be called.
   * @return exists - a boolean indicating if the timelock exists
   * @return completed -  a boolean indicating if the timelock has completed
   * @return expired -  a boolean indicating if the timelock has expired
   * @return completionTime - time at which the timelock completed
   * @return expirationTime - time at which the timelock expired
   */
  function getTimelock(
    bytes4 functionSelector, bytes memory arguments
  ) public view override returns (
    bool exists,
    bool completed,
    bool expired,
    uint256 completionTime,
    uint256 expirationTime
  ) {
    // Get information on the current timelock, if one exists.
    (exists, completed, expired, completionTime, expirationTime) = _getTimelock(
      functionSelector, arguments
    );
  }

  /**
   * @notice View function to check the current minimum timelock interval on a
   * given function.
   * @param functionSelector Function to retrieve the timelock interval for.
   * @return defaultTimelockInterval - the current minimum timelock interval for the given function.
   */
  function getDefaultTimelockInterval(
    bytes4 functionSelector
  ) public view override returns (uint256 defaultTimelockInterval) {
    defaultTimelockInterval = _getDefaultTimelockInterval(functionSelector);
  }

  /**
   * @notice View function to check the current default timelock expiration on a
   * given function.
   * @param functionSelector Function to retrieve the timelock expiration for.
   * @return defaultTimelockExpiration - the current default timelock expiration for the given function.
   */
  function getDefaultTimelockExpiration(
    bytes4 functionSelector
  ) public view override returns (uint256 defaultTimelockExpiration) {
    defaultTimelockExpiration = _getDefaultTimelockExpiration(functionSelector);
  }

  /**
   * @notice Internal function that sets a timelock so that the specified
   * function can be called with the specified arguments. Note that existing
   * timelocks may be extended, but not shortened - this can also be used as a
   * method for "cancelling" a function call by extending the timelock to an
   * arbitrarily long duration. Keep in mind that new timelocks may be created
   * with a shorter duration on functions that already have other timelocks on
   * them, but only if they have different arguments.
   * @param functionSelector Selector of the function to be called.
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
    ) + block.timestamp + extraTime;

    // Get expiration time using timelock duration plus default expiration time.
    uint256 expiration = timelock + uint256(_timelockDefaults[functionSelector].expiration);

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
   * @param functionSelector The selector of the function to set the timelock
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
   * @param functionSelector The selector of the function to set the timelock
   * expiration for.
   * @param newTimelockExpiration The new minimum timelock expiration to set for
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
   * @param functionSelector The selector of the function to set the timelock
   * interval for.
   * @param newTimelockInterval The new minimum timelock interval to set for the
   * given function.
   */
  function _setInitialTimelockInterval(
    bytes4 functionSelector, uint256 newTimelockInterval
  ) internal {
    // Ensure that this function is only callable during contract construction.
    assembly { if extcodesize(address()) { revert(0, 0) } }

    // Set the timelock interval and emit a `TimelockIntervalModified` event.
    _setTimelockIntervalPrivate(functionSelector, newTimelockInterval);
  }

  /**
   * @notice Internal function to set an initial timelock expiration for a given
   * function selector. Only callable during contract creation.
   * @param functionSelector The selector of the function to set the timelock
   * expiration for.
   * @param newTimelockExpiration The new minimum timelock expiration to set for
   * the given function.
   */
  function _setInitialTimelockExpiration(
    bytes4 functionSelector, uint256 newTimelockExpiration
  ) internal {
    // Ensure that this function is only callable during contract construction.
    assembly { if extcodesize(address()) { revert(0, 0) } }

    // Set the timelock interval and emit a `TimelockExpirationModified` event.
    _setTimelockExpirationPrivate(functionSelector, newTimelockExpiration);
  }

  /**
   * @notice Internal function to expire or cancel a timelock so it is no longer
   * usable. Once it has been expired, the timelock in question will only be
   * reactivated if the timelock is reset, and this operation is only permitted
   * if the completion time is not shorter than the original completion time.
   * @param functionSelector The function that the timelock to expire is set on.
   * @param arguments The abi-encoded arguments of the timelocked function call
   * to be expired.
   */
  function _expireTimelock(
    bytes4 functionSelector, bytes memory arguments
  ) internal {
    // Get timelock ID using the supplied function arguments.
    bytes32 timelockID = keccak256(abi.encodePacked(arguments));

    // Get the current timelock, if one exists.
    Timelock storage timelock = _timelocks[functionSelector][timelockID];

    uint256 currentTimelock = uint256(timelock.complete);
    uint256 expiration = uint256(timelock.expires);

    // Ensure a timelock is currently set for the given function and arguments.
    require(currentTimelock != 0, "No timelock found for the given arguments.");

    // Ensure that the timelock has not already expired.
    require(expiration > block.timestamp, "Timelock has already expired.");

    // Mark the timelock as expired.
    timelock.expires = uint128(0);
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
   * @notice Internal view function to check if a timelock for the specified
   * function and arguments has completed.
   * @param functionSelector Function to be called.
   * @param arguments The abi-encoded arguments of the function to be called.
   * @return exists - a boolean indicating if the timelock exists
   * @return completed -  a boolean indicating if the timelock has completed
   * @return expired -  a boolean indicating if the timelock has expired
   * @return completionTime - time at which the timelock completed
   * @return expirationTime - time at which the timelock expired
   */
  function _getTimelock(
    bytes4 functionSelector, bytes memory arguments
  ) internal view returns (
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
    completed = exists && block.timestamp > completionTime;
    expired = exists && block.timestamp > expirationTime;
  }

  /**
   * @notice Internal view function to check the current minimum timelock
   * interval on a given function.
   * @param functionSelector Function to retrieve the timelock interval for.
   * @return defaultTimelockInterval - the current minimum timelock interval for the given function.
   */
  function _getDefaultTimelockInterval(
    bytes4 functionSelector
  ) internal view returns (uint256 defaultTimelockInterval) {
    defaultTimelockInterval = uint256(
      _timelockDefaults[functionSelector].interval
    );
  }

  /**
   * @notice Internal view function to check the current default timelock
   * expiration on a given function.
   * @param functionSelector Function to retrieve the timelock expiration for.
   * @return defaultTimelockExpiration - the current default timelock expiration for the given function.
   */
  function _getDefaultTimelockExpiration(
    bytes4 functionSelector
  ) internal view returns (uint256 defaultTimelockExpiration) {
    defaultTimelockExpiration = uint256(
      _timelockDefaults[functionSelector].expiration
    );
  }

  /**
   * @notice Private function to ensure that a timelock is complete or expired
   * and to clear the existing timelock if it is complete so it cannot later be
   * reused.
   * @param functionSelector Function to be called.
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
      currentTimelock != 0 && currentTimelock <= block.timestamp, "Timelock is incomplete."
    );

    // Ensure that the timelock has not expired.
    require(expiration > block.timestamp, "Timelock has expired.");

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
  constructor() {
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
      "TwoStepOwnable#transferOwnership: new potential owner is the zero address."
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
      "TwoStepOwnable#acceptOwnership: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    emit OwnershipTransferred(_owner, msg.sender);

    _owner = msg.sender;
  }
}


/**
 * @title DharmaAccountRecoveryManagerV2
 * @author 0age
 * @notice This contract is owned by an Account Recovery multisig and manages
 * resets to user signing keys when necessary. It implements a set of timelocked
 * functions, where the `setTimelock` function must first be called, with the
 * same arguments that the function will be supplied with. Then, a given time
 * interval must first fully transpire before the timelock functions can be
 * successfully called.
 *
 * The timelocked functions currently implemented include:
 *  recover(address wallet, address newUserSigningKey)
 *  disableAccountRecovery(address wallet)
 *  modifyTimelockInterval(bytes4 functionSelector, uint256 newTimelockInterval)
 *  modifyTimelockExpiration(
 *    bytes4 functionSelector, uint256 newTimelockExpiration
 *  )
 *
 * Note that special care should be taken to differentiate between lost keys and
 * compromised keys, and that the danger of a user being impersonated is
 * extremely high. Account recovery should progress to a system where the user
 * builds their preferred account recovery procedure into a "key ring" smart
 * contract at their signing address, reserving this "hard reset" for extremely
 * unusual circumstances and eventually sunsetting it entirely.
 *
 * V2 of the Account Recovery Manager builds on V1 by introducing the concept of
 * "roles" - these are dedicated accounts that can be modified by the owner, and
 * that can trigger specific functionality on the manager. These roles are:
 *  - operator: initiates timelocks for account recovery + disablement
 *  - recoverer: triggers account recovery once timelock is complete
 *  - disabler: triggers account recovery disablement once timelock is complete
 *  - canceller: cancels account recovery and recovery disablement timelocks
 *  - pauser: pauses any role (where only the owner is then able to unpause it)
 *
 * V2 also provides dedicated methods for cancelling timelocks related to
 * account recovery or the disablement of account recovery, as well as functions
 * for managing, pausing, and querying for the status of the various roles.
 */
contract DharmaAccountRecoveryManagerV2Polygon is
  DharmaAccountRecoveryManagerInterface,
  DharmaAccountRecoveryManagerV2Interface,
  TimelockerModifiersInterface,
  TwoStepOwnable,
  TimelockerV2 {

  // Maintain a role status mapping with assigned accounts and paused states.
  mapping(uint256 => RoleStatus) private _roles;

  // Maintain mapping of smart wallets that have opted out of account recovery.
  mapping(address => bool) private _accountRecoveryDisabled;

  /**
   * @notice In the constructor, set the initial owner to the transaction
   * submitter and initial minimum timelock interval and default timelock
   * expiration values.
   */
  constructor() {
    // Set initial minimum timelock interval values.
    _setInitialTimelockInterval(this.modifyTimelockInterval.selector, 2 weeks);
    _setInitialTimelockInterval(
      this.modifyTimelockExpiration.selector, 2 weeks
    );
    _setInitialTimelockInterval(this.recover.selector, 2 days);
    _setInitialTimelockInterval(this.disableAccountRecovery.selector, 3 days);

    // Set initial default timelock expiration values.
    _setInitialTimelockExpiration(this.modifyTimelockInterval.selector, 7 days);
    _setInitialTimelockExpiration(
      this.modifyTimelockExpiration.selector, 7 days
    );
    _setInitialTimelockExpiration(this.recover.selector, 3 days);
    _setInitialTimelockExpiration(this.disableAccountRecovery.selector, 3 days);
  }

  /**
   * @notice Initiates a timelocked account recovery process for a smart wallet
   * user signing key. Only the owner or the designated operator may call this
   * function. Once the timelock period is complete (and before it has expired)
   * the owner or the designated recoverer may call `recover` to complete the
   * process and reset the user's signing key.
   * @param smartWallet The smart wallet address.
   * @param userSigningKey The new user signing key.
   * @param extraTime Additional time in seconds to add to the timelock.
   */
  function initiateAccountRecovery(
    address smartWallet, address userSigningKey, uint256 extraTime
  ) external override onlyOwnerOr(Role.OPERATOR) {
    require(smartWallet != address(0), "No smart wallet address provided.");
    require(userSigningKey != address(0), "No new user signing key provided.");

    // Set the timelock and emit a `TimelockInitiated` event.
    _setTimelock(
      this.recover.selector, abi.encode(smartWallet, userSigningKey), extraTime
    );
  }

  /**
   * @notice Timelocked function to set a new user signing key on a smart
   * wallet. Only the owner or the designated recoverer may call this function.
   * @param smartWallet Address of the smart wallet to recover a key on.
   * @param newUserSigningKey Address of the new signing key for the user.
   */
  function recover(
    address smartWallet, address newUserSigningKey
  ) external override onlyOwnerOr(Role.RECOVERER) {
    require(smartWallet != address(0), "No smart wallet address provided.");
    require(
      newUserSigningKey != address(0),
      "No new user signing key provided."
    );

    // Ensure that the wallet in question has not opted out of account recovery.
    require(
      !_accountRecoveryDisabled[smartWallet],
      "This wallet has elected to opt out of account recovery functionality."
    );

    // Ensure that the timelock has been set and is completed.
    _enforceTimelock(abi.encode(smartWallet, newUserSigningKey));

    // Declare the proper interface for the smart wallet in question.
    DharmaSmartWalletRecoveryInterface walletInterface;

    // Attempt to get current signing key - a failure should not block recovery.
    address oldUserSigningKey;
    (bool ok, bytes memory data) = smartWallet.call{gas: gasleft() / 2}(
      abi.encodeWithSelector(walletInterface.getUserSigningKey.selector)
    );
    if (ok && data.length == 32) {
      oldUserSigningKey = abi.decode(data, (address));
    }

    // Call the specified smart wallet and supply the new user signing key.
    DharmaSmartWalletRecoveryInterface(smartWallet).recover(newUserSigningKey);

    // Emit an event to signify that the wallet in question was recovered.
    emit Recovery(smartWallet, oldUserSigningKey, newUserSigningKey);
  }

  /**
   * @notice Initiates a timelocked account recovery disablement process for a
   * smart wallet. Only the owner or the designated operator may call this
   * function. Once the timelock period is complete (and before it has expired)
   * the owner or the designated disabler may call `disableAccountRecovery` to
   * complete the process and opt a smart wallet out of account recovery. Once
   * account recovery has been disabled, it cannot be reenabled - the process is
   * irreversible.
   * @param smartWallet The smart wallet address.
   * @param extraTime Additional time in seconds to add to the timelock.
   */
  function initiateAccountRecoveryDisablement(
    address smartWallet, uint256 extraTime
  ) external override onlyOwnerOr(Role.OPERATOR) {
    require(smartWallet != address(0), "No smart wallet address provided.");

    // Set the timelock and emit a `TimelockInitiated` event.
    _setTimelock(
      this.disableAccountRecovery.selector, abi.encode(smartWallet), extraTime
    );
  }

  /**
   * @notice Timelocked function to opt a given wallet out of account recovery.
   * This action cannot be undone - any future account recovery would require an
   * upgrade to the smart wallet implementation itself and is not likely to be
   * supported. Only the owner or the designated disabler may call this
   * function.
   * @param smartWallet Address of the smart wallet to disable account recovery
   * for.
   */
  function disableAccountRecovery(
    address smartWallet
  ) external override onlyOwnerOr(Role.DISABLER) {
    require(smartWallet != address(0), "No smart wallet address provided.");

    // Ensure that the timelock has been set and is completed.
    _enforceTimelock(abi.encode(smartWallet));

    // Register the specified wallet as having opted out of account recovery.
    _accountRecoveryDisabled[smartWallet] = true;

    // Emit an event to signify the wallet in question is no longer recoverable.
    emit RecoveryDisabled(smartWallet);
  }

  /**
   * @notice Cancel a pending timelock for setting a new user signing key on a
   * smart wallet. Only the owner or the designated canceller may call this
   * function.
   * @param smartWallet Address of the smart wallet to cancel the recovery on.
   * @param userSigningKey Address of the signing key supplied for the user.
   */
  function cancelAccountRecovery(
    address smartWallet, address userSigningKey
  ) external override onlyOwnerOr(Role.CANCELLER) {
    require(smartWallet != address(0), "No smart wallet address provided.");
    require(userSigningKey != address(0), "No user signing key provided.");

    // Expire the timelock for the account recovery in question if one exists.
    _expireTimelock(
      this.recover.selector, abi.encode(smartWallet, userSigningKey)
    );

    // Emit an event to signify that the recovery was cancelled.
    emit RecoveryCancelled(smartWallet, userSigningKey);
  }

  /**
   * @notice Cancel a pending timelock for disabling account recovery for a
   * smart wallet. Only the owner or the designated canceller may call this
   * function.
   * @param smartWallet Address of the smart wallet to cancel the recovery
   * disablement on.
   */
  function cancelAccountRecoveryDisablement(
    address smartWallet
  ) external override onlyOwnerOr(Role.CANCELLER) {
    require(smartWallet != address(0), "No smart wallet address provided.");

    // Expire account recovery disablement timelock in question if one exists.
    _expireTimelock(
      this.disableAccountRecovery.selector, abi.encode(smartWallet)
    );

    // Emit an event to signify that the recovery disablement was cancelled.
    emit RecoveryDisablementCancelled(smartWallet);
  }

  /**
   * @notice Pause a currently unpaused role and emit a `RolePaused` event. Only
   * the owner or the designated pauser may call this function. Also, bear in
   * mind that only the owner may unpause a role once paused.
   * @param role The role to pause. Permitted roles are operator (0),
   * recoverer (1), canceller (2), disabler (3), and pauser (4).
   */
  function pause(Role role) external override onlyOwnerOr(Role.PAUSER) {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];
    require(!storedRoleStatus.paused, "Role in question is already paused.");
    storedRoleStatus.paused = true;
    emit RolePaused(role);
  }

  /**
   * @notice Unause a currently paused role and emit a `RoleUnpaused` event.
   * Only the owner may call this function.
   * @param role The role to pause. Permitted roles are operator (0),
   * recoverer (1), canceller (2), disabler (3), and pauser (4).
   */
  function unpause(Role role) external override onlyOwner {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];
    require(storedRoleStatus.paused, "Role in question is already unpaused.");
    storedRoleStatus.paused = false;
    emit RoleUnpaused(role);
  }

  /**
   * @notice Sets the timelock for a new timelock interval for a given function
   * selector. Only the owner may call this function.
   * @param functionSelector The selector of the function to set the timelock
   * interval for.
   * @param newTimelockInterval The new timelock interval to set for the given
   * function selector.
   * @param extraTime Additional time in seconds to add to the timelock.
   */
  function initiateModifyTimelockInterval(
    bytes4 functionSelector, uint256 newTimelockInterval, uint256 extraTime
  ) external override onlyOwner {
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
   * @param functionSelector The selector of the function to set the timelock
   * interval for.
   * @param newTimelockInterval The new timelock interval to set for the given
   * function selector.
   */
  function modifyTimelockInterval(
    bytes4 functionSelector, uint256 newTimelockInterval
  ) external override onlyOwner {
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
   * @param functionSelector The selector of the function to set the timelock
   * expiration for.
   * @param newTimelockExpiration The new timelock expiration to set for the
   * given function selector.
   * @param extraTime Additional time in seconds to add to the timelock.
   */
  function initiateModifyTimelockExpiration(
    bytes4 functionSelector, uint256 newTimelockExpiration, uint256 extraTime
  ) external override onlyOwner {
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
   * @param functionSelector The selector of the function to set the timelock
   * expiration for.
   * @param newTimelockExpiration The new timelock expiration to set for the
   * given function selector.
   */
  function modifyTimelockExpiration(
    bytes4 functionSelector, uint256 newTimelockExpiration
  ) external override onlyOwner {
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
   * @notice Set a new account on a given role and emit a `RoleModified` event
   * if the role holder has changed. Only the owner may call this function.
   * @param role The role that the account will be set for. Permitted roles are
   * operator (0), recoverer (1), canceller (2), disabler (3), and pauser (4).
   * @param account The account to set as the designated role bearer.
   */
  function setRole(Role role, address account) external override onlyOwner {
    require(account != address(0), "Must supply an account.");
    _setRole(role, account);
  }

  /**
   * @notice Remove any current role bearer for a given role and emit a
   * `RoleModified` event if a role holder was previously set. Only the owner
   * may call this function.
   * @param role The role that the account will be removed from. Permitted roles
   * are operator (0), recoverer (1), canceller (2), disabler (3), and
   * pauser (4).
   */
  function removeRole(Role role) external override onlyOwner {
    _setRole(role, address(0));
  }

  /**
   * @notice External view function to check whether a given smart wallet has
   * disabled account recovery by opting out.
   * @param smartWallet Address of the smart wallet to check.
   * @return hasDisabledAccountRecovery - a boolean indicating if account recovery has been disabled for the
   * wallet in question.
   */
  function accountRecoveryDisabled(
    address smartWallet
  ) external view override returns (bool hasDisabledAccountRecovery) {
    // Determine if the wallet in question has opted out of account recovery.
    hasDisabledAccountRecovery = _accountRecoveryDisabled[smartWallet];
  }

  /**
   * @notice External view function to check whether or not the functionality
   * associated with a given role is currently paused or not. The owner or the
   * pauser may pause any given role (including the pauser itself), but only the
   * owner may unpause functionality. Additionally, the owner may call paused
   * functions directly.
   * @param role The role to check the pause status on. Permitted roles are
   * operator (0), recoverer (1), canceller (2), disabler (3), and pauser (4).
   * @return paused - a boolean to indicate if the functionality associated with the role
   * in question is currently paused.
   */
  function isPaused(Role role) external view override returns (bool paused) {
    paused = _isPaused(role);
  }

  /**
   * @notice External view function to check whether the caller is the current
   * role holder.
   * @param role The role to check for. Permitted roles are operator (0),
   * recoverer (1), canceller (2), disabler (3), and pauser (4).
   * @return hasRole - a boolean indicating if the caller has the specified role.
   */
  function isRole(Role role) external view override returns (bool hasRole) {
    hasRole = _isRole(role);
  }

  /**
   * @notice External view function to check the account currently holding the
   * operator role. The operator can initiate timelocks for account recovery and
   * account recovery disablement.
   * @return operator - the address of the current operator, or the null address if none is
   * set.
   */
  function getOperator() external view override returns (address operator) {
    operator = _roles[uint256(Role.OPERATOR)].account;
  }

  /**
   * @notice External view function to check the account currently holding the
   * recoverer role. The recoverer can trigger smart wallet account recovery in
   * the event that a timelock has been initiated and is complete and not yet
   * expired.
   * @return recoverer - the address of the current recoverer, or the null address if none
   * is set.
   */
  function getRecoverer() external view override returns (address recoverer) {
    recoverer = _roles[uint256(Role.RECOVERER)].account;
  }

  /**
   * @notice External view function to check the account currently holding the
   * canceller role. The canceller can expire a timelock related to account
   * recovery or account recovery disablement prior to its execution.
   * @return canceller - the address of the current canceller, or the null address if none
   * is set.
   */
  function getCanceller() external view override returns (address canceller) {
    canceller = _roles[uint256(Role.CANCELLER)].account;
  }

  /**
   * @notice External view function to check the account currently holding the
   * disabler role. The disabler can trigger permanent smart wallet account
   * recovery disablement in the event that a timelock has been initiated and is
   * complete and not yet expired.
   * @return disabler - the address of the current disabler, or the null address if none is
   * set.
   */
  function getDisabler() external view override returns (address disabler) {
    disabler = _roles[uint256(Role.DISABLER)].account;
  }

  /**
   * @notice External view function to check the account currently holding the
   * pauser role. The pauser can pause any role from taking its standard action,
   * though the owner will still be able to call the associated function in the
   * interim and is the only entity able to unpause the given role once paused.
   * @return pauser - the address of the current pauser, or the null address if none is
   * set.
   */
  function getPauser() external view override returns (address pauser) {
    pauser = _roles[uint256(Role.PAUSER)].account;
  }

  /**
   * @notice Internal function to set a new account on a given role and emit a
   * `RoleModified` event if the role holder has changed.
   * @param role The role that the account will be set for. Permitted roles are
   * operator (0), recoverer (1), canceller (2), disabler (3), and pauser (4).
   * @param account The account to set as the designated role bearer.
   */
  function _setRole(Role role, address account) internal {
    RoleStatus storage storedRoleStatus = _roles[uint256(role)];

    if (account != storedRoleStatus.account) {
      storedRoleStatus.account = account;
      emit RoleModified(role, account);
    }
  }

  /**
   * @notice Internal view function to check whether the caller is the current
   * role holder.
   * @param role The role to check for. Permitted roles are operator (0),
   * recoverer (1), canceller (2), disabler (3), and pauser (4).
   * @return hasRole - a boolean indicating if the caller has the specified role.
   */
  function _isRole(Role role) internal view returns (bool hasRole) {
    hasRole = msg.sender == _roles[uint256(role)].account;
  }

  /**
   * @notice Internal view function to check whether the given role is paused or
   * not.
   * @param role The role to check for. Permitted roles are operator (0),
   * recoverer (1), canceller (2), disabler (3), and pauser (4).
   * @return paused - a boolean indicating if the specified role is paused or not.
   */
  function _isPaused(Role role) internal view returns (bool paused) {
    paused = _roles[uint256(role)].paused;
  }

  /**
   * @notice Modifier that throws if called by any account other than the owner
   * or the supplied role, or if the caller is not the owner and the role in
   * question is paused.
   * @param role The role to require unless the caller is the owner. Permitted
   * roles are operator (0), recoverer (1), canceller (2), disabler (3), and
   * pauser (4).
   */
  modifier onlyOwnerOr(Role role) {
    if (!isOwner()) {
      require(_isRole(role), "Caller does not have a required role.");
      require(!_isPaused(role), "Role in question is currently paused.");
    }
    _;
  }
}