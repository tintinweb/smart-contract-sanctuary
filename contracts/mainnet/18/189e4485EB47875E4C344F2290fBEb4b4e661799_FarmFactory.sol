// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.7.0;

library EnumerableSet {
  struct Set {
    bytes32[] _values;
    mapping (bytes32 => uint256) _indexes;
  }

  function _add(Set storage set, bytes32 value) private returns (bool) {
    if (!_contains(set, value)) {
      set._values.push(value);
      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  function _remove(Set storage set, bytes32 value) private returns (bool) {
    uint256 valueIndex = set._indexes[value];
    if (valueIndex != 0) {
      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;
      bytes32 lastvalue = set._values[lastIndex];
      set._values[toDeleteIndex] = lastvalue;
      set._indexes[lastvalue] = toDeleteIndex + 1;
      set._values.pop();
      delete set._indexes[value];
      return true;
    } else {
      return false;
    }
  }

  function _contains(Set storage set, bytes32 value) private view returns (bool) {
    return set._indexes[value] != 0;
  }

  function _length(Set storage set) private view returns (uint256) {
    return set._values.length;
  }

  function _at(Set storage set, uint256 index) private view returns (bytes32) {
    require(set._values.length > index, "EnumerableSet: index out of bounds");
    return set._values[index];
  }

  struct AddressSet {
    Set _inner;
  }

  function add(AddressSet storage set, address value) internal returns (bool) {
    return _add(set._inner, bytes32(uint256(value)));
  }

  function remove(AddressSet storage set, address value) internal returns (bool) {
    return _remove(set._inner, bytes32(uint256(value)));
  }

  function contains(AddressSet storage set, address value) internal view returns (bool) {
    return _contains(set._inner, bytes32(uint256(value)));
  }

  function length(AddressSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(AddressSet storage set, uint256 index) internal view returns (address) {
    return address(uint256(_at(set._inner, index)));
  }

  struct UintSet {
    Set _inner;
  }

  function add(UintSet storage set, uint256 value) internal returns (bool) {
    return _add(set._inner, bytes32(value));
  }

  function remove(UintSet storage set, uint256 value) internal returns (bool) {
    return _remove(set._inner, bytes32(value));
  }

  function contains(UintSet storage set, uint256 value) internal view returns (bool) {
    return _contains(set._inner, bytes32(value));
  }

  function length(UintSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  function at(UintSet storage set, uint256 index) internal view returns (uint256) {
    return uint256(_at(set._inner, index));
  }
}

abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }
}

abstract contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }

  function renounceOwnership() public virtual onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


contract FarmFactory is Context, Ownable {
  using EnumerableSet for EnumerableSet.AddressSet;

  EnumerableSet.AddressSet private farms;
  EnumerableSet.AddressSet private farmGenerators;

  mapping (address => EnumerableSet.AddressSet) private userFarms;

  constructor() public { }

  function adminAllowFarmGenerator(address _address, bool _allow) public onlyOwner {
    if (_allow) {
      farmGenerators.add(_address);
    } else {
      farmGenerators.remove(_address);
    }
  }

  /**
   * @notice called by a registered FarmGenerator upon Farm creation
   */
  function registerFarm(address _farmAddress) public {
    require(farmGenerators.contains(_msgSender()), 'FORBIDDEN');
    farms.add(_farmAddress);
  }

  /**
   * @notice Number of allowed FarmGenerators
   */
  function farmGeneratorsLength() external view returns (uint256) {
    return farmGenerators.length();
  }

  /**
   * @notice Gets the address of a registered FarmGenerator at specifiex index
   */
  function farmGeneratorAtIndex(uint256 _index) external view returns (address) {
    return farmGenerators.at(_index);
  }

  /**
   * @notice The length of all farms on the platform
   */
  function farmsLength() external view returns (uint256) {
    return farms.length();
  }

  /**
   * @notice gets a farm at a specific index. Although using Enumerable Set, since farms are only added and not removed this will never change
   * @return the address of the Farm contract at index
   */
  function farmAtIndex(uint256 _index) external view returns (address) {
    return farms.at(_index);
  }

  /**
   * @notice called by a Farm contract when lp token balance changes from 0 to > 0 to allow tracking all farms a user is active in
   */
  function userEnteredFarm(address _user) public {
    // msgSender = farm contract
    address msgSender = _msgSender();
    require(farms.contains(msgSender), 'FORBIDDEN');
    EnumerableSet.AddressSet storage set = userFarms[_user];
    set.add(msgSender);
  }

  /**
   * @notice called by a Farm contract when all LP tokens have been withdrawn, removing the farm from the users active farm list
   */
  function userLeftFarm(address _user) public {
    // msgSender = farm contract
    address msgSender = _msgSender();
    require(farms.contains(msgSender), 'FORBIDDEN');
    EnumerableSet.AddressSet storage set = userFarms[_user];
    set.remove(msgSender);
  }

  /**
   * @notice returns the number of farms the user is active in
   */
  function userFarmsLength(address _user) external view returns (uint256) {
    EnumerableSet.AddressSet storage set = userFarms[_user];
    return set.length();
  }

  /**
   * @notice called by a Farm contract when all LP tokens have been withdrawn, removing the farm from the users active farm list
   * @return the address of the Farm contract the user is farming
   */
  function userFarmAtIndex(address _user, uint256 _index) external view returns (address) {
    EnumerableSet.AddressSet storage set = userFarms[_user];
    return set.at(_index);
  }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "evmVersion": "istanbul",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}