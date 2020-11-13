// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/// Know more: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/EnumerableSet.sol

library EnumerableSet {
  struct Set {
    bytes32[] _values;
    mapping (bytes32 => uint256) _indexes;
  }

  function _add(
    Set storage set,
    bytes32 value
  ) private returns (bool) {
    if (!_contains(set, value)) {
      set._values.push(value);
      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  function _remove(
    Set storage set,
    bytes32 value
  ) private returns (bool) {
    uint256 valueIndex = set._indexes[value];

    if (valueIndex != 0) {
      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;
      bytes32 lastvalue = set._values[lastIndex];
      set._values[toDeleteIndex] = lastvalue;
      set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based
      set._values.pop();
      delete set._indexes[value];
      return true;
    } else {
      return false;
    }
  }

  function _contains(
    Set storage set,
    bytes32 value
  ) private view returns (bool) {
    return set._indexes[value] != 0;
  }

  function _length(
    Set storage set
  ) private view returns (uint256) {
    return set._values.length;
  }

  function _at(
    Set storage set,
    uint256 index
  ) private view returns (bytes32) {
    require(set._values.length > index, "EnumerableSet: index out of bounds");
    return set._values[index];
  }

  struct AddressSet {
    Set _inner;
  }

  function add(
    AddressSet storage set,
    address value
  ) internal returns (bool) {
    return _add(set._inner, bytes32(uint256(value)));
  }

  function remove(
    AddressSet storage set,
    address value
  ) internal returns (bool) {
    return _remove(set._inner, bytes32(uint256(value)));
  }

  function contains(
    AddressSet storage set,
    address value
  ) internal view returns (bool) {
    return _contains(set._inner, bytes32(uint256(value)));
  }

  function length(
    AddressSet storage set
  ) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(
    AddressSet storage set,
    uint256 index
  ) internal view returns (address) {
    return address(uint256(_at(set._inner, index)));
  }

  struct UintSet {
    Set _inner;
  }

  function add(
    UintSet storage set,
    uint256 value
  ) internal returns (bool) {
    return _add(set._inner, bytes32(value));
  }

  function remove(
    UintSet storage set,
    uint256 value
  ) internal returns (bool) {
    return _remove(set._inner, bytes32(value));
  }

  function contains(
    UintSet storage set,
    uint256 value
  ) internal view returns (bool) {
    return _contains(set._inner, bytes32(value));
  }

  function length(
    UintSet storage set
  ) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(
    UintSet storage set,
    uint256 index
  ) internal view returns (uint256) {
    return uint256(_at(set._inner, index));
  }
}