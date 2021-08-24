/**
 *Submitted for verification at polygonscan.com on 2021-08-24
*/

pragma solidity 0.5.11; // optimization runs: 200, evm version: petersburg


interface DharmaKeyRingImplementationV0Interface {
  event KeyModified(address indexed key, bool standard, bool admin);

  enum KeyType {
    None,
    Standard,
    Admin,
    Dual
  }

  enum AdminActionType {
    AddStandardKey,
    RemoveStandardKey,
    SetStandardThreshold,
    AddAdminKey,
    RemoveAdminKey,
    SetAdminThreshold,
    AddDualKey,
    RemoveDualKey,
    SetDualThreshold
  }

  struct AdditionalKeyCount {
    uint128 standard;
    uint128 admin;
  }

  function takeAdminAction(
    AdminActionType adminActionType, uint160 argument, bytes calldata signatures
  ) external;

  function getAdminActionID(
    AdminActionType adminActionType, uint160 argument, uint256 nonce
  ) external view returns (bytes32 adminActionID);

  function getNextAdminActionID(
    AdminActionType adminActionType, uint160 argument
  ) external view returns (bytes32 adminActionID);

  function getKeyCount() external view returns (
    uint256 standardKeyCount, uint256 adminKeyCount
  );

  function getKeyType(
    address key
  ) external view returns (bool standard, bool admin);

  function getNonce() external returns (uint256 nonce);

  function getVersion() external pure returns (uint256 version);
}


interface ERC1271 {
  /**
   * @dev Should return whether the signature provided is valid for the provided data
   * @param data Arbitrary length data signed on the behalf of address(this)
   * @param signature Signature byte array associated with data
   *
   * MUST return the bytes4 magic value 0x20c13b0b when function passes.
   * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
   * MUST allow external calls
   */ 
  function isValidSignature(
    bytes calldata data, 
    bytes calldata signature
  ) external view returns (bytes4 magicValue);
}


library ECDSA {
  function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
    if (signature.length != 65) {
      return (address(0));
    }

    bytes32 r;
    bytes32 s;
    uint8 v;

    assembly {
      r := mload(add(signature, 0x20))
      s := mload(add(signature, 0x40))
      v := byte(0, mload(add(signature, 0x60)))
    }

    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      return address(0);
    }

    if (v != 27 && v != 28) {
      return address(0);
    }

    return ecrecover(hash, v, r, s);
  }

  function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }
}


/**
 * @title DharmaKeyRingImplementationV1Polygon
 * @author 0age
 * @notice The Dharma Key Ring is a smart contract that implements ERC-1271 and
 * can be used in place of an externally-owned account for the user signing key
 * on the Dharma Smart Wallet to support multiple user signing keys. For this V1
 * implementation, new Dual keys (standard + admin) can be added, but cannot be
 * removed, and the action threshold is fixed at one. Upgrades are managed by an
 * upgrade beacon, similar to the one utilized by the Dharma Smart Wallet. Note
 * that this implementation only implements the minimum feature set required to
 * support multiple user signing keys on the current Dharma Smart Wallet, and
 * that it will likely be replaced with a new, more full-featured implementation
 * relatively soon. V1 differs from V0 in that it requires that an adminActionID
 * must be prefixed (according to EIP-191 0x45) and hashed in order to construct
 * a valid signature (note that the message hash given to `isValidSignature` is
 * assumed to have already been appropriately constructed to fit the caller's
 * requirements and so does not apply an additional prefix).
 */
