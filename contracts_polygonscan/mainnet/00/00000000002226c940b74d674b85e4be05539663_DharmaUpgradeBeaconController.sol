/**
 *Submitted for verification at polygonscan.com on 2021-08-24
*/

pragma solidity 0.5.11; // optimization runs: 200, evm version: petersburg


interface DharmaUpgradeBeaconEnvoyInterface {
  function getImplementation(address beacon) external view returns (address);
}


/**
 * @title DharmaUpgradeBeaconController
 * @author 0age
 * @notice This contract has exclusive control over modifications to the stored
 * implementation address on controlled "upgrade beacon" contracts. It is an
 * owned contract, where ownership can be transferred to another contract - that
 * way, the upgrade mechanism itself can be "upgraded". Apart from the ownable
 * methods, this contract is deliberately simple and only has one non-view
 * method - `upgrade`. Timelocks or other upgrade conditions will be managed by
 * the owner of this contract.
 */
contract DharmaUpgradeBeaconController {
  // Fire an event whenever ownership of this contract changes.
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  // Fire an event any time a new implementation is set on an upgrade beacon.
  event Upgraded(
    address indexed upgradeBeacon,
    address oldImplementation,
    bytes32 oldImplementationCodeHash,
    address newImplementation,
    bytes32 newImplementationCodeHash
  );

  // Store address of owner - ownership modeled after OpenZeppelin's `Ownable`.
  address private _owner;

  // Store a mapping of the implementation code hash at the time of the last
  // upgrade for each beacon. This can be used by calling contracts to verify
  // that the implementation has not been altered since it was initially set.
  mapping(address => bytes32) private _codeHashAtLastUpgrade;

  // The Upgrade Beacon Envoy checks a beacon's implementation, used for events. 
  DharmaUpgradeBeaconEnvoyInterface private constant _UPGRADE_BEACON_ENVOY = (
    DharmaUpgradeBeaconEnvoyInterface(
      0x000000000067503c398F4c9652530DBC4eA95C02
    )
  );

  /**
   * @notice In the constructor, set the transaction submitter as the initial
   * owner of this contract and verify the runtime code of the referenced
   * upgrade beacon envoy via `EXTCODEHASH`.
   */
  constructor() public {
    // Set the transaction submitter as the initial owner of this contract.
    _owner = tx.origin;
    emit OwnershipTransferred(address(0), tx.origin);
    
    // Ensure the upgrade beacon envoy has the expected runtime code hash.
    address envoy = address(_UPGRADE_BEACON_ENVOY);
    bytes32 envoyCodeHash;
    assembly { envoyCodeHash := extcodehash(envoy)}
    require(
      envoyCodeHash == bytes32(
        0x7332d06692fd32b21bdd8b8b7a0a3f0de5cf549668cbc4498fc6cfaa453f1176
      ),
      "Upgrade Beacon Envoy runtime code is incorrect."
    );
  }

  /**
   * @notice Set a new implementation address on an upgrade beacon contract.
   * This function may only be called by the owner of this contract.
   * @param beacon Address of upgrade beacon to set the new implementation on.
   * @param implementation The address of the new implementation.
   */
  function upgrade(address beacon, address implementation) external onlyOwner {
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
   * @notice Transfers ownership of the contract to a new account (`newOwner`).
   * This function may only be called by the owner of this contract.
   * @param newOwner Address of the new owner to set.
   */
  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

  /**
   * @notice Transfers ownership of the contract to the null account, thereby
   * preventing it from being used to perform upgrades in the future. This
   * function may only be called by the owner of this contract.
   */
  function renounceOwnership() external onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
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
  ) external view returns (address implementation) {
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
  ) external view returns (bytes32 codeHashAtLastUpgrade) {
    // Return the code hash that was set when the given beacon was last updated.
    codeHashAtLastUpgrade = _codeHashAtLastUpgrade[beacon];
  }

  /**
   * @notice Returns the address of the current owner.
   * @return The address of the owner.
   */
  function owner() external view returns (address) {
    return _owner;
  }

  /**
   * @notice Returns true if the caller is the current owner.
   * @return True if the caller is the current owner, else false.
   */
  function isOwner() external view returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @notice Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == _owner, "Ownable: caller is not the owner");
    _;
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
    bytes32 oldImplementationCodeHash;
    assembly { oldImplementationCodeHash := extcodehash(oldImplementation) }

    // Call into beacon and supply address of new implementation to update it.
    (bool success,) = beacon.call(abi.encode(implementation));

    // Revert with message on failure (i.e. if the beacon is somehow incorrect).
    if (!success) {
      assembly {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }

    // Get address of the new implementation that was set on the upgrade beacon.
    address newImplementation = _UPGRADE_BEACON_ENVOY.getImplementation(beacon);

    // Get the runtime code hash for the new implementation.
    bytes32 newImplementationCodeHash;
    assembly { newImplementationCodeHash := extcodehash(newImplementation) }

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