/**
 *Submitted for verification at polygonscan.com on 2021-11-17
*/

pragma solidity 0.5.11; // optimization runs: 200, evm version: petersburg


/**
 * @title AdharmaKeyRingImplementation
 * @author 0age
 * @notice The Adharma Key Ring is an emergency implementation that can be
 * immediately upgraded to by the Upgrade Beacon Controller Manager in the event
 * of a critical-severity exploit, or after a 90-day period of inactivity by
 * Dharma. It gives the user direct, sole custody and control over issuing calls
 * from their keyring, using any of their Admin or Dual keys, until the Upgrade
 * Beacon Controller Manager issues another upgrade to the implementation
 * contract.
 */
contract AdharmaKeyRingImplementation {
  event KeyModified(address indexed key, bool standard, bool admin);

  enum KeyType {
    None,
    Standard,
    Admin,
    Dual
  }

  struct AdditionalKeyCount {
    uint128 standard;
    uint128 admin;
  }

  struct AdditionalThreshold {
    uint128 standard;
    uint128 admin;
  }

  // WARNING: DO NOT REMOVE OR REORDER STORAGE WHEN WRITING NEW IMPLEMENTATIONS!

  // Track all keys as an address (as uint160) => key type mapping in slot zero.
  mapping (uint160 => KeyType) private _keys;

  // Track the nonce in slot 1 so that actions cannot be replayed. Note that
  // proper nonce management must be managed by the implementing contract when
  // using `isValidSignature`, as it is a static method and cannot change state.
  uint256 private _nonce;

  // Track the total number of standard and admin keys in storage slot 2.
  AdditionalKeyCount private _additionalKeyCounts;

  // Track the required threshold standard and admin actions in storage slot 3.
  AdditionalThreshold private _additionalThresholds;

  // END STORAGE DECLARATIONS - DO NOT REMOVE OR REORDER STORAGE ABOVE HERE!

  // Keep the initializer function on the contract in case a keyring has not yet
  // been deployed but an account it controls still contains user funds.
  function initialize(
    uint128 adminThreshold,
    uint128 executorThreshold,
    address[] calldata keys,
    uint8[] calldata keyTypes // 1: standard, 2: admin, 3: dual
  ) external {
    // Ensure that this function is only callable during contract construction.
    assembly { if extcodesize(address) { revert(0, 0) } }

    uint128 adminKeys;
    uint128 executorKeys;

    require(keys.length > 0, "Must supply at least one key.");

    require(adminThreshold > 0, "Admin threshold cannot be zero.");

    require(executorThreshold > 0, "Executor threshold cannot be zero.");

    require(
      keys.length == keyTypes.length,
      "Length of keys array and keyTypes arrays must be the same."
    );

    for (uint256 i = 0; i < keys.length; i++) {
      uint160 key = uint160(keys[i]);

      require(key != uint160(0), "Cannot supply the null address as a key.");

      require(_keys[key] == KeyType.None, "Cannot supply duplicate keys.");

      KeyType keyType = KeyType(keyTypes[i]);

      _keys[key] = keyType;

      bool isStandard = (keyType == KeyType.Standard || keyType == KeyType.Dual);
      bool isAdmin = (keyType == KeyType.Admin || keyType == KeyType.Dual);

      emit KeyModified(keys[i], isStandard, isAdmin);

      if (isStandard) {
        executorKeys++;
      }

      if (isAdmin) {
        adminKeys++;
      }
    }

    require(adminKeys > 0, "Must supply at least one admin key.");

    require(executorKeys > 0, "Must supply at least one executor key.");

    require(
      adminKeys >= adminThreshold,
      "Admin threshold cannot be greater than the total supplied admin keys."
    );

    if (adminKeys > 1 || executorKeys > 1) {
      _additionalKeyCounts = AdditionalKeyCount({
        standard: executorKeys - 1,
        admin: adminKeys - 1
      });
    }

    if (adminThreshold > 1 || executorThreshold > 1) {
      _additionalThresholds = AdditionalThreshold({
        standard: executorThreshold - 1,
        admin: adminThreshold - 1
      });
    }
  }

  // Admin or Dual key holders have authority to issue actions from the keyring.
  function takeAction(
    address payable to, uint256 value, bytes calldata data, bytes calldata
  ) external returns (bool ok, bytes memory returnData) {
    require(
      _keys[uint160(msg.sender)] == KeyType.Admin ||
      _keys[uint160(msg.sender)] == KeyType.Dual,
      "Only Admin or Dual key holders can call this function."
    );

    (ok, returnData) = to.call.value(value)(data);
  }
}