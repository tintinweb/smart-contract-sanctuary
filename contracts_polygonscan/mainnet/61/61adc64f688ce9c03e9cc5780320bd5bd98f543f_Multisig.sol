/**
 *Submitted for verification at polygonscan.com on 2021-08-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;


/**
 * @title Multisig
 * @author 0age (derived from Christian Lundkvist's Simple Multisig)
 * @notice This contract is a multisig that will initiate timelocks for account
 * recovery on the Dharma Smart Wallet, based on Christian Lundkvist's Simple
 * Multisig (found at https://github.com/christianlundkvist/simple-multisig).
 * The Account Recovery Manager is hard-coded as the only allowable call
 * destination, and any changes in ownership or signature threshold will require
 * deploying a new multisig and setting it as the new operator on the account
 * recovery manager.
 */
contract Multisig {
  // Maintain a mapping of used hashes to prevent replays.
  mapping(bytes32 => bool) private _usedHashes;

  // Maintain a mapping and a convenience array of owners.
  mapping(address => bool) private _isOwner;
  address[] private _owners;

  // The Account Recovery Manager is the only account the multisig can call.
  address private immutable _DESTINATION;

  // The threshold is an exact number of valid signatures that must be supplied.
  uint256 private immutable _THRESHOLD;

  // Note: Owners must be strictly increasing in order to prevent duplicates.
  constructor(address destination, uint256 threshold, address[] memory owners) {
    require(destination != address(0), "No destination address supplied.");
    _DESTINATION = destination;

    require(threshold > 0 && threshold <= 10, "Invalid threshold supplied.");
    _THRESHOLD = threshold;

    require(owners.length <= 10, "Cannot have more than 10 owners.");
    require(threshold <= owners.length, "Threshold cannot exceed total owners.");

    address lastAddress = address(0);
    for (uint256 i = 0; i < owners.length; i++) {
      require(
        owners[i] > lastAddress, "Owner addresses must be strictly increasing."
      );
      _isOwner[owners[i]] = true;
      lastAddress = owners[i];
    }
    _owners = owners;
  }

  function getHash(
    bytes calldata data,
    address executor,
    uint256 gasLimit,
    bytes32 salt
  ) external view returns (bytes32 hash, bool usable) {
    (hash, usable) = _getHash(data, executor, gasLimit, salt);
  }

  function getOwners() external view returns (address[] memory owners) {
    owners = _owners;
  }

  function isOwner(address account) external view returns (bool owner) {
    owner = _isOwner[account];
  }

  function getThreshold() external view returns (uint256 threshold) {
    threshold = _THRESHOLD;
  }

  function getDestination() external view returns (address destination) {
    destination = _DESTINATION;
  }

  // Note: addresses recovered from signatures must be strictly increasing.
  function execute(
    bytes calldata data,
    address executor,
    uint256 gasLimit,
    bytes32 salt,
    bytes calldata signatures
  ) external returns (bool success, bytes memory returnData) {
    require(
      executor == msg.sender || executor == address(0),
      "Must call from the executor account if one is specified."
    );

    // Derive the message hash and ensure that it has not been used before.
    (bytes32 rawHash, bool usable) = _getHash(data, executor, gasLimit, salt);
    require(usable, "Hash in question has already been used previously.");

    // wrap the derived message hash as an eth signed messsage hash.
    bytes32 hash = _toEthSignedMessageHash(rawHash);

    // Recover each signer from provided signatures and ensure threshold is met.
    address[] memory signers = _recoverGroup(hash, signatures);

    require(signers.length == _THRESHOLD, "Total signers must equal threshold.");

    // Verify that each signatory is an owner and is strictly increasing.
    address lastAddress = address(0); // cannot have address(0) as an owner
    for (uint256 i = 0; i < signers.length; i++) {
      require(
        _isOwner[signers[i]], "Signature does not correspond to an owner."
      );
      require(
        signers[i] > lastAddress, "Signer addresses must be strictly increasing."
      );
      lastAddress = signers[i];
    }

    // Add the hash to the mapping of used hashes and execute the transaction.
    _usedHashes[rawHash] = true;
    (success, returnData) = _DESTINATION.call{gas:gasLimit}(data);
  }

  function _getHash(
    bytes memory data,
    address executor,
    uint256 gasLimit,
    bytes32 salt
  ) internal view returns (bytes32 hash, bool usable) {
    // Prevent replays across different chains.
    uint256 chainId;
    assembly {
        chainId := chainid()
    }

    // Note: this is the data used to create a personal signed message hash.
    hash = keccak256(
      abi.encodePacked(address(this), chainId, salt, executor, gasLimit, data)
    );

    usable = !_usedHashes[hash];
  }

  /**
   * @dev Returns each address that signed a hashed message (`hash`) from a
   * collection of `signatures`.
   *
   * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
   * this function rejects them by requiring the `s` value to be in the lower
   * half order, and the `v` value to be either 27 or 28.
   *
   * NOTE: This call _does not revert_ if a signature is invalid, or if the
   * signer is otherwise unable to be retrieved. In those scenarios, the zero
   * address is returned for that signature.
   *
   * IMPORTANT: `hash` _must_ be the result of a hash operation for the
   * verification to be secure: it is possible to craft signatures that recover
   * to arbitrary addresses for non-hashed data.
   */
  function _recoverGroup(
    bytes32 hash,
    bytes memory signatures
  ) internal pure returns (address[] memory signers) {
    // Ensure that the signatures length is a multiple of 65.
    if (signatures.length % 65 != 0) {
      return new address[](0);
    }

    // Create an appropriately-sized array of addresses for each signer.
    signers = new address[](signatures.length / 65);

    // Get each signature location and divide into r, s and v variables.
    bytes32 signatureLocation;
    bytes32 r;
    bytes32 s;
    uint8 v;

    for (uint256 i = 0; i < signers.length; i++) {
      assembly {
        signatureLocation := add(signatures, mul(i, 65))
        r := mload(add(signatureLocation, 32))
        s := mload(add(signatureLocation, 64))
        v := byte(0, mload(add(signatureLocation, 96)))
      }

      // EIP-2 still allows signature malleability for ecrecover(). Remove
      // this possibility and make the signature unique.
      if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
        continue;
      }

      if (v != 27 && v != 28) {
        continue;
      }

      // If signature is valid & not malleable, add signer address.
      signers[i] = ecrecover(hash, v, r, s);
    }
  }

  function _toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
  }
}