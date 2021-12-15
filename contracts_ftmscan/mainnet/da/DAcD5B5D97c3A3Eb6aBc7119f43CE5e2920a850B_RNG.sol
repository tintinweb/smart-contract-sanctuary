/**
 *Submitted for verification at FtmScan.com on 2021-12-15
*/

// Dependency file: contracts/interfaces/IRegistry.sol

// SPDX-License-Identifier: Apache-2.0
// pragma solidity >=0.8.4 <0.9.0;

interface IRegistry {
  event Registered(bytes32 domain, bytes32 indexed name, address indexed addr);

  function isExistRecord(bytes32 domain, bytes32 name) external view returns (bool);

  function set(
    bytes32 domain,
    bytes32 name,
    address addr
  ) external returns (bool);

  function batchSet(
    bytes32[] calldata domains,
    bytes32[] calldata names,
    address[] calldata addrs
  ) external returns (bool);

  function getAddress(bytes32 domain, bytes32 name) external view returns (address);

  function getDomainAndName(address addr) external view returns (bytes32, bytes32);
}


// Dependency file: contracts/libraries/RegistryUser.sol

// pragma solidity >=0.8.4 <0.9.0;

// import 'contracts/interfaces/IRegistry.sol';

abstract contract RegistryUser {
  // Registry contract
  IRegistry internal _registry;

  // Active domain
  bytes32 internal _domain;

  // Initialized
  bool private _initialized = false;

  // Allow same domain calls
  modifier onlyAllowSameDomain(bytes32 name) {
    require(msg.sender == _registry.getAddress(_domain, name), 'UserRegistry: Only allow call from same domain');
    _;
  }

  // Allow cross domain call
  modifier onlyAllowCrossDomain(bytes32 fromDomain, bytes32 name) {
    require(
      msg.sender == _registry.getAddress(fromDomain, name),
      'UserRegistry: Only allow call from allowed cross domain'
    );
    _;
  }

  /*******************************************************
   * Internal section
   ********************************************************/

  // Constructing with registry address and its active domain
  function _registryUserInit(address registry_, bytes32 domain_) internal returns (bool) {
    require(!_initialized, "UserRegistry: It's only able to initialize once");
    _registry = IRegistry(registry_);
    _domain = domain_;
    _initialized = true;
    return true;
  }

  // Get address in the same domain
  function _getAddressSameDomain(bytes32 name) internal view returns (address) {
    return _registry.getAddress(_domain, name);
  }

  /*******************************************************
   * View section
   ********************************************************/

  // Return active domain
  function getDomain() external view returns (bytes32) {
    return _domain;
  }

  // Return registry address
  function getRegistry() external view returns (address) {
    return address(_registry);
  }
}


// Dependency file: contracts/libraries/Bytes.sol

// pragma solidity >=0.8.4 <0.9.0;

library Bytes {
  // Convert bytes to bytes32[]
  function toBytes32Array(bytes memory input) public pure returns (bytes32[] memory) {
    require(input.length % 32 == 0, 'Bytes: invalid data length should divied by 32');
    bytes32[] memory result = new bytes32[](input.length / 32);
    assembly {
      // Read length of data from offset
      let length := mload(input)

      // Seek offset to the beginning
      let offset := add(input, 0x20)

      // Next is size of chunk
      let resultOffset := add(result, 0x20)

      for {
        let i := 0
      } lt(i, length) {
        i := add(i, 0x20)
      } {
        mstore(resultOffset, mload(add(offset, i)))
        resultOffset := add(resultOffset, 0x20)
      }
    }
    return result;
  }

  // Read address from input bytes buffer
  function readAddress(bytes memory input, uint256 offset) public pure returns (address result) {
    require(offset + 20 <= input.length, 'Bytes: Out of range, can not read address from bytes');
    assembly {
      result := shr(96, mload(add(add(input, 0x20), offset)))
    }
  }

  // Read uint256 from input bytes buffer
  function readUint256(bytes memory input, uint256 offset) public pure returns (uint256 result) {
    require(offset + 32 <= input.length, 'Bytes: Out of range, can not read uint256 from bytes');
    assembly {
      result := mload(add(add(input, 0x20), offset))
    }
  }

  // Read bytes from input bytes buffer
  function readBytes(
    bytes memory input,
    uint256 offset,
    uint256 length
  ) public pure returns (bytes memory) {
    require(offset + length <= input.length, 'Bytes: Out of range, can not read bytes from bytes');
    bytes memory result = new bytes(length);
    assembly {
      // Seek offset to the beginning
      let seek := add(add(input, 0x20), offset)

      // Next is size of data
      let resultOffset := add(result, 0x20)

      for {
        let i := 0
      } lt(i, length) {
        i := add(i, 0x20)
      } {
        mstore(add(resultOffset, i), mload(add(seek, i)))
      }
    }
    return result;
  }
}


