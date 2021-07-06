// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;
import "../interfaces/IStore.sol";

contract FakeStore is IStore {
  mapping(bytes32 => int256) public intStorage;
  mapping(bytes32 => uint256) public uintStorage;
  mapping(bytes32 => uint256[]) public uintsStorage;
  mapping(bytes32 => address) public addressStorage;
  mapping(bytes32 => string) public stringStorage;
  mapping(bytes32 => bytes) public bytesStorage;
  mapping(bytes32 => bytes32) public bytes32Storage;
  mapping(bytes32 => bool) public boolStorage;

  function setAddress(bytes32 k, address v) external override {
    addressStorage[k] = v;
  }

  function setUint(bytes32 k, uint256 v) external override {
    uintStorage[k] = v;
  }

  function addUint(bytes32 k, uint256 v) external override {
    uint256 existing = uintStorage[k];
    uintStorage[k] = existing + v;
  }

  function subtractUint(bytes32 k, uint256 v) external override {
    uint256 existing = uintStorage[k];
    uintStorage[k] = existing - v;
  }

  function setUints(bytes32 k, uint256[] memory v) external override {
    uintsStorage[k] = v;
  }

  function setString(bytes32 k, string calldata v) external override {
    stringStorage[k] = v;
  }

  function setBytes(bytes32 k, bytes calldata v) external override {
    bytesStorage[k] = v;
  }

  function setBool(bytes32 k, bool v) external override {
    if (v) {
      boolStorage[k] = v;
    }
  }

  function setInt(bytes32 k, int256 v) external override {
    intStorage[k] = v;
  }

  function setBytes32(bytes32 k, bytes32 v) external override {
    bytes32Storage[k] = v;
  }

  function deleteAddress(bytes32 k) external override {
    delete addressStorage[k];
  }

  function deleteUint(bytes32 k) external override {
    delete uintStorage[k];
  }

  function deleteUints(bytes32 k) external override {
    delete uintsStorage[k];
  }

  function deleteString(bytes32 k) external override {
    delete stringStorage[k];
  }

  function deleteBytes(bytes32 k) external override {
    delete bytesStorage[k];
  }

  function deleteBool(bytes32 k) external override {
    delete boolStorage[k];
  }

  function deleteInt(bytes32 k) external override {
    delete intStorage[k];
  }

  function deleteBytes32(bytes32 k) external override {
    delete bytes32Storage[k];
  }

  function getAddress(bytes32 k) external view override returns (address) {
    return addressStorage[k];
  }

  function getUint(bytes32 k) external view override returns (uint256) {
    return uintStorage[k];
  }

  function getUints(bytes32 k) external view override returns (uint256[] memory) {
    return uintsStorage[k];
  }

  function getString(bytes32 k) external view override returns (string memory) {
    return stringStorage[k];
  }

  function getBytes(bytes32 k) external view override returns (bytes memory) {
    return bytesStorage[k];
  }

  function getBool(bytes32 k) external view override returns (bool) {
    return boolStorage[k];
  }

  function getInt(bytes32 k) external view override returns (int256) {
    return intStorage[k];
  }

  function getBytes32(bytes32 k) external view override returns (bytes32) {
    return bytes32Storage[k];
  }
}

// Neptune Mutual Protocol (https://neptunemutual.com)
// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.4.22 <0.9.0;

interface IStore {
  function setAddress(bytes32 k, address v) external;

  function setUint(bytes32 k, uint256 v) external;

  function addUint(bytes32 k, uint256 v) external;

  function subtractUint(bytes32 k, uint256 v) external;

  function setUints(bytes32 k, uint256[] memory v) external;

  function setString(bytes32 k, string calldata v) external;

  function setBytes(bytes32 k, bytes calldata v) external;

  function setBool(bytes32 k, bool v) external;

  function setInt(bytes32 k, int256 v) external;

  function setBytes32(bytes32 k, bytes32 v) external;

  function deleteAddress(bytes32 k) external;

  function deleteUint(bytes32 k) external;

  function deleteUints(bytes32 k) external;

  function deleteString(bytes32 k) external;

  function deleteBytes(bytes32 k) external;

  function deleteBool(bytes32 k) external;

  function deleteInt(bytes32 k) external;

  function deleteBytes32(bytes32 k) external;

  function getAddress(bytes32 k) external view returns (address);

  function getUint(bytes32 k) external view returns (uint256);

  function getUints(bytes32 k) external view returns (uint256[] memory);

  function getString(bytes32 k) external view returns (string memory);

  function getBytes(bytes32 k) external view returns (bytes memory);

  function getBool(bytes32 k) external view returns (bool);

  function getInt(bytes32 k) external view returns (int256);

  function getBytes32(bytes32 k) external view returns (bytes32);
}