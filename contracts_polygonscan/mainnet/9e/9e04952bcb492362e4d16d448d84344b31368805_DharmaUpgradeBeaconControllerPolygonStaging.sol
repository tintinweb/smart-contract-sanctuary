/**
 *Submitted for verification at polygonscan.com on 2021-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4; // optimization runs: 200

interface DharmaUpgradeBeaconControllerInterface {
  function upgrade(address beacon, address implementation) external;
  function getImplementation(address beacon) external view returns (address implementation);
  function getCodeHashAtLastUpgrade(address beacon) external view returns (bytes32 codeHashAtLastUpgrade);
}

interface DharmaUpgradeBeaconEnvoyInterface {
  function getImplementation(address beacon) external view returns (address);
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
 * @title DharmaUpgradeBeaconEnvoy
 * @author 0age
 * @notice This contract calls into an upgrade beacon on behalf of a controller
 * to retrieve the implementation address, since a call from the controller will
 * instead trigger an update of the upgrade beacon's implementation.
 */
contract DharmaUpgradeBeaconEnvoy is DharmaUpgradeBeaconEnvoyInterface {
  /**
   * @notice View function to check the existing implementation on a given
   * beacon. This is accomplished via a staticcall to the beacon with no data,
   * and the beacon will return an abi-encoded implementation address.
   * @param beacon Address of the upgrade beacon to check for an implementation.
   * @return implementation Address of the implementation.
   */
  function getImplementation(
    address beacon
  ) external view override returns (address implementation) {
    // Perform the staticcall into the supplied upgrade beacon.
    (bool ok, bytes memory returnData) = beacon.staticcall("");

    // Revert if underlying staticcall reverts, passing along revert message.
    if (!ok) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // Ensure that the data returned from the beacon is the correct length.
    require(
      returnData.length == 32,
      "DharmaUpgradeBeaconEnvoy#getImplementation: Return data must be exactly 32 bytes."
    );

    // Decode the address from the returned data and return it to the caller.
    implementation = abi.decode(returnData, (address));
  }
}

/**
 * @title DharmaUpgradeBeaconControllerPolygonStaging
 * @author 0age
 * @notice This contract has exclusive control over modifications to the stored
 * implementation address on controlled "upgrade beacon" contracts. It is an
 * owned contract, where ownership can be transferred to another contract - that
 * way, the upgrade mechanism itself can be "upgraded". Apart from the ownable
 * methods, this contract is deliberately simple and only has one non-view
 * method - `upgrade`. Timelocks or other upgrade conditions will be managed by
 * the owner of this contract.
 */
