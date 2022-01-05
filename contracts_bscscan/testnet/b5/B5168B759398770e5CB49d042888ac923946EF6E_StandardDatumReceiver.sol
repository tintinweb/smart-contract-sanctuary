// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "@umb-network/toolbox/dist/contracts/IChain.sol";
import "@umb-network/toolbox/dist/contracts/IRegistry.sol";
import "@umb-network/toolbox/dist/contracts/lib/ValueDecoder.sol";
import "./interfaces/IDatumReceiver.sol";

/// @title Datum Receiver example implementation
/// @notice This is only an example implementation, and can be entirely rewriten 
/// by the needs of the consumer as long as it uses the IDatumReceiver interface. 
contract StandardDatumReceiver is IDatumReceiver {
  using ValueDecoder for bytes;

  IRegistry public immutable contractRegistry;

  uint32 public timestamp;
  bytes32 public key;
  bytes32 public value;
  bytes32 public lastUpdateHash;
  bytes32 public datumRegistry = bytes32("DatumRegistry");

  /// @notice Makes sure the caller is a trusted source, like DatumRegistry
  modifier onlyFromDatumRegistry(address _msgSender) {
    require(
      contractRegistry.getAddress(datumRegistry) == _msgSender,
        string(abi.encodePacked("caller is not ", datumRegistry))
    );
    _;
  }

  constructor(address _contractRegistry) {
    contractRegistry = IRegistry(_contractRegistry);
  }

  /// @notice Apply the rules of storage or data usage here. In this case it
  /// checks if the received data is stored and if not, stores it. 
  function receivePallet(Pallet calldata _pallet) 
    external virtual override onlyFromDatumRegistry(msg.sender) {
    IChain oracle = IChain(contractRegistry.getAddressByString("Chain"));
    IChain.Block memory _block = oracle.blocks(_pallet.blockId);

    bytes32 thisUpdateHash = keccak256(abi.encodePacked(_block.dataTimestamp, _pallet.key));
    require(lastUpdateHash != thisUpdateHash, "update already received");

    key = _pallet.key;
    value = _pallet.value;
    timestamp = _block.dataTimestamp;
    lastUpdateHash = thisUpdateHash;
  }

  /// @notice This function shall be view and will be called with a staticcall 
  /// so receiver can preview the content and decide if you wanna pay for it.
  function approvePallet(Pallet calldata _pallet) external view virtual override returns (bool) {
    IChain oracle = IChain(contractRegistry.getAddressByString("Chain"));
    IChain.Block memory _block = oracle.blocks(_pallet.blockId);

    require(_block.dataTimestamp > timestamp, "provided block id is older than the last information stored");

    return true;  
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;
pragma abicoder v2;

interface IChain {
  struct Block {
    bytes32 root;
    uint32 dataTimestamp;
  }

  struct FirstClassData {
    uint224 value;
    uint32 dataTimestamp;
  }

  function isForeign() external pure returns (bool);

  function blocks(uint256) external view returns (Block memory);

  function fcds(bytes32) external view returns (FirstClassData memory);

  function blocksCount() external view returns (uint32);

  function blocksCountOffset() external view returns (uint32);

  function padding() external view returns (uint16);

  function getName() external pure returns (bytes32);

  function recoverSigner(bytes32 affidavit, uint8 _v, bytes32 _r, bytes32 _s) external pure returns (address);

  function getStatus() external view returns(
    uint256 blockNumber,
    uint16 timePadding,
    uint32 lastDataTimestamp,
    uint32 lastBlockId,
    address nextLeader,
    uint32 nextBlockId,
    address[] memory validators,
    uint256[] memory powers,
    string[] memory locations,
    uint256 staked
  );

  function getBlockId() external view returns (uint32);

  // this function does not works for past timestamps
  function getBlockIdAtTimestamp(uint256 _timestamp) external view returns (uint32);

  function getLatestBlockId() external view returns (uint32);

  function getLeaderIndex(uint256 _numberOfValidators, uint256 _timestamp) external view returns (uint256);

  function getNextLeaderAddress() external view returns (address);

  function getLeaderAddress() external view returns (address);

  function getLeaderAddressAtTime(uint232 _timestamp) external view returns (address);

  function hashLeaf(bytes calldata _key, bytes calldata _value) external pure returns (bytes32);

  function verifyProof(bytes32[] calldata _proof, bytes32 _root, bytes32 _leaf) external pure returns (bool);

  function verifyProofForBlock(
    uint256 _blockId,
    bytes32[] calldata _proof,
    bytes calldata _key,
    bytes calldata _value
  ) external view returns (bool);

  function bytesToBytes32Array(
    bytes calldata _data,
    uint256 _offset,
    uint256 _items
  ) external pure returns (bytes32[] memory);

  function verifyProofs(
    uint32[] memory _blockIds,
    bytes memory _proofs,
    uint256[] memory _proofItemsCounter,
    bytes32[] memory _leaves
  ) external view returns (bool[] memory results);
  
  function getBlockRoot(uint256 _blockId) external view returns (bytes32);

  function getBlockTimestamp(uint32 _blockId) external view returns (uint32);

  function getCurrentValues(bytes32[] calldata _keys)
  external view returns (uint256[] memory values, uint32[] memory timestamps);

  function getCurrentValue(bytes32 _key) external view returns (uint256 value, uint256 timestamp);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.8;

interface IRegistry {
  function registry(bytes32 _name) external view returns (address);

  function requireAndGetAddress(bytes32 _name) external view returns (address);

  function getAddress(bytes32 _bytes) external view returns (address);

  function getAddressByString(string memory _name) external view returns (address);

  function stringToBytes32(string memory _string) external pure returns (bytes32);
}

//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.6.8;

library ValueDecoder {
  function toUint(bytes memory _bytes) internal pure returns (uint256 value) {
    assembly {
      value := mload(add(_bytes, 32))
    }
  }

  function toUint(bytes32 _bytes) internal pure returns (uint256 value) {
    assembly {
      value := _bytes
    }
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "../lib/PassportStructs.sol";

interface IDatumReceiver {
  /// @notice This function will hold the parameters or business rules that consumer
  /// wants to do with the received data structure, here called Pallet.
  /// @param _pallet the structure sent by DatumRegistry, containing proof, key and value
  function receivePallet(Pallet calldata _pallet) external;

  /// @notice This function holds rules that consumer may need to check before accepting
  /// the Pallet. Rules like how old is the block, or how many blocks have passed since 
  /// last storage. Deliverer will check if approvePallet reverted this call or returned true.
  /// @param _pallet The exact same Pallet that will arrive at the receivePallet endpoint.
  /// @return true if wants pallet or should REVERT if Contract does not want the pallet.
  /// @dev DO NOT RETURN false.
  function approvePallet(Pallet calldata _pallet) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

struct Datum {
  address receiver;
  bytes32[] keys;
  uint256 balance;
  address funder;
  bool enabled;
}

struct Pallet {
  uint32 blockId;
  bytes32 key;
  bytes32 value;
  bytes32[] proof; 
}

struct Delivery {
  bytes32 datumId;
  uint16[] indexes; // TODO we never use this struck in storage, so let's use uint256[]
}