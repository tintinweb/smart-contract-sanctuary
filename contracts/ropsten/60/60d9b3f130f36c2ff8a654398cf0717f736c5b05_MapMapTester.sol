/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

contract Tester {
  int256 public foo;

  constructor(int256 f) payable {
    foo = f;
  }

  function incPayable(int256 i) public payable {
    foo += i;
  }

  function inc(int256 i) public {
    foo += i;
  }

  fallback() external payable {
    if (msg.value > 0) {
      foo += 1000;
    } else {
      foo += 42;
    }
  }

  receive() external payable {
    if (msg.value > 0) {
      foo += 1000;
    } else {
      foo += 42;
    }
  }

  function getAndIncFoo() public returns (int256) {
    foo += 1;
    return foo;
  }

  function getFoo() public view returns (int256) {
    return foo;
  }
}

contract MapMapTester {
  uint256 public count;
  mapping(uint256 => uint256) public keyMap;
  mapping(uint256 => uint256) public keyToIndex;
  mapping(uint256 => uint256) public indexToKey;

  function addKey(uint256 key) public {
    require(keyMap[key] == 0, 'key already used');
    keyMap[key] = 1;
    uint256 index = count++;
    indexToKey[index] = key;
    keyToIndex[key] = index;
  }

  function removeKey(uint256 key) public {
    require(keyMap[key] != 0, 'key not found');
    uint256 index = keyToIndex[key];
    count--;
    if (index < count) {
      uint256 endKey = indexToKey[count];
      keyToIndex[endKey] = index;
      indexToKey[index] = endKey;
    }
    delete indexToKey[count];
    delete keyToIndex[key];
    delete keyMap[key];
  }

  function getKeyAtIndex(uint256 index) public view returns (uint256) {
    uint256 key = indexToKey[index];
    require(keyMap[key] != 0, 'key not found');
    return key;
  }

  function getIndexForKey(uint256 key) public view returns (uint256) {
    require(keyMap[key] != 0, 'key not found');
    return keyToIndex[key];
  }

  function fill(uint256 start, uint256 _count) public {
    for (uint256 i = 0; i < _count; i++) {
      addKey(start + i);
    }
  }
}

contract MapListTester {
  mapping(uint256 => uint256) public keyMap;
  uint256[] public keyList;
  mapping(uint256 => uint256) public keyToIndex;

  function addKey(uint256 key) public {
    require(keyMap[key] == 0, 'key already used');
    keyMap[key] = 1;
    keyToIndex[key] = keyList.length;
    keyList.push(key);
  }

  function removeKey(uint256 key) public {
    require(keyMap[key] != 0, 'key not found');
    uint256 index = keyToIndex[key];
    if (index < keyList.length - 1) {
      uint256 endKey = keyList[keyList.length - 1];
      keyToIndex[endKey] = index;
      keyList[index] = endKey;
    }
    delete keyToIndex[key];
    delete keyMap[key];
    keyList.pop();
  }

  function getKeyAtIndex(uint256 index) public view returns (uint256) {
    uint256 key = keyList[index];
    require(keyMap[key] != 0, 'key not found');
    return key;
  }

  function getIndexForKey(uint256 key) public view returns (uint256) {
    require(keyMap[key] != 0, 'key not found');
    return keyToIndex[key];
  }

  function fill(uint256 start, uint256 _count) public {
    for (uint256 i = 0; i < _count; i++) {
      addKey(start + i);
    }
  }

  function count() public view returns (uint256) {
    return keyList.length;
  }

  function getList() public view returns (uint256[] memory) {
    return keyList;
  }
}