contract DharmaUpgradeBeaconControllerPolygonStaging is TwoStepOwnable, DharmaUpgradeBeaconControllerInterface {
  // Fire an event any time a new implementation is set on an upgrade beacon.
  event Upgraded(
    address indexed upgradeBeacon,
    address oldImplementation,
    bytes32 oldImplementationCodeHash,
    address newImplementation,
    bytes32 newImplementationCodeHash
  );

  // Store a mapping of the implementation code hash at the time of the last
  // upgrade for each beacon. This can be used by calling contracts to verify
  // that the implementation has not been altered since it was initially set.
  mapping(address => bytes32) private _codeHashAtLastUpgrade;

  // The Upgrade Beacon Envoy is used to check the implementation of a beacon.
  DharmaUpgradeBeaconEnvoyInterface private immutable _UPGRADE_BEACON_ENVOY;

  /**
   * @notice In the constructor, set the transaction submitter as the initial
   * owner of this contract and verify the runtime code of the referenced
   * upgrade beacon envoy.
   * @param envoy The address of the envoy.
   */
  constructor(address envoy) public {
    require(
      envoy != address(0),
      "DharmaUpgradeBeaconController#constructor: No envoy address supplied."
    );

    // Ensure the upgrade beacon envoy has the expected runtime code.
    bytes32 envoyCodeHash = envoy.codehash;
    require(
      envoyCodeHash == keccak256(type(DharmaUpgradeBeaconEnvoy).runtimeCode),
      "DharmaUpgradeBeaconController#constructor: envoy runtime code is incorrect."
    );

    _UPGRADE_BEACON_ENVOY = DharmaUpgradeBeaconEnvoyInterface(envoy);
  }

  /**
   * @notice Set a new implementation address on an upgrade beacon contract.
   * This function may only be called by the owner of this contract.
   * @param beacon Address of upgrade beacon to set the new implementation on.
   * @param implementation The address of the new implementation.
   */
  function upgrade(address beacon, address implementation) external override onlyOwner {
    // Ensure that the implementaton contract is not the null address.
    require(implementation != address(0), "Must specify an implementation.");

    // Ensure that the implementation contract has code via extcodesize.
    uint256 implementationSize;
    assembly { implementationSize := extcodesize(implementation) }
    require(implementationSize > 0, "Implementation must have contract code.");

    // Ensure that the beacon contract is not the null address.
    require(beacon != address(0), "Must specify an upgrade beacon.");

    // Ensure that the upgrade beacon contract has code via extcodesize.
    uint256 beaconSize;
    assembly { beaconSize := extcodesize(beacon) }
    require(beaconSize > 0, "Upgrade beacon must have contract code.");

    // Update the upgrade beacon with the new implementation address.
    _update(beacon, implementation);
  }

  /**
   * @notice View function to check the existing implementation on a given
   * beacon. This is accomplished via a staticcall to the upgrade beacon envoy,
   * which in turn performs a staticcall into the given beacon and passes along
   * the returned implementation address.
   * @param beacon Address of the upgrade beacon to check for an implementation.
   * @return implementation Address of the implementation.
   */
  function getImplementation(
    address beacon
  ) external view override returns (address implementation) {
    // Perform a staticcall into envoy, supplying the beacon as the argument.
    implementation = _UPGRADE_BEACON_ENVOY.getImplementation(beacon);
  }

  /**
   * @notice View function to check the runtime code hash of a beacon's
   * implementation contract at the time it was last updated. This can be used
   * by other callers to verify that the implementation has not been altered
   * since it was last updated by comparing this value to the current runtime
   * code hash of the beacon's implementation contract. Note that this function
   * will return `bytes32(0)` in the event the supplied beacon has not yet been
   * updated.
   * @param beacon Address of the upgrade beacon to check for a code hash.
   * @return codeHashAtLastUpgrade Runtime code hash of the implementation
   * contract when the beacon was last updated.
   */
  function getCodeHashAtLastUpgrade(
    address beacon
  ) external view override returns (bytes32 codeHashAtLastUpgrade) {
    // Return the code hash that was set when the given beacon was last updated.
    codeHashAtLastUpgrade = _codeHashAtLastUpgrade[beacon];
  }

  /**
   * @notice Private function to perform an update to a given upgrade beacon and
   * determine the runtime code hash of both the old and the new implementation.
   * The latest code hash for the new implementation of the given beacon will be
   * updated, and an event containing the beacon, the old and new implementation
   * addresses, and the old and new implementation runtime code hashes will be
   * emitted.
   * @param beacon Address of upgrade beacon to set the new implementation on.
   * @param implementation The address of the new implementation.
   */
  function _update(address beacon, address implementation) private {
    // Get the address of the current implementation set on the upgrade beacon.
    address oldImplementation = _UPGRADE_BEACON_ENVOY.getImplementation(beacon);

    // Get the runtime code hash for the current implementation.
    bytes32 oldImplementationCodeHash = oldImplementation.codehash;

    // Call into beacon and supply address of new implementation to update it.
    (bool success,) = beacon.call(abi.encode(implementation));

    // Revert with message on failure (i.e. if the beacon is somehow incorrect).
    if (!success) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // Get address of the new implementation that was set on the upgrade beacon.
    address newImplementation = _UPGRADE_BEACON_ENVOY.getImplementation(beacon);

    // Get the runtime code hash for the new implementation.
    bytes32 newImplementationCodeHash = newImplementation.codehash;

    // Set runtime code hash of the new implementation for the given beacon.
    _codeHashAtLastUpgrade[beacon] = newImplementationCodeHash;

    // Emit an event to signal that the upgrade beacon was updated.
    emit Upgraded(
      beacon,
      oldImplementation,
      oldImplementationCodeHash,
      newImplementation,
      newImplementationCodeHash
    );
  }
}