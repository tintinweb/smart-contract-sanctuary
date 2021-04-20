// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./MultiCallUtils.sol";
import "./RequireUtils.sol";


contract SequenceUtils is 
  MultiCallUtils,
  RequireUtils
{
  constructor(
    address _factory,
    address _mainModule
  ) RequireUtils(
    _factory,
    _mainModule
  ) {}
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../commons/interfaces/IModuleCalls.sol";


contract MultiCallUtils {
  function multiCall(
    IModuleCalls.Transaction[] memory _txs
  ) public payable returns (
    bool[] memory _successes,
    bytes[] memory _results
  ) {
    _successes = new bool[](_txs.length);
    _results = new bytes[](_txs.length);

    for (uint256 i = 0; i < _txs.length; i++) {
      IModuleCalls.Transaction memory transaction = _txs[i];

      require(!transaction.delegateCall, 'MultiCallUtils#multiCall: delegateCall not allowed');
      require(gasleft() >= transaction.gasLimit, "MultiCallUtils#multiCall: NOT_ENOUGH_GAS");

      // solhint-disable
      (_successes[i], _results[i]) = transaction.target.call{
        value: transaction.value,
        gas: transaction.gasLimit == 0 ? gasleft() : transaction.gasLimit
      }(transaction.data);
      // solhint-enable

      require(_successes[i] || !_txs[i].revertOnError, 'MultiCallUtils#multiCall: CALL_REVERTED');
    }
  }

  // ///
  // Globals
  // ///

  function callBlockhash(uint256 _i) external view returns (bytes32) {
    return blockhash(_i);
  }

  function callCoinbase() external view returns (address) {
    return block.coinbase;
  }

  function callDifficulty() external view returns (uint256) {
    return block.difficulty;
  }

  function callGasLimit() external view returns (uint256) {
    return block.gaslimit;
  }

  function callBlockNumber() external view returns (uint256) {
    return block.gaslimit;
  }

  function callTimestamp() external view returns (uint256) {
    return block.timestamp;
  }

  function callGasLeft() external view returns (uint256) {
    return gasleft();
  }

  function callGasPrice() external view returns (uint256) {
    return tx.gasprice;
  }

  function callOrigin() external view returns (address) {
    return tx.origin;
  }

  function callBalanceOf(address _addr) external view returns (uint256) {
    return _addr.balance;
  }

  function callCodeSize(address _addr) external view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  function callCode(address _addr) external view returns (bytes memory code) {
    assembly {
      let size := extcodesize(_addr)
      code := mload(0x40)
      mstore(0x40, add(code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
      mstore(code, size)
      extcodecopy(_addr, add(code, 0x20), 0, size)
    }
  }

  function callCodeHash(address _addr) external view returns (bytes32 codeHash) {
    assembly { codeHash := extcodehash(_addr) }
  }

  function callChainId() external pure returns (uint256 id) {
    assembly { id := chainid() }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../commons/interfaces/IModuleCalls.sol";
import "../commons/interfaces/IModuleAuthUpgradable.sol";
import "../../interfaces/IERC1271Wallet.sol";
import "../../utils/SignatureValidator.sol";
import "../../utils/LibBytes.sol";
import "../../Wallet.sol";

contract RequireUtils is SignatureValidator {
  using LibBytes for bytes;

  uint256 private constant NONCE_BITS = 96;
  bytes32 private constant NONCE_MASK = bytes32((1 << NONCE_BITS) - 1);

  uint256 private constant FLAG_SIGNATURE = 0;
  uint256 private constant FLAG_ADDRESS = 1;
  uint256 private constant FLAG_DYNAMIC_SIGNATURE = 2;

  bytes32 private immutable INIT_CODE_HASH;
  address private immutable FACTORY;

  struct Member {
    uint256 weight;
    address signer;
  }

  event RequiredConfig(
    address indexed _wallet,
    bytes32 indexed _imageHash,
    uint256 _threshold,
    bytes _signers
  );

  event RequiredSigner(
    address indexed _wallet,
    address indexed _signer
  );

  mapping(address => uint256) public lastSignerUpdate;
  mapping(address => uint256) public lastWalletUpdate;
  mapping(address => bytes32) public knownImageHashes;
  mapping(bytes32 => uint256) public lastImageHashUpdate;

  constructor(address _factory, address _mainModule) public {
    FACTORY = _factory;
    INIT_CODE_HASH = keccak256(abi.encodePacked(Wallet.creationCode, uint256(_mainModule)));
  }

  /**
   * @notice Publishes the current configuration of a Sequence wallets using logs
   * @dev Used for fast lookup of a wallet configuration based on its image-hash, compatible with updated and counter-factual wallets.
   *
   * @param _wallet      Sequence wallet
   * @param _threshold   Thershold of the current configuration
   * @param _members     Members of the current configuration
   * @param _index       True if an index in contract-storage is desired 
   */
  function publishConfig(
    address _wallet,
    uint256 _threshold,
    Member[] calldata _members,
    bool _index
  ) external {
    // Compute expected imageHash
    bytes32 imageHash = bytes32(uint256(_threshold));
    for (uint256 i = 0; i < _members.length; i++) {
      imageHash = keccak256(abi.encode(imageHash, _members[i].weight, _members[i].signer));
    }

    // Check against wallet imageHash
    (bool succeed, bytes memory data) = _wallet.call(abi.encodePacked(IModuleAuthUpgradable(_wallet).imageHash.selector));
    if (succeed && data.length == 32) {
      // Check contract defined
      bytes32 currentImageHash = abi.decode(data, (bytes32));
      require(currentImageHash == imageHash, "RequireUtils#publishConfig: UNEXPECTED_IMAGE_HASH");
    } else {
      // Check counter-factual
      require(address(
        uint256(
          keccak256(
            abi.encodePacked(
              byte(0xff),
              FACTORY,
              imageHash,
              INIT_CODE_HASH
            )
          )
        )
      ) == _wallet, "RequireUtils#publishConfig: UNEXPECTED_COUNTERFACTUAL_IMAGE_HASH");

      // Register known image-hash for counter-factual wallet
      if (_index) knownImageHashes[_wallet] = imageHash;
    }

    // Emit event for easy config retrieval
    emit RequiredConfig(_wallet, imageHash, _threshold, abi.encode(_members));

    if (_index) {
      // Register last event for given wallet
      lastWalletUpdate[_wallet] = block.number;

      // Register last event for image-hash
      lastImageHashUpdate[imageHash] = block.number;
    }
  }

  /**
   * @notice Publishes the configuration and set of signers for a counter-factual Sequence wallets using logs
   * @dev Used for fast lookup of a wallet based on its signer members, only signing members are included in the logs
   *   as a mechanism to avoid poisoning of the directory of wallets.
   *
   *   Only the initial counter-factual configuration can be published, to publish updated configurations see `publishConfig`.
   *
   * @param _wallet      Sequence wallet
   * @param _hash        Any hash signed by the wallet
   * @param _sizeMembers Number of members on the counter-factual configuration
   * @param _signature   Signature for the given hash
   * @param _index       True if an index in contract-storage is desired 
   */
  function publishInitialSigners(
    address _wallet,
    bytes32 _hash,
    uint256 _sizeMembers,
    bytes memory _signature,
    bool _index
  ) external {
    // Decode and index signature
    (
      uint16 threshold,  // required threshold signature
      uint256 rindex     // read index
    ) = _signature.readFirstUint16();

    // Generate sub-digest
    bytes32 subDigest; {
      uint256 chainId; assembly { chainId := chainid() }
      subDigest = keccak256(
        abi.encodePacked(
          "\x19\x01",
          chainId,
          _wallet,
          _hash
        )
      );
    }

    // Recover signature
    bytes32 imageHash = bytes32(uint256(threshold));

    Member[] memory members = new Member[](_sizeMembers);
    uint256 membersIndex = 0;

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
        addr = recoverSigner(subDigest, signature);

        // Publish signer
        _publishSigner(_wallet, addr, _index);
      } else if (flag == FLAG_DYNAMIC_SIGNATURE) {
        // Read signer
        (addr, rindex) = _signature.readAddress(rindex);

        {
          // Read signature size
          uint256 size;
          (size, rindex) = _signature.readUint16(rindex);

          // Read dynamic size signature
          bytes memory signature;
          (signature, rindex) = _signature.readBytes(rindex, size);
          require(isValidSignature(subDigest, addr, signature), "ModuleAuth#_signatureValidation: INVALID_SIGNATURE");
        }

        // Publish signer
        _publishSigner(_wallet, addr, _index);
      } else {
        revert("RequireUtils#publishInitialSigners: INVALID_SIGNATURE_FLAG");
      }

      // Store member on array
      members[membersIndex] = Member(addrWeight, addr);
      membersIndex++;

      // Write weight and address to image
      imageHash = keccak256(abi.encode(imageHash, addrWeight, addr));
    }

    require(membersIndex == _sizeMembers, "RequireUtils#publishInitialSigners: INVALID_MEMBERS_COUNT");

    // Check against counter-factual imageHash
    require(address(
      uint256(
        keccak256(
          abi.encodePacked(
            byte(0xff),
            FACTORY,
            imageHash,
            INIT_CODE_HASH
          )
        )
      )
    ) == _wallet, "RequireUtils#publishInitialSigners: UNEXPECTED_COUNTERFACTUAL_IMAGE_HASH");

    // Emit event for easy config retrieval
    emit RequiredConfig(_wallet, imageHash, threshold, abi.encode(members));

    if (_index) {
      // Register last event for given wallet
      lastWalletUpdate[_wallet] = block.number;

      // Register last event for image-hash
      lastImageHashUpdate[imageHash] = block.number;

      // Register known image-hash for counter-factual wallet
      knownImageHashes[_wallet] = imageHash;
    }
  }

  /**
   * @notice Validates that a given expiration hasn't expired
   * @dev Used as an optional transaction on a Sequence batch, to create expirable transactions.
   *
   * @param _expiration  Expiration to check
   */
  function requireNonExpired(uint256 _expiration) external view {
    require(block.timestamp < _expiration, "RequireUtils#requireNonExpired: EXPIRED");
  }

  /**
   * @notice Validates that a given wallet has reached a given nonce
   * @dev Used as an optional transaction on a Sequence batch, to define transaction execution order
   *
   * @param _wallet Sequence wallet
   * @param _nonce  Required nonce
   */
  function requireMinNonce(address _wallet, uint256 _nonce) external view {
    (uint256 space, uint256 nonce) = _decodeNonce(_nonce);
    uint256 currentNonce = IModuleCalls(_wallet).readNonce(space);
    require(currentNonce >= nonce, "RequireUtils#requireMinNonce: NONCE_BELOW_REQUIRED");
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
   * @notice Publishes a signer that was validated to sign for a particular wallet
   * @param _wallet Address of the wallet
   * @param _signer Address of the signer
   * @param _index True if an index on contract storage is desired
   */
  function _publishSigner(address _wallet, address _signer, bool _index) private {
    // Required signer event
    emit RequiredSigner(_wallet, _signer);

    if (_index) {
      // Register last event for given signer
      lastSignerUpdate[_signer] = block.number;
    }
  }
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


interface IModuleAuthUpgradable {
  /**
   * @notice Updates the signers configuration of the wallet
   * @param _imageHash New required image hash of the signature
   */
  function updateImageHash(bytes32 _imageHash) external;

  /**
   * @notice Returns the current image hash of the wallet
   */
  function imageHash() external view returns (bytes32);
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
    require(_signature.length == 66, "SignatureValidator#recoverSigner: invalid signature length");
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
    assert(newIndex > index);
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
    assert(newIndex > index);
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
    assert(newIndex > index);
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
    assert(newIndex > index);
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

    assert(newIndex >= index);
    require(newIndex <= data.length, "LibBytes#readBytes: OUT_OF_BOUNDS");
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;

/**
    Minimal upgradeable proxy implementation, delegates all calls to the address
    defined by the storage slot matching the wallet address.

    Inspired by EIP-1167 Implementation (https://eips.ethereum.org/EIPS/eip-1167)

    deployed code:

        0x00    0x36         0x36      CALLDATASIZE      cds
        0x01    0x3d         0x3d      RETURNDATASIZE    0 cds
        0x02    0x3d         0x3d      RETURNDATASIZE    0 0 cds
        0x03    0x37         0x37      CALLDATACOPY
        0x04    0x3d         0x3d      RETURNDATASIZE    0
        0x05    0x3d         0x3d      RETURNDATASIZE    0 0
        0x06    0x3d         0x3d      RETURNDATASIZE    0 0 0
        0x07    0x36         0x36      CALLDATASIZE      cds 0 0 0
        0x08    0x3d         0x3d      RETURNDATASIZE    0 cds 0 0 0
        0x09    0x30         0x30      ADDRESS           addr 0 cds 0 0 0
        0x0A    0x54         0x54      SLOAD             imp 0 cds 0 0 0
        0x0B    0x5a         0x5a      GAS               gas imp 0 cds 0 0 0
        0x0C    0xf4         0xf4      DELEGATECALL      suc 0
        0x0D    0x3d         0x3d      RETURNDATASIZE    rds suc 0
        0x0E    0x82         0x82      DUP3              0 rds suc 0
        0x0F    0x80         0x80      DUP1              0 0 rds suc 0
        0x10    0x3e         0x3e      RETURNDATACOPY    suc 0
        0x11    0x90         0x90      SWAP1             0 suc
        0x12    0x3d         0x3d      RETURNDATASIZE    rds 0 suc
        0x13    0x91         0x91      SWAP2             suc 0 rds
        0x14    0x60 0x18    0x6018    PUSH1             0x18 suc 0 rds
    /-- 0x16    0x57         0x57      JUMPI             0 rds
    |   0x17    0xfd         0xfd      REVERT
    \-> 0x18    0x5b         0x5b      JUMPDEST          0 rds
        0x19    0xf3         0xf3      RETURN

    flat deployed code: 0x363d3d373d3d3d363d30545af43d82803e903d91601857fd5bf3

    deploy function:

        0x00    0x60 0x3a    0x603a    PUSH1             0x3a
        0x02    0x60 0x0e    0x600e    PUSH1             0x0e 0x3a
        0x04    0x3d         0x3d      RETURNDATASIZE    0 0x0e 0x3a
        0x05    0x39         0x39      CODECOPY
        0x06    0x60 0x1a    0x601a    PUSH1             0x1a
        0x08    0x80         0x80      DUP1              0x1a 0x1a
        0x09    0x51         0x51      MLOAD             imp 0x1a
        0x0A    0x30         0x30      ADDRESS           addr imp 0x1a
        0x0B    0x55         0x55      SSTORE            0x1a
        0x0C    0x3d         0x3d      RETURNDATASIZE    0 0x1a
        0x0D    0xf3         0xf3      RETURN
        [...deployed code]

    flat deploy function: 0x603a600e3d39601a805130553df3363d3d373d3d3d363d30545af43d82803e903d91601857fd5bf3
*/
library Wallet {
  bytes internal constant creationCode = hex"603a600e3d39601a805130553df3363d3d373d3d3d363d30545af43d82803e903d91601857fd5bf3";
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999,
    "details": {
      "yul": true
    }
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}