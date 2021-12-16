/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.9.0;




//just for attrubute
struct IndexValue { uint256 keyIndex; uint256 value; }
struct KeyFlag { uint256 key; bool deleted; }

struct itmap {
    mapping(uint256 => IndexValue) data;
    KeyFlag[] keys;
    uint256 size;
}

//可便利map
library IterableMapping {
    function insert(itmap storage self, uint256 key, uint256  value) internal returns (bool replaced) {
        uint256 keyIndex = self.data[key].keyIndex;
        self.data[key].value = value;
        if (keyIndex > 0)
            return true;
        else {
            keyIndex = self.keys.length;

            self.keys.push();
            self.data[key].keyIndex = keyIndex + 1;
            self.keys[keyIndex].key = key;
            self.size++;
            return false;
        }
    }

    function remove(itmap storage self, uint256 key) internal returns (bool success) {
        uint keyIndex = self.data[key].keyIndex;
        if (keyIndex == 0)
            return false;
        delete self.data[key];
        self.keys[keyIndex - 1].deleted = true;
        self.size --;
    }



    function contains(itmap storage self, uint256 key) internal view returns (bool) {
        return self.data[key].keyIndex > 0;
    }


    function iterate_start(itmap storage self) internal view returns (uint256 keyIndex) {
        return iterate_next(self, type(uint256).max);
    }

    function iterate_valid(itmap storage self, uint256 keyIndex) internal view returns (bool) {
        return keyIndex < self.keys.length;
    }

    function iterate_next(itmap storage self, uint256 keyIndex) internal view returns (uint256 r_keyIndex) {
        keyIndex++;
        while (keyIndex < self.keys.length && self.keys[keyIndex].deleted)
            keyIndex++;
        return keyIndex;
    }

    function iterate_get(itmap storage self, uint256 keyIndex) internal view returns (uint256 key, uint256  value) {
        key = self.keys[keyIndex].key;
        value = self.data[key].value;
    }
}

// 如何使用
contract User {
    // Just a struct holding our data.
    itmap data;
    // Apply library functions to the data type.
    using IterableMapping for itmap;

    // Insert something
    function insert(uint256[] memory k, uint256[] memory  v) public returns (uint256 size) {
        for (uint i = 0; i < k.length; i++) {
            data.insert(k[i], v[i]);
        }
            // This calls IterableMapping.insert(data, k, v)

            // We can still access members of the struct,
            // but we should take care not to mess with them.
        return data.size;
    }

    // Computes the sum of all stored data.
    function sum() public view returns (uint256[] memory ,uint256[] memory)  {
        uint256[] memory k = new uint256[](data.size);
        uint256[] memory v =  new uint256[](data.size);
        uint256 j ;
        for (
            uint256 i = data.iterate_start();
            data.iterate_valid(i);
            i = data.iterate_next(i)
        ) {
            (uint256 a, uint256 b) = data.iterate_get(i);
            k[j]=a;
            v[j]=b;
            j++;
        }
    }
}