contract DharmaKeyRingImplementationV1Polygon is
  DharmaKeyRingImplementationV0Interface,
  ERC1271 {
  using ECDSA for bytes32;
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
  // AdditionalThreshold private _additionalThresholds;

  // END STORAGE DECLARATIONS - DO NOT REMOVE OR REORDER STORAGE ABOVE HERE!

  // The key ring version will be used when constructing valid signatures.
  uint256 internal constant _DHARMA_KEY_RING_VERSION = 1;

  // ERC-1271 must return this magic value when `isValidSignature` is called.
  bytes4 internal constant _ERC_1271_MAGIC_VALUE = bytes4(0x20c13b0b);

  /**
   * @notice In initializer, set up an initial user signing key. For V1, the
   * adminThreshold and executorThreshold arguments must both be equal to 1 and
   * exactly one key with a key type of 3 (Dual key) must be supplied. Note that
   * this initializer is only callable while the key ring instance is still in
   * the contract creation phase.
   * @param adminThreshold uint128 Must be equal to 1 in V1.
   * @param executorThreshold uint128 Must be equal to 1 in V1.
   * @param keys address[] The initial user signing key for the key ring. Must
   * have exactly one non-null key in V1.
   * @param keyTypes uint8[] Must be equal to [3].
   */
  function initialize(
    uint128 adminThreshold,
    uint128 executorThreshold,
    address[] calldata keys,
    uint8[] calldata keyTypes // must all be 3 (Dual) for V1
  ) external {
    // Ensure that this function is only callable during contract construction.
    assembly { if extcodesize(address) { revert(0, 0) } }

    // V1 only allows setting a singly Dual key with thresholds both set to 1.
    require(keys.length == 1, "Must supply exactly one key in V1.");

    require(keys[0] != address(0), "Cannot supply the null address as a key.");

    require(
      keyTypes.length == 1 && keyTypes[0] == uint8(3),
      "Must supply exactly one Dual keyType (3) in V1."
    );

    require(adminThreshold == 1, "Admin threshold must be exactly one in V1.");

    require(
      executorThreshold == 1, "Executor threshold must be exactly one in V1."
    );

    // Set the key and emit a corresponding event.
    _keys[uint160(keys[0])] = KeyType.Dual;
    emit KeyModified(keys[0], true, true);

    // Note: skip additional key counts + thresholds setup in V1 (only one key).
  }

  /**
   * @notice Supply a signature from one of the existing keys on the keyring in
   * order to add a new key.
   * @param adminActionType uint8 Must be equal to 6 in V1.
   * @param argument uint160 The signing address to add to the key ring.
   * @param signatures bytes A signature from an existing key on the key ring.
   */
  function takeAdminAction(
    AdminActionType adminActionType, uint160 argument, bytes calldata signatures
  ) external {
    // Only Admin Action Type 6 (AddDualKey) is supported in V1.
    require(
      adminActionType == AdminActionType.AddDualKey,
      "Only adding new Dual key types (admin action type 6) is supported in V1."
    );

    require(argument != uint160(0), "Cannot supply the null address as a key.");

    require(_keys[argument] == KeyType.None, "Key already exists.");

    // Verify signature against a hash of the prefixed admin admin actionID.
    _verifySignature(
      _getAdminActionID(argument, _nonce).toEthSignedMessageHash(), signatures
    );

    // Increment the key count for both standard and admin keys.
    _additionalKeyCounts.standard++;
    _additionalKeyCounts.admin++;

    // Set the key and emit a corresponding event.
    _keys[argument] = KeyType.Dual;
    emit KeyModified(address(argument), true, true);

    // Increment the nonce.
    _nonce++;
  }

  /**
   * @notice View function that implements ERC-1271 and validates a signature
   * against one of the keys on the keyring based on the supplied data. The data
   * must be ABI encoded as (bytes32, uint8, bytes) - in V1, only the first
   * bytes32 parameter is used to validate the supplied signature.
   * @param data bytes The data used to validate the signature.
   * @param signature bytes A signature from an existing key on the key ring.
   * @return The 4-byte magic value to signify a valid signature in ERC-1271, if
   * the signature is valid.
   */
  function isValidSignature(
    bytes calldata data, bytes calldata signature
  ) external view returns (bytes4 magicValue) {
    (bytes32 hash, , ) = abi.decode(data, (bytes32, uint8, bytes));

    _verifySignature(hash, signature);

    magicValue = _ERC_1271_MAGIC_VALUE;
  }

  /**
   * @notice View function that returns the message hash that must be signed in
   * order to add a new key to the key ring based on the supplied parameters.
   * @param adminActionType uint8 Unused in V1, as only action type 6 is valid.
   * @param argument uint160 The signing address to add to the key ring.
   * @param nonce uint256 The nonce to use when deriving the message hash.
   * @return The message hash to sign.
   */
  function getAdminActionID(
    AdminActionType adminActionType, uint160 argument, uint256 nonce
  ) external view returns (bytes32 adminActionID) {
    adminActionType;
    adminActionID = _getAdminActionID(argument, nonce);
  }

  /**
   * @notice View function that returns the message hash that must be signed in
   * order to add a new key to the key ring based on the supplied parameters and
   * using the current nonce of the key ring.
   * @param adminActionType uint8 Unused in V1, as only action type 6 is valid.
   * @param argument uint160 The signing address to add to the key ring.
   * @return The message hash to sign.
   */
  function getNextAdminActionID(
    AdminActionType adminActionType, uint160 argument
  ) external view returns (bytes32 adminActionID) {
    adminActionType;
    adminActionID = _getAdminActionID(argument, _nonce);
  }

  /**
   * @notice Pure function for getting the current Dharma Key Ring version.
   * @return The current Dharma Key Ring version.
   */
  function getVersion() external pure returns (uint256 version) {
    version = _DHARMA_KEY_RING_VERSION;
  }

  /**
   * @notice View function for getting the current number of both standard and
   * admin keys that are set on the Dharma Key Ring. For V1, these should be the
   * same value as one another.
   * @return The number of standard and admin keys set on the Dharma Key Ring.
   */
  function getKeyCount() external view returns (
    uint256 standardKeyCount, uint256 adminKeyCount
  ) {
    AdditionalKeyCount memory additionalKeyCount = _additionalKeyCounts;
    standardKeyCount = uint256(additionalKeyCount.standard) + 1;
    adminKeyCount = uint256(additionalKeyCount.admin) + 1;
  }

  /**
   * @notice View function for getting standard and admin key status of a given
   * address. For V1, these should both be true, or both be false (i.e. the key
   * is not set).
   * @param key address An account to check for key type information.
   * @return Booleans for standard and admin key status for the given address.
   */
  function getKeyType(
    address key
  ) external view returns (bool standard, bool admin) {
    KeyType keyType = _keys[uint160(key)];
    standard = (keyType == KeyType.Standard || keyType == KeyType.Dual);
    admin = (keyType == KeyType.Admin || keyType == KeyType.Dual);
  }

  /**
   * @notice View function for getting the current nonce of the Dharma Key Ring.
   * @return The current nonce set on the Dharma Key Ring.
   */
  function getNonce() external returns (uint256 nonce) {
    nonce = _nonce;
  }

  /**
   * @notice Internal view function to derive an action ID that is prefixed,
   * hashed, and signed by an existing key in order to add a new key to the key
   * ring.
   * @param argument uint160 The signing address to add to the key ring.
   * @param nonce uint256 The nonce to use when deriving the adminActionID.
   * @return The message hash to sign.
   */
  function _getAdminActionID(
    uint160 argument, uint256 nonce
  ) internal view returns (bytes32 adminActionID) {
    adminActionID = keccak256(
      abi.encodePacked(
        address(this), _DHARMA_KEY_RING_VERSION, nonce, argument
      )
    );
  }

  /**
   * @notice Internal view function for verifying a signature and a message hash
   * against the mapping of keys currently stored on the key ring. For V1, all
   * stored keys are the Dual key type, and only a single signature is provided
   * for verification at once since the threshold is fixed at one signature.
   */
  function _verifySignature(
    bytes32 hash, bytes memory signature
  ) internal view {
    require(
      _keys[uint160(hash.recover(signature))] == KeyType.Dual,
      "Supplied signature does not have a signer with the required key type."
    );
  }
}