// Dependency file: contracts/interfaces/IRNGConsumer.sol

// pragma solidity >=0.8.4 <0.9.0;

interface IRNGConsumer {
  function compute(bytes memory data) external returns (bool);
}


// Root file: contracts/infrastructure/RNG.sol


pragma solidity >=0.8.4 <0.9.0;

// import 'contracts/libraries/RegistryUser.sol';
// import 'contracts/libraries/Bytes.sol';
// import 'contracts/interfaces/IRNGConsumer.sol';

/**
 * Random Number Generator
 * Name: RNG
 * Domain: Infrastructure
 */
contract RNG is RegistryUser {
  // Use bytes lib for bytes
  using Bytes for bytes;

  // Commit scheme data
  struct CommitSchemeData {
    uint256 index;
    bytes32 digest;
    bytes32 secret;
  }

  // Commit scheme progess
  struct CommitSchemeProgress {
    uint256 remaining;
    uint256 total;
  }

  // Total committed digest
  uint256 private totalDigest;

  uint256 private remainingDigest;

  // Secret digests map
  mapping(uint256 => bytes32) private secretDigests;

  // Reverted digiest map
  mapping(bytes32 => uint256) private digestIndexs;

  // Secret storage
  mapping(uint256 => bytes32) private secretValues;

  // Commit event
  event Committed(uint256 indexed index, bytes32 indexed digest);

  // Reveal event
  event Revealed(uint256 indexed index, uint256 indexed s, uint256 indexed t);

  // Pass constructor parameter to User
  constructor(address registry_, bytes32 domain_) {
    _registryUserInit(registry_, domain_);
  }

  /*******************************************************
   * Oracle section
   ********************************************************/

  // DKDAO Oracle will commit H(S||t) to blockchain
  function commit(bytes32 digest) external onlyAllowSameDomain('Oracle') returns (uint256) {
    return _commit(digest);
  }

  // Allow Oracle to commit multiple values to blockchain
  function batchCommit(bytes calldata digest) external onlyAllowSameDomain('Oracle') returns (bool) {
    bytes32[] memory digestList = digest.toBytes32Array();
    for (uint256 i = 0; i < digestList.length; i += 1) {
      require(_commit(digestList[i]) > 0, 'RNG: Unable to add digest to blockchain');
    }
    return true;
  }

  // DKDAO Oracle will reveal S and t
  function reveal(bytes memory data) external onlyAllowSameDomain('Oracle') returns (uint256) {
    require(data.length >= 84, 'RNG: Input data has wrong format');
    address target = data.readAddress(0);
    uint256 index = data.readUint256(20);
    uint256 secret = data.readUint256(52);
    uint256 s;
    uint256 t;
    remainingDigest -= 1;
    t = secret & 0xffffffffffffffff;
    s = secret >> 64;
    // Make sure that this secret is valid
    require(secretValues[index] == bytes32(''), 'Rng: This secret was revealed');
    require(keccak256(abi.encodePacked(secret)) == secretDigests[index], "Rng: Secret doesn't match digest");
    secretValues[index] = bytes32(secret);
    // Increase last reveal value
    // Hook call to fair distribution
    if (target != address(0x00)) {
      require(
        IRNGConsumer(target).compute(data.readBytes(52, data.length - 52)),
        "RNG: Can't do callback to distributor"
      );
    }
    emit Revealed(index, s, t);
    return index;
  }

  /*******************************************************
   * Private section
   ********************************************************/

  // Commit digest to blockchain state
  function _commit(bytes32 digest) private returns (uint256) {
    // We begin from 1 instead of 0 to prevent error
    totalDigest += 1;
    remainingDigest += 1;
    secretDigests[totalDigest] = digest;
    digestIndexs[digest] = totalDigest;
    emit Committed(totalDigest, digest);
    return totalDigest;
  }

  /*******************************************************
   * View section
   ********************************************************/

  // Get progress of commit scheme
  function getDataByIndex(uint256 index) external view returns (CommitSchemeData memory) {
    return CommitSchemeData({ index: index, digest: secretDigests[index], secret: secretValues[index] });
  }

  // Get progress of commit scheme
  function getDataByDigest(bytes32 digest) external view returns (CommitSchemeData memory) {
    uint256 index = digestIndexs[digest];
    return CommitSchemeData({ index: index, digest: secretDigests[index], secret: secretValues[index] });
  }

  // Get progress of commit scheme
  function getProgress() external view returns (CommitSchemeProgress memory) {
    return CommitSchemeProgress({ remaining: remainingDigest, total: totalDigest });
  }
}