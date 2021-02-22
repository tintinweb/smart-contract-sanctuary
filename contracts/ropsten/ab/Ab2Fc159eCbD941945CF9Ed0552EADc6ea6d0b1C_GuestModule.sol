// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../utils/SignatureValidator.sol";

import "./commons/Implementation.sol";
import "./commons/ModuleAuth.sol";
import "./commons/ModuleHooks.sol";
import "./commons/ModuleCalls.sol";
import "./commons/ModuleUpdate.sol";
import "./commons/ModuleCreator.sol";

import "../interfaces/receivers/IERC1155Receiver.sol";
import "../interfaces/receivers/IERC721Receiver.sol";

import "../interfaces/IERC1271Wallet.sol";


/**
 * GuestModule implements an Arcadeum wallet without signatures, nonce or replay protection.
 * executing transactions using this wallet is not an authenticated process, and can be done by any address.
 *
 * @notice This contract is completely public with no security, designed to execute pre-signed transactions
 *   and use Arcadeum tools without using the wallets.
 */
contract GuestModule is
  ModuleAuth,
  ModuleCalls,
  ModuleCreator
{
  /**
   * @notice Allow any caller to execute an action
   * @param _txs Transactions to process
   */
  function execute(
    Transaction[] memory _txs,
    uint256,
    bytes memory
  ) public override {
    // Hash transaction bundle
    bytes32 txHash = _subDigest(keccak256(abi.encode('guest:', _txs)));

    // Execute the transactions
    _executeGuest(txHash, _txs);
  }

  /**
   * @notice Allow any caller to execute an action
   * @param _txs Transactions to process
   */
  function selfExecute(
    Transaction[] memory _txs
  ) public override {
    // Hash transaction bundle
    bytes32 txHash = _subDigest(keccak256(abi.encode('self:', _txs)));

    // Execute the transactions
    _executeGuest(txHash, _txs);
  }

  /**
   * @notice Executes a list of transactions
   * @param _txHash  Hash of the batch of transactions
   * @param _txs  Transactions to execute
   */
  function _executeGuest(
    bytes32 _txHash,
    Transaction[] memory _txs
  ) private {
    // Execute transaction
    for (uint256 i = 0; i < _txs.length; i++) {
      Transaction memory transaction = _txs[i];

      bool success;
      bytes memory result;

      require(!transaction.delegateCall, 'GuestModule#_executeGuest: delegateCall not allowed');
      require(gasleft() >= transaction.gasLimit, "GuestModule#_executeGuest: NOT_ENOUGH_GAS");

      // solhint-disable
      (success, result) = transaction.target.call{
        value: transaction.value,
        gas: transaction.gasLimit == 0 ? gasleft() : transaction.gasLimit
      }(transaction.data);
      // solhint-enable

      if (success) {
        emit TxExecuted(_txHash);
      } else {
        _revertBytes(transaction, _txHash, result);
      }
    }
  }

  /**
   * @notice Validates any signature image, because the wallet is public and has now owner.
   * @return true, all signatures are valid.
   */
  function _isValidImage(bytes32) internal override view returns (bool) {
    return true;
  }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(
    bytes4 _interfaceID
  ) public override (
    ModuleAuth,
    ModuleCalls,
    ModuleCreator
  ) pure returns (bool) {
    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "../interfaces/IERC1271Wallet.sol";

import "./LibBytes.sol";

/**
 * @dev Contains logic for signature validation.
 * Signatures from wallet contracts assume ERC-1271 support (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1271.md)
 * Notes: Methods are strongly inspired by contracts in https://github.com/0xProject/0x-monorepo/blob/development/
 */
contract SignatureValidator {
  using LibBytes for bytes;

  /***********************************|
  |             Variables             |
  |__________________________________*/

  // bytes4(keccak256("isValidSignature(bytes,bytes)"))
  bytes4 constant internal ERC1271_MAGICVALUE = 0x20c13b0b;

  // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
  bytes4 constant internal ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e;

  // Allowed signature types.
  uint256 private constant SIG_TYPE_EIP712 = 1;
  uint256 private constant SIG_TYPE_ETH_SIGN = 2;
  uint256 private constant SIG_TYPE_WALLET_BYTES32 = 3;

  /***********************************|
  |        Signature Functions        |
  |__________________________________*/

 /**
   * @notice Recover the signer of hash, assuming it's an EOA account
   * @dev Only for SignatureType.EIP712 and SignatureType.EthSign signatures
   * @param _hash      Hash that was signed
   *   encoded as (bytes32 r, bytes32 s, uint8 v, ... , SignatureType sigType)
   */
  function recoverSigner(
    bytes32 _hash,
    bytes memory _signature
  ) internal pure returns (address signer) {
    uint256 signatureType = uint8(_signature[_signature.length - 1]);

    // Variables are not scoped in Solidity.
    uint8 v = uint8(_signature[64]);
    bytes32 r = _signature.readBytes32(0);
    bytes32 s = _signature.readBytes32(32);

    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
    // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
    //
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    //
    // Source OpenZeppelin
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol

    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      revert("SignatureValidator#recoverSigner: invalid signature 's' value");
    }

    if (v != 27 && v != 28) {
      revert("SignatureValidator#recoverSigner: invalid signature 'v' value");
    }

    // Signature using EIP712
    if (signatureType == SIG_TYPE_EIP712) {
      signer = ecrecover(_hash, v, r, s);

    // Signed using web3.eth_sign() or Ethers wallet.signMessage()
    } else if (signatureType == SIG_TYPE_ETH_SIGN) {
      signer = ecrecover(
        keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)),
        v,
        r,
        s
      );

    } else {
      // Anything other signature types are illegal (We do not return false because
      // the signature may actually be valid, just not in a format
      // that we currently support. In this case returning false
      // may lead the caller to incorrectly believe that the
      // signature was invalid.)
      revert("SignatureValidator#recoverSigner: UNSUPPORTED_SIGNATURE_TYPE");
    }

    // Prevent signer from being 0x0
    require(
      signer != address(0x0),
      "SignatureValidator#recoverSigner: INVALID_SIGNER"
    );

    return signer;
  }

 /**
   * @notice Returns true if the provided signature is valid for the given signer.
   * @dev Supports SignatureType.EIP712, SignatureType.EthSign, and ERC1271 signatures
   * @param _hash      Hash that was signed
   * @param _signer    Address of the signer candidate
   * @param _signature Signature byte array
   */
  function isValidSignature(
    bytes32 _hash,
    address _signer,
    bytes memory _signature
  ) internal view returns (bool valid) {
    uint256 signatureType = uint8(_signature[_signature.length - 1]);

    if (signatureType == SIG_TYPE_EIP712 || signatureType == SIG_TYPE_ETH_SIGN) {
      // Recover signer and compare with provided
      valid = recoverSigner(_hash, _signature) == _signer;

    } else if (signatureType == SIG_TYPE_WALLET_BYTES32) {
      // Remove signature type before calling ERC1271, restore after call
      uint256 prevSize; assembly { prevSize := mload(_signature) mstore(_signature, sub(prevSize, 1)) }
      valid = ERC1271_MAGICVALUE_BYTES32 == IERC1271Wallet(_signer).isValidSignature(_hash, _signature);
      assembly { mstore(_signature, prevSize) }

    } else {
      // Anything other signature types are illegal (We do not return false because
      // the signature may actually be valid, just not in a format
      // that we currently support. In this case returning false
      // may lead the caller to incorrectly believe that the
      // signature was invalid.)
      revert("SignatureValidator#isValidSignature: UNSUPPORTED_SIGNATURE_TYPE");
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

/**
 * @dev Allows modules to access the implementation slot
 */
contract Implementation {
  /**
   * @notice Updates the Wallet implementation
   * @param _imp New implementation address
   * @dev The wallet implementation is stored on the storage slot
   *   defined by the address of the wallet itself
   *   WARNING updating this value may break the wallet and users
   *   must be confident that the new implementation is safe.
   */
  function _setImplementation(address _imp) internal {
    assembly {
      sstore(address(), _imp)
    }
  }

  /**
   * @notice Returns the Wallet implementation
   * @return _imp The address of the current Wallet implementation
   */
  function _getImplementation() internal view returns (address _imp) {
    assembly {
      _imp := sload(address())
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "../../utils/LibBytes.sol";
import "../../utils/SignatureValidator.sol";
import "../../interfaces/IERC1271Wallet.sol";

import "./interfaces/IModuleAuth.sol";

import "./ModuleERC165.sol";


abstract contract ModuleAuth is IModuleAuth, ModuleERC165, SignatureValidator, IERC1271Wallet {
  using LibBytes for bytes;

  uint256 private constant FLAG_SIGNATURE = 0;
  uint256 private constant FLAG_ADDRESS = 1;
  uint256 private constant FLAG_DYNAMIC_SIGNATURE = 2;

  bytes4 private constant SELECTOR_ERC1271_BYTES_BYTES = 0x20c13b0b;
  bytes4 private constant SELECTOR_ERC1271_BYTES32_BYTES = 0x1626ba7e;

  /**
   * @notice Verify if signer is default wallet owner
   * @param _hash       Hashed signed message
   * @param _signature  Array of signatures with signers ordered
   *                    like the the keys in the multisig configs
   *
   * @dev The signature must be solidity packed and contain the total number of owners,
   *      the threshold, the weight and either the address or a signature for each owner.
   *
   *      Each weight & (address or signature) pair is prefixed by a flag that signals if such pair
   *      contains an address or a signature. The aggregated weight of the signatures must surpass the threshold.
   *
   *      Flag types:
   *        0x00 - Signature
   *        0x01 - Address
   *
   *      E.g:
   *      abi.encodePacked(
   *        uint16 threshold,
   *        uint8 01,  uint8 weight_1, address signer_1,
   *        uint8 00, uint8 weight_2, bytes signature_2,
   *        ...
   *        uint8 01,  uint8 weight_5, address signer_5
   *      )
   */
  function _signatureValidation(
    bytes32 _hash,
    bytes memory _signature
  )
    internal override view returns (bool)
  {
    (
      uint16 threshold,  // required threshold signature
      uint256 rindex     // read index
    ) = _signature.readFirstUint16();

    // Start image hash generation
    bytes32 imageHash = bytes32(uint256(threshold));

    // Acumulated weight of signatures
    uint256 totalWeight;

    // Iterate until the image is completed
    while (rindex < _signature.length) {
      // Read next item type and addrWeight
      uint256 flag; uint256 addrWeight; address addr;
      (flag, addrWeight, rindex) = _signature.readUint8Uint8(rindex);

      if (flag == FLAG_ADDRESS) {
        // Read plain address
        (addr, rindex) = _signature.readAddress(rindex);
      } else if (flag == FLAG_SIGNATURE) {
        // Read single signature and recover signer
        bytes memory signature;
        (signature, rindex) = _signature.readBytes66(rindex);
        addr = recoverSigner(_hash, signature);

        // Acumulate total weight of the signature
        totalWeight += addrWeight;
      } else if (flag == FLAG_DYNAMIC_SIGNATURE) {
        // Read signer
        (addr, rindex) = _signature.readAddress(rindex);

        // Read signature size
        uint256 size;
        (size, rindex) = _signature.readUint16(rindex);

        // Read dynamic size signature
        bytes memory signature;
        (signature, rindex) = _signature.readBytes(rindex, size);
        require(isValidSignature(_hash, addr, signature), "ModuleAuth#_signatureValidation: INVALID_SIGNATURE");

        // Acumulate total weight of the signature
        totalWeight += addrWeight;
      } else {
        revert("ModuleAuth#_signatureValidation INVALID_FLAG");
      }

      // Write weight and address to image
      imageHash = keccak256(abi.encode(imageHash, addrWeight, addr));
    }

    return totalWeight >= threshold && _isValidImage(imageHash);
  }

  /**
   * @notice Validates the signature image
   * @param _imageHash Hashed image of signature
   * @return true if the signature image is valid
   */
  function _isValidImage(bytes32 _imageHash) internal virtual view returns (bool);

  /**
   * @notice Will hash _data to be signed (similar to EIP-712)
   * @param _digest Pre-final digest
   * @return hashed data for this wallet
   */
  function _subDigest(bytes32 _digest) internal override view returns (bytes32) {
    uint256 chainId; assembly { chainId := chainid() }
    return keccak256(
      abi.encodePacked(
        "\x19\x01",
        chainId,
        address(this),
        _digest
      )
    );
  }

  /**
   * @notice Verifies whether the provided signature is valid with respect to the provided data
   * @dev MUST return the correct magic value if the signature provided is valid for the provided data
   *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)"))
   * @param _data       Arbitrary length data signed on the behalf of address(this)
   * @param _signatures Signature byte array associated with _data.
   *                    Encoded as abi.encode(Signature[], Configs)
   * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
   */
  function isValidSignature(
    bytes calldata _data,
    bytes calldata _signatures
  ) external override view returns (bytes4) {
    // Validate signatures
    if (_signatureValidation(_subDigest(keccak256(_data)), _signatures)) {
      return SELECTOR_ERC1271_BYTES_BYTES;
    }
  }

  /**
   * @notice Verifies whether the provided signature is valid with respect to the provided hash
   * @dev MUST return the correct magic value if the signature provided is valid for the provided hash
   *   > The bytes4 magic value to return when signature is valid is 0x1626ba7e : bytes4(keccak256("isValidSignature(bytes32,bytes)"))
   * @param _hash       keccak256 hash that was signed
   * @param _signatures Signature byte array associated with _data.
   *                    Encoded as abi.encode(Signature[], Configs)
   * @return magicValue Magic value 0x1626ba7e if the signature is valid and 0x0 otherwise
   */
  function isValidSignature(
    bytes32 _hash,
    bytes calldata _signatures
  ) external override view returns (bytes4) {
    // Validate signatures
    if (_signatureValidation(_subDigest(_hash), _signatures)) {
      return SELECTOR_ERC1271_BYTES32_BYTES;
    }
  }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) public override virtual pure returns (bool) {
    if (
      _interfaceID == type(IModuleAuth).interfaceId ||
      _interfaceID == type(IERC1271Wallet).interfaceId
    ) {
      return true;
    }

    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "./interfaces/IModuleHooks.sol";

import "./ModuleSelfAuth.sol";
import "./ModuleStorage.sol";
import "./ModuleERC165.sol";

import "../../interfaces/receivers/IERC1155Receiver.sol";
import "../../interfaces/receivers/IERC721Receiver.sol";
import "../../interfaces/receivers/IERC223Receiver.sol";


contract ModuleHooks is IERC1155Receiver, IERC721Receiver, IModuleHooks, ModuleERC165, ModuleSelfAuth {
  //                       HOOKS_KEY = keccak256("org.arcadeum.module.hooks.hooks");
  bytes32 private constant HOOKS_KEY = bytes32(0xbe27a319efc8734e89e26ba4bc95f5c788584163b959f03fa04e2d7ab4b9a120);

  /**
   * @notice Reads the implementation hook of a signature
   * @param _signature Signature function
   * @return The address of the implementation hook, address(0) if none
  */
  function readHook(bytes4 _signature) external override view returns (address) {
    return _readHook(_signature);
  }

  /**
   * @notice Adds a new hook to handle a given function selector
   * @param _signature Signature function linked to the hook
   * @param _implementation Hook implementation contract
   * @dev Can't overwrite hooks that are part of the mainmodule (those defined below)
   */
  function addHook(bytes4 _signature, address _implementation) external override onlySelf {
    require(_readHook(_signature) == address(0), "ModuleHooks#addHook: HOOK_ALREADY_REGISTERED");
    _writeHook(_signature, _implementation);
  }

  /**
   * @notice Removes a registered hook
   * @param _signature Signature function linked to the hook
   * @dev Can't remove hooks that are part of the mainmodule (those defined below) 
   *      without upgrading the wallet
   */
  function removeHook(bytes4 _signature) external override onlySelf {
    require(_readHook(_signature) != address(0), "ModuleHooks#removeHook: HOOK_NOT_REGISTERED");
    _writeHook(_signature, address(0));
  }

  /**
   * @notice Reads the implementation hook of a signature
   * @param _signature Signature function
   * @return The address of the implementation hook, address(0) if none
  */
  function _readHook(bytes4 _signature) private view returns (address) {
    return address(uint256(ModuleStorage.readBytes32Map(HOOKS_KEY, _signature)));
  }

  /**
   * @notice Writes the implementation hook of a signature
   * @param _signature Signature function
   * @param _implementation Hook implementation contract
  */
  function _writeHook(bytes4 _signature, address _implementation) private {
    ModuleStorage.writeBytes32Map(HOOKS_KEY, _signature, bytes32(uint256(_implementation)));
  }

  /**
   * @notice Handle the receipt of a single ERC1155 token type.
   * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external override returns (bytes4) {
    return ModuleHooks.onERC1155Received.selector;
  }

  /**
   * @notice Handle the receipt of multiple ERC1155 token types.
   * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external override returns (bytes4) {
    return ModuleHooks.onERC1155BatchReceived.selector;
  }

  /**
   * @notice Handle the receipt of a single ERC721 token.
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(address, address, uint256, bytes calldata) external override returns (bytes4) {
    return ModuleHooks.onERC721Received.selector;
  }

  /**
   * @notice Routes fallback calls through hooks
   */
  fallback() external payable {
    address target = _readHook(msg.sig);
    if (target != address(0)) {
      (bool success, bytes memory result) = target.delegatecall(msg.data);
      assembly {
        if iszero(success)  {
          revert(add(result, 0x20), mload(result))
        }

        return(add(result, 0x20), mload(result))
      }
    }
  }

  /**
   * @notice Allows the wallet to receive ETH
   */
  receive() external payable { }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) public override virtual pure returns (bool) {
    if (
      _interfaceID == type(IModuleHooks).interfaceId ||
      _interfaceID == type(IERC1155Receiver).interfaceId ||
      _interfaceID == type(IERC721Receiver).interfaceId ||
      _interfaceID == type(IERC223Receiver).interfaceId
    ) {
      return true;
    }

    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./ModuleSelfAuth.sol";
import "./ModuleStorage.sol";
import "./ModuleERC165.sol";

import "./interfaces/IModuleCalls.sol";
import "./interfaces/IModuleAuth.sol";


abstract contract ModuleCalls is IModuleCalls, IModuleAuth, ModuleERC165, ModuleSelfAuth {
  //                       NONCE_KEY = keccak256("org.arcadeum.module.calls.nonce");
  bytes32 private constant NONCE_KEY = bytes32(0x8d0bf1fd623d628c741362c1289948e57b3e2905218c676d3e69abee36d6ae2e);

  uint256 private constant NONCE_BITS = 96;
  bytes32 private constant NONCE_MASK = bytes32((1 << NONCE_BITS) - 1);

  /**
   * @notice Returns the next nonce of the default nonce space
   * @dev The default nonce space is 0x00
   * @return The next nonce
   */
  function nonce() external override virtual view returns (uint256) {
    return readNonce(0);
  }

  /**
   * @notice Returns the next nonce of the given nonce space
   * @param _space Nonce space, each space keeps an independent nonce count
   * @return The next nonce
   */
  function readNonce(uint256 _space) public override virtual view returns (uint256) {
    return uint256(ModuleStorage.readBytes32Map(NONCE_KEY, bytes32(_space)));
  }

  /**
   * @notice Changes the next nonce of the given nonce space
   * @param _space Nonce space, each space keeps an independent nonce count
   * @param _nonce Nonce to write on the space
   */
  function _writeNonce(uint256 _space, uint256 _nonce) private {
    ModuleStorage.writeBytes32Map(NONCE_KEY, bytes32(_space), bytes32(_nonce));
  }

  /**
   * @notice Allow wallet owner to execute an action
   * @dev Relayers must ensure that the gasLimit specified for each transaction
   *      is acceptable to them. A user could specify large enough that it could
   *      consume all the gas available.
   * @param _txs        Transactions to process
   * @param _nonce      Signature nonce (may contain an encoded space)
   * @param _signature  Encoded signature
   */
  function execute(
    Transaction[] memory _txs,
    uint256 _nonce,
    bytes memory _signature
  ) public override virtual {
    // Validate and update nonce
    _validateNonce(_nonce);

    // Hash transaction bundle
    bytes32 txHash = _subDigest(keccak256(abi.encode(_nonce, _txs)));

    // Verify that signatures are valid
    require(
      _signatureValidation(txHash, _signature),
      "ModuleCalls#execute: INVALID_SIGNATURE"
    );

    // Execute the transactions
    _execute(txHash, _txs);
  }

  /**
   * @notice Allow wallet to execute an action
   *   without signing the message
   * @param _txs  Transactions to execute
   */
  function selfExecute(
    Transaction[] memory _txs
  ) public override virtual onlySelf {
    // Hash transaction bundle
    bytes32 txHash = _subDigest(keccak256(abi.encode('self:', _txs)));

    // Execute the transactions
    _execute(txHash, _txs);
  }

  /**
   * @notice Executes a list of transactions
   * @param _txHash  Hash of the batch of transactions
   * @param _txs  Transactions to execute
   */
  function _execute(
    bytes32 _txHash,
    Transaction[] memory _txs
  ) private {
    // Execute transaction
    for (uint256 i = 0; i < _txs.length; i++) {
      Transaction memory transaction = _txs[i];

      bool success;
      bytes memory result;

      require(gasleft() >= transaction.gasLimit, "ModuleCalls#_execute: NOT_ENOUGH_GAS");

      if (transaction.delegateCall) {
        (success, result) = transaction.target.delegatecall{
          gas: transaction.gasLimit == 0 ? gasleft() : transaction.gasLimit
        }(transaction.data);
      } else {
        (success, result) = transaction.target.call{
          value: transaction.value,
          gas: transaction.gasLimit == 0 ? gasleft() : transaction.gasLimit
        }(transaction.data);
      }

      if (success) {
        emit TxExecuted(_txHash);
      } else {
        _revertBytes(transaction, _txHash, result);
      }
    }
  }

  /**
   * @notice Verify if a nonce is valid
   * @param _rawNonce Nonce to validate (may contain an encoded space)
   * @dev A valid nonce must be above the last one used
   *   with a maximum delta of 100
   */
  function _validateNonce(uint256 _rawNonce) private {
    // Retrieve current nonce for this wallet
    (uint256 space, uint256 providedNonce) = _decodeNonce(_rawNonce);
    uint256 currentNonce = readNonce(space);

    // Verify if nonce is valid
    require(
      providedNonce == currentNonce,
      "MainModule#_auth: INVALID_NONCE"
    );

    // Update signature nonce
    uint256 newNonce = providedNonce + 1;
    _writeNonce(space, newNonce);
    emit NonceChange(space, newNonce);
  }

  /**
   * @notice Logs a failed transaction, reverts if the transaction is not optional
   * @param _tx      Transaction that is reverting
   * @param _txHash  Hash of the transaction
   * @param _reason  Encoded revert message
   */
  function _revertBytes(
    Transaction memory _tx,
    bytes32 _txHash,
    bytes memory _reason
  ) internal {
    if (_tx.revertOnError) {
      assembly { revert(add(_reason, 0x20), mload(_reason)) }
    } else {
      emit TxFailed(_txHash, _reason);
    }
  }

  /**
   * @notice Decodes a raw nonce
   * @dev A raw nonce is encoded using the first 160 bits for the space
   *  and the last 96 bits for the nonce
   * @param _rawNonce Nonce to be decoded
   * @return _space The nonce space of the raw nonce
   * @return _nonce The nonce of the raw nonce
   */
  function _decodeNonce(uint256 _rawNonce) private pure returns (uint256 _space, uint256 _nonce) {
    _nonce = uint256(bytes32(_rawNonce) & NONCE_MASK);
    _space = _rawNonce >> NONCE_BITS;
  }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) public override virtual pure returns (bool) {
    if (_interfaceID == type(IModuleCalls).interfaceId) {
      return true;
    }

    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "./interfaces/IModuleUpdate.sol";

import "./Implementation.sol";
import "./ModuleSelfAuth.sol";
import "./ModuleERC165.sol";

import "../../utils/LibAddress.sol";


contract ModuleUpdate is IModuleUpdate, ModuleERC165, ModuleSelfAuth, Implementation {
  using LibAddress for address;

  event ImplementationUpdated(address newImplementation);

  /**
   * @notice Updates the implementation of the base wallet
   * @param _implementation New main module implementation
   * @dev WARNING Updating the implementation can brick the wallet
   */
  function updateImplementation(address _implementation) external override onlySelf {
    require(_implementation.isContract(), "ModuleUpdate#updateImplementation: INVALID_IMPLEMENTATION");
    _setImplementation(_implementation);
    emit ImplementationUpdated(_implementation);
  }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) public override virtual pure returns (bool) {
    if (_interfaceID == type(IModuleUpdate).interfaceId) {
      return true;
    }

    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

import "./interfaces/IModuleCreator.sol";

import "./ModuleSelfAuth.sol";
import "./ModuleERC165.sol";


contract ModuleCreator is IModuleCreator, ModuleERC165, ModuleSelfAuth {
  event CreatedContract(address _contract);

  /**
   * @notice Creates a contract forwarding eth value
   * @param _code Creation code of the contract
   * @return addr The address of the created contract
   */
  function createContract(bytes memory _code) public override payable onlySelf returns (address addr) {
    assembly { addr := create(callvalue(), add(_code, 32), mload(_code)) }
    emit CreatedContract(addr);
  }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) public override virtual pure returns (bool) {
    if (_interfaceID == type(IModuleCreator).interfaceId) {
      return true;
    }

    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;


interface IERC1155Receiver {
  function onERC1155Received(address, address, uint256, uint256, bytes calldata) external returns (bytes4);
  function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external returns (bytes4);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;


interface IERC721Receiver {
  function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;


interface IERC1271Wallet {

  /**
   * @notice Verifies whether the provided signature is valid with respect to the provided data
   * @dev MUST return the correct magic value if the signature provided is valid for the provided data
   *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
   *   > This function MAY modify Ethereum's state
   * @param _data       Arbitrary length data signed on the behalf of address(this)
   * @param _signature  Signature byte array associated with _data
   * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
   */
  function isValidSignature(
    bytes calldata _data,
    bytes calldata _signature)
    external
    view
    returns (bytes4 magicValue);

  /**
   * @notice Verifies whether the provided signature is valid with respect to the provided hash
   * @dev MUST return the correct magic value if the signature provided is valid for the provided hash
   *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
   *   > This function MAY modify Ethereum's state
   * @param _hash       keccak256 hash that was signed
   * @param _signature  Signature byte array associated with _data
   * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
   */
  function isValidSignature(
    bytes32 _hash,
    bytes calldata _signature)
    external
    view
    returns (bytes4 magicValue);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

library LibBytes {
  using LibBytes for bytes;

  /***********************************|
  |        Read Bytes Functions       |
  |__________________________________*/

  /**
   * @dev Read firsts uint16 value.
   * @param data Byte array to be read.
   * @return a uint16 value of data at index zero.
   * @return newIndex Updated index after reading the values.
   */
  function readFirstUint16(
    bytes memory data
  ) internal pure returns (
    uint16 a,
    uint256 newIndex
  ) {
    assembly {
      let word := mload(add(32, data))
      a := shr(240, word)
      newIndex := 2
    }
    require(2 <= data.length, "LibBytes#readFirstUint16: OUT_OF_BOUNDS");
  }

  /**
   * @dev Reads consecutive bool (8 bits) and uint8 values.
   * @param data Byte array to be read.
   * @param index Index in byte array of uint8 and uint8 values.
   * @return a uint8 value of data at given index.
   * @return b uint8 value of data at given index + 8.
   * @return newIndex Updated index after reading the values.
   */
  function readUint8Uint8(
    bytes memory data,
    uint256 index
  ) internal pure returns (
    uint8 a,
    uint8 b,
    uint256 newIndex
  ) {
    assembly {
      let word := mload(add(index, add(32, data)))
      a := shr(248, word)
      b := and(shr(240, word), 0xff)
      newIndex := add(index, 2)
    }
    require(newIndex <= data.length, "LibBytes#readUint8Uint8: OUT_OF_BOUNDS");
  }

  /**
   * @dev Reads an address value from a position in a byte array.
   * @param data Byte array to be read.
   * @param index Index in byte array of address value.
   * @return a address value of data at given index.
   * @return newIndex Updated index after reading the value.
   */
  function readAddress(
    bytes memory data,
    uint256 index
  ) internal pure returns (
    address a,
    uint256 newIndex
  ) {
    assembly {
      let word := mload(add(index, add(32, data)))
      a := and(shr(96, word), 0xffffffffffffffffffffffffffffffffffffffff)
      newIndex := add(index, 20)
    }
    require(newIndex <= data.length, "LibBytes#readAddress: OUT_OF_BOUNDS");
  }

  /**
   * @dev Reads 66 bytes from a position in a byte array.
   * @param data Byte array to be read.
   * @param index Index in byte array of 66 bytes value.
   * @return a 66 bytes bytes array value of data at given index.
   * @return newIndex Updated index after reading the value.
   */
  function readBytes66(
    bytes memory data,
    uint256 index
  ) internal pure returns (
    bytes memory a,
    uint256 newIndex
  ) {
    a = new bytes(66);
    assembly {
      let offset := add(32, add(data, index))
      mstore(add(a, 32), mload(offset))
      mstore(add(a, 64), mload(add(offset, 32)))
      mstore(add(a, 66), mload(add(offset, 34)))
      newIndex := add(index, 66)
    }
    require(newIndex <= data.length, "LibBytes#readBytes66: OUT_OF_BOUNDS");
  }

  /**
   * @dev Reads a bytes32 value from a position in a byte array.
   * @param b Byte array containing a bytes32 value.
   * @param index Index in byte array of bytes32 value.
   * @return result bytes32 value from byte array.
   */
  function readBytes32(
    bytes memory b,
    uint256 index
  )
    internal
    pure
    returns (bytes32 result)
  {
    require(
      b.length >= index + 32,
      "LibBytes#readBytes32: GREATER_OR_EQUAL_TO_32_LENGTH_REQUIRED"
    );

    // Arrays are prefixed by a 256 bit length parameter
    uint256 pos = index + 32;

    // Read the bytes32 from array memory
    assembly {
      result := mload(add(b, pos))
    }
    return result;
  }

  /**
   * @dev Reads an uint16 value from a position in a byte array.
   * @param data Byte array to be read.
   * @param index Index in byte array of uint16 value.
   * @return a uint16 value of data at given index.
   * @return newIndex Updated index after reading the value.
   */
  function readUint16(
    bytes memory data,
    uint256 index
  ) internal pure returns (uint16 a, uint256 newIndex) {
    assembly {
      let word := mload(add(index, add(32, data)))
      a := and(shr(240, word), 0xffff)
      newIndex := add(index, 2)
    }
    require(newIndex <= data.length, "LibBytes#readUint16: OUT_OF_BOUNDS");
  }

  /**
   * @dev Reads bytes from a position in a byte array.
   * @param data Byte array to be read.
   * @param index Index in byte array of bytes value.
   * @param size Number of bytes to read.
   * @return a bytes bytes array value of data at given index.
   * @return newIndex Updated index after reading the value.
   */
  function readBytes(
    bytes memory data,
    uint256 index,
    uint256 size
  ) internal pure returns (bytes memory a, uint256 newIndex) {
    a = new bytes(size);

    assembly {
      let offset := add(32, add(data, index))

      let i := 0 let n := 32
      // Copy each word, except last one
      for { } lt(n, size) { i := n n := add(n, 32) } {
        mstore(add(a, n), mload(add(offset, i)))
      }

      // Load word after new array
      let suffix := add(a, add(32, size))
      let suffixWord := mload(suffix)

      // Copy last word, overwrites after array 
      mstore(add(a, n), mload(add(offset, i)))

      // Restore after array
      mstore(suffix, suffixWord)

      newIndex := add(index, size)
    }

    require(newIndex <= data.length, "LibBytes#readBytes: OUT_OF_BOUNDS");
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;


abstract contract IModuleAuth {
  /**
   * @notice Hashed _data to be signed
   * @param _digest Pre-final digest
   * @return hashed data for this wallet
   */
  function _subDigest(
    bytes32 _digest
  ) internal virtual view returns (bytes32);

  /**
   * @notice Verify if signer is default wallet owner
   * @param _hash Hashed signed message
   * @param _signature Encoded signature
   * @return True is the signature is valid
   */
  function _signatureValidation(
    bytes32 _hash,
    bytes memory _signature
  ) internal virtual view returns (bool);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;


abstract contract ModuleERC165 {
  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @dev Adding new hooks will not lead to them being reported by this function
   *      without upgrading the wallet. In addition, developpers must ensure that 
   *      all inherited contracts by the mainmodule don't conflict and are accounted
   *      to be supported by the supportsInterface method.
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) virtual public pure returns (bool) {
    return _interfaceID == this.supportsInterface.selector;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;


interface IModuleHooks {
  /**
   * @notice Reads the implementation hook of a signature
   * @param _signature Signature function
   * @return The address of the implementation hook, address(0) if none
  */
  function readHook(bytes4 _signature) external view returns (address);

  /**
   * @notice Adds a new hook to handle a given function selector
   * @param _signature Signature function linked to the hook
   * @param _implementation Hook implementation contract
   */
  function addHook(bytes4 _signature, address _implementation) external;

  /**
   * @notice Removes a registered hook
   * @param _signature Signature function linked to the hook
   */
  function removeHook(bytes4 _signature) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;


contract ModuleSelfAuth {
  modifier onlySelf() {
    require(msg.sender == address(this), "ModuleSelfAuth#onlySelf: NOT_AUTHORIZED");
    _;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;


library ModuleStorage {
  function writeBytes32(bytes32 _key, bytes32 _val) internal {
    assembly { sstore(_key, _val) }
  }

  function readBytes32(bytes32 _key) internal view returns (bytes32 val) {
    assembly { val := sload(_key) }
  }

  function writeBytes32Map(bytes32 _key, bytes32 _subKey, bytes32 _val) internal {
    bytes32 key = keccak256(abi.encode(_key, _subKey));
    assembly { sstore(key, _val) }
  }

  function readBytes32Map(bytes32 _key, bytes32 _subKey) internal view returns (bytes32 val) {
    bytes32 key = keccak256(abi.encode(_key, _subKey));
    assembly { val := sload(key) }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;


interface IERC223Receiver {
  function tokenFallback(address, uint256, bytes calldata) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;


interface IModuleCalls {
  // Events
  event NonceChange(uint256 _space, uint256 _newNonce);
  event TxFailed(bytes32 _tx, bytes _reason);
  event TxExecuted(bytes32 _tx) anonymous;

  // Transaction structure
  struct Transaction {
    bool delegateCall;   // Performs delegatecall
    bool revertOnError;  // Reverts transaction bundle if tx fails
    uint256 gasLimit;    // Maximum gas to be forwarded
    address target;      // Address of the contract to call
    uint256 value;       // Amount of ETH to pass with the call
    bytes data;          // calldata to pass
  }

  /**
   * @notice Returns the next nonce of the default nonce space
   * @dev The default nonce space is 0x00
   * @return The next nonce
   */
  function nonce() external view returns (uint256);

  /**
   * @notice Returns the next nonce of the given nonce space
   * @param _space Nonce space, each space keeps an independent nonce count
   * @return The next nonce
   */
  function readNonce(uint256 _space) external view returns (uint256);

  /**
   * @notice Allow wallet owner to execute an action
   * @param _txs        Transactions to process
   * @param _nonce      Signature nonce (may contain an encoded space)
   * @param _signature  Encoded signature
   */
  function execute(
    Transaction[] calldata _txs,
    uint256 _nonce,
    bytes calldata _signature
  ) external;

  /**
   * @notice Allow wallet to execute an action
   *   without signing the message
   * @param _txs  Transactions to execute
   */
  function selfExecute(
    Transaction[] calldata _txs
  ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;


interface IModuleUpdate {
  /**
   * @notice Updates the implementation of the base wallet
   * @param _implementation New main module implementation
   * @dev WARNING Updating the implementation can brick the wallet
   */
  function updateImplementation(address _implementation) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;


library LibAddress {
  /**
   * @notice Will return true if provided address is a contract
   * @param account Address to verify if contract or not
   * @dev This contract will return false if called within the constructor of
   *      a contract's deployment, as the code is not yet stored on-chain.
   */
  function isContract(address account) internal view returns (bool) {
    uint256 csize;
    // solhint-disable-next-line no-inline-assembly
    assembly { csize := extcodesize(account) }
    return csize != 0;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;


interface IModuleCreator {
  /**
   * @notice Creates a contract forwarding eth value
   * @param _code Creation code of the contract
   * @return addr The address of the created contract
   */
  function createContract(bytes calldata _code) external payable returns (address addr);
}