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

pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: MIT
import "@umb-network/toolbox/dist/contracts/IRegistry.sol";
import "@umb-network/toolbox/dist/contracts/IChain.sol";


contract UMBL2Bridge {
  struct L2Value {
    uint256 value;
    uint256 timestamp;
  }

  mapping(bytes32 => L2Value) _currentValues;
  IRegistry contractRegistry = IRegistry(0x059FDd69e771645fe91d8E1040320DbB845cEaFd);

  event DataRequest(
    address indexed sender,
    bytes32 indexed key
  );

  event DataUpdated(
    bytes32 indexed key,
    uint256 value,
    uint256 timestamp
  );

  function getCurrentValue(bytes32 _key) public view returns (uint256 value, uint256 timestamp) {
    L2Value storage currentValue = _currentValues[_key];
    return (currentValue.value, currentValue.timestamp);
  }

  function getChainContract() public view returns (IChain) {
    return IChain(contractRegistry.getAddressByString("Chain"));
  }

  function getOnchainValueOrL2Value(bytes32 _key) public view returns (uint256 value, uint256 timestamp) {
    (uint256 val, uint256 ts) = getChainContract().getCurrentValue(_key);
    if (val == 0) {
      (uint256 _value, uint256 _timestamp) = getCurrentValue(_key);
      return (_value, _timestamp);
    }
    else {
      return (val, ts);
    }
  }

  function updateCurrentValue(
    uint256 _blockId,
    bytes32[] memory _proof,
    bytes memory _key,
    bytes memory _value,
    uint256 timestamp
  ) public {
    bool isValid = getChainContract().verifyProofForBlock(_blockId, _proof, _key, _value);

    bytes32 bytes32key;
    bytes32 bytes32value;

    assembly {
      bytes32key := mload(add(_key, 32))
      bytes32value := mload(add(_value, 32))
    }

    uint256 _decodedValue = uint256(bytes32value);
    require(isValid, "not a valid value");
    _currentValues[bytes32key] = L2Value(_decodedValue, timestamp);
    emit DataUpdated(bytes32key, _decodedValue, timestamp);
  }

  function reqeustL2Data(bytes32 _key) public {
    emit DataRequest(msg.sender, _key);
  }
}