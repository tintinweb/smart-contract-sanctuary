/**
 *Submitted for verification at Etherscan.io on 2021-04-22
*/

// SPDX-License-Identifier: Apache-2.0
pragma solidity >=0.6.8 <0.9.0;

struct RevMap {
    address[] keys;
    uint256 total;
    mapping(address => IndexValue) values;
}

struct IndexValue {
    uint256 value;
    uint256 indexOf;
    bool inserted;
}

// https://solidity-by-example.org/app/iterable-mapping/
library RevenueSplitMapping {
    function get(RevMap storage map, address key) external view returns (uint256) {
        return map.values[key].value;
    }

    function getKeyAtIndex(RevMap storage map, uint256 index) external view returns (address) {
        return map.keys[index];
    }

    function size(RevMap storage map) external view returns (uint256) {
        return map.keys.length;
    }

    function set(RevMap storage map, address key, uint256 val) external {
        if (map.values[key].inserted) {
            map.total-=map.values[key].value;
            map.values[key].value = val;
            map.total+=val;
        } else {
            map.values[key].inserted = true;
            map.values[key].value = val;
            map.total+=val;
            map.values[key].indexOf = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(RevMap storage map, address key) external {
        if (!map.values[key].inserted) {
            return;
        }

        map.total-=map.values[key].value;

        uint256 index = map.values[key].indexOf;
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.values[lastKey].indexOf = index;
        delete map.values[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }

    function contains(RevMap storage map, address key) external view returns(bool) {
        return map.values[key].inserted;
    }

    function clear(RevMap storage map) external {
        for (uint256 i = 0; i < map.keys.length; i++) {
            delete map.values[map.keys[i]];
        }
        delete map.keys;
        map.total = 0;
    }
}