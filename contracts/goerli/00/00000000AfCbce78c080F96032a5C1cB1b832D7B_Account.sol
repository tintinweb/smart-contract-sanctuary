// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

/**
 *    ,,                           ,,                                
 *   *MM                           db                      `7MM      
 *    MM                                                     MM      
 *    MM,dMMb.      `7Mb,od8     `7MM      `7MMpMMMb.        MM  ,MP'
 *    MM    `Mb       MM' "'       MM        MM    MM        MM ;Y   
 *    MM     M8       MM           MM        MM    MM        MM;Mm   
 *    MM.   ,M9       MM           MM        MM    MM        MM `Mb. 
 *    P^YbmdP'      .JMML.       .JMML.    .JMML  JMML.    .JMML. YA.
 *
 *    Account.sol :: 0x00000000AfCbce78c080F96032a5C1cB1b832D7B
 *    etherscan.io verified 2021-12-18
 */ 

import "./EIP712SignerRecovery.sol";
import "./EIP1271Validator.sol";

/// @title Brink account core
/// @notice Deployed once and used by many proxy contracts as the implementation contract. External functions in this
/// contract are intended to be called by `delegatecall` from proxy contracts deployed by AccountFactory.
contract Account is EIP712SignerRecovery, EIP1271Validator {
  /// @dev Revert if signer of a transaction or EIP712 message signer is not the proxy owner
  /// @param signer The address that is not the owner
  error NotOwner(address signer);

  /// @dev Revert if EIP1271 hash and signature is invalid
  /// @param hash Hash of the data to be validated
  /// @param signature Signature byte array associated with hash
  error InvalidSignature(bytes32 hash, bytes signature);

  /// @dev Revert if the Account.sol implementation contract is called directly
  error NotDelegateCall();

  /// @dev Typehash for signed metaDelegateCall() messages
  bytes32 internal immutable META_DELEGATE_CALL_TYPEHASH;

  /// @dev Typehash for signed metaDelegateCall_EIP1271() messages
  bytes32 internal immutable META_DELEGATE_CALL_EIP1271_TYPEHASH;

  /// @dev Deployment address of the implementation Account.sol contract. Used to enforce onlyDelegateCallable.
  address internal immutable deploymentAddress = address(this);

  /// @dev Used by external functions to revert if they are called directly on the implementation Account.sol contract
  modifier onlyDelegateCallable() {
    if (address(this) == deploymentAddress) {
      revert NotDelegateCall();
    }
    _;
  }

  /// @dev Constructor sets immutable constants
  constructor() { 
    META_DELEGATE_CALL_TYPEHASH = keccak256("MetaDelegateCall(address to,bytes data)");
    META_DELEGATE_CALL_EIP1271_TYPEHASH = keccak256("MetaDelegateCall_EIP1271(address to,bytes data)");
  }

  /// @dev Makes a call to an external contract
  /// @dev Only executable directly by the proxy owner
  /// @param value Amount of wei to send with the call
  /// @param to Address of the external contract to call
  /// @param data Call data to execute
  function externalCall(uint256 value, address to, bytes memory data) external payable onlyDelegateCallable {
    if (proxyOwner() != msg.sender) {
      revert NotOwner(msg.sender);
    }

    assembly {
      let result := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /// @dev Makes a delegatecall to an external contract
  /// @param to Address of the external contract to delegatecall
  /// @param data Call data to execute
  function delegateCall(address to, bytes memory data) external payable onlyDelegateCallable {
    if (proxyOwner() != msg.sender) {
      revert NotOwner(msg.sender);
    }

    assembly {
      let result := delegatecall(gas(), to, add(data, 0x20), mload(data), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /// @dev Allows execution of a delegatecall with a valid signature from the proxyOwner. Uses EIP-712
  /// (https://github.com/ethereum/EIPs/pull/712) signer recovery.
  /// @param to Address of the external contract to delegatecall, signed by the proxyOwner
  /// @param data Call data to include in the delegatecall, signed by the proxyOwner
  /// @param signature Signature of the proxyOwner
  /// @param unsignedData Unsigned call data appended to the delegatecall
  /// @notice WARNING: The `to` contract is responsible for secure handling of the call provided in the encoded
  /// `callData`. If the proxyOwner signs a delegatecall to a malicious contract, this could result in total loss of
  /// their account.
  function metaDelegateCall(
    address to, bytes calldata data, bytes calldata signature, bytes calldata unsignedData
  ) external payable onlyDelegateCallable {
    address signer = _recoverSigner(
      keccak256(abi.encode(META_DELEGATE_CALL_TYPEHASH, to, keccak256(data))),
      signature
    );
    if (proxyOwner() != signer) {
      revert NotOwner(signer);
    }

    bytes memory callData = abi.encodePacked(data, unsignedData);

    assembly {
      let result := delegatecall(gas(), to, add(callData, 0x20), mload(callData), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /// @dev Allows execution of a delegatecall if proxyOwner is a smart contract. Uses EIP-1271
  /// (https://eips.ethereum.org/EIPS/eip-1271) signer validation.
  /// @param to Address of the external contract to delegatecall, validated by the proxyOwner contract
  /// @param data Call data to include in the delegatecall, validated by the proxyOwner contract
  /// @param signature Signature that will be validated by the proxyOwner contract
  /// @param unsignedData Unsigned call data appended to the delegatecall
  /// @notice WARNING: The `to` contract is responsible for secure handling of the call provided in the encoded
  /// `callData`. If the proxyOwner contract validates a delegatecall to a malicious contract, this could result in
  /// total loss of the account.
  function metaDelegateCall_EIP1271(
    address to, bytes calldata data, bytes calldata signature, bytes calldata unsignedData
  ) external payable onlyDelegateCallable {
    bytes32 hash = keccak256(abi.encode(META_DELEGATE_CALL_EIP1271_TYPEHASH, to, keccak256(data)));
    if(!_isValidSignature(proxyOwner(), hash, signature)) {
      revert InvalidSignature(hash, signature);
    }

    bytes memory callData = abi.encodePacked(data, unsignedData);

    assembly {
      let result := delegatecall(gas(), to, add(callData, 0x20), mload(callData), 0, 0)
      returndatacopy(0, 0, returndatasize())
      switch result
      case 0 {
        revert(0, returndatasize())
      }
      default {
        return(0, returndatasize())
      }
    }
  }

  /// @dev Returns the owner address for the proxy
  /// @return _proxyOwner The owner address for the proxy
  function proxyOwner() internal view returns (address _proxyOwner) {
    assembly {
      // copies to "scratch space" 0 memory pointer
      extcodecopy(address(), 0, 0x28, 0x14)
      _proxyOwner := shr(0x60, mload(0))
    }
  }

  receive() external payable { }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

import "./ECDSA.sol";

/// @title Provides signer address recovery for EIP-712 signed messages
/// @notice https://github.com/ethereum/EIPs/pull/712
abstract contract EIP712SignerRecovery {
  /// @dev Recovers the signer address for an EIP-712 signed message
  /// @param dataHash Hash of the data included in the message
  /// @param signature An EIP-712 signature
  function _recoverSigner(bytes32 dataHash, bytes calldata signature) internal view returns (address) {
    // generate the hash for the signed message
    bytes32 messageHash = keccak256(abi.encodePacked(
      "\x19\x01",
      // hash the EIP712 domain separator
      keccak256(abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256("BrinkAccount"),
        keccak256("1"),
        block.chainid,
        address(this)
      )),
      dataHash
    ));

    // recover the signer address from the signed messageHash and return
    return ECDSA.recover(messageHash, signature);
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

import "../Interfaces/IERC1271.sol";

/// @title Provides a validation check on a signer contract that implements EIP-1271
/// @notice https://github.com/ethereum/EIPs/issues/1271
abstract contract EIP1271Validator {

  bytes4 constant internal MAGICVALUE = bytes4(keccak256("isValidSignature(bytes32,bytes)"));

  /**
   * @dev Should return whether the signature provided is valid for the provided hash
   * @param signer Address of a contract that implements EIP-1271
   * @param hash Hash of the data to be validated
   * @param signature Signature byte array associated with hash
   */ 
  function _isValidSignature(address signer, bytes32 hash, bytes calldata signature) internal view returns (bool) {
    return IERC1271(signer).isValidSignature(hash, signature) == MAGICVALUE;
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * replicates the behavior of the
     * https://github.com/ethereum/wiki/wiki/JSON-RPC#eth_sign[`eth_sign`]
     * JSON-RPC method.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.10;
pragma abicoder v1;

interface IERC1271 {
  function isValidSignature(bytes32 _hash, bytes memory _signature) external view returns (bytes4 magicValue);
}