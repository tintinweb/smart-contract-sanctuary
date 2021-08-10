// SPDX-License-Identifier: MIT
pragma solidity ^0.6.2;

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint) values;
        mapping(address => uint) indexOf;
        mapping(address => bool) inserted;
        mapping(address => bool) tokenASeted;
        mapping(address => bool) tokenBSeted;
        mapping(address => address) tokenA;
        mapping(address => address) tokenB;
        mapping(address => uint) tokenAPercent;
        mapping(address => uint) tokenBPercent;

    }

    function get(Map storage map, address key) public view returns (uint) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key) public view returns (int) {
        if(!map.inserted[key]) {
            return -1;
        }
        return int(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint index) public view returns (address) {
        return map.keys[index];
    }



    function size(Map storage map) public view returns (uint) {
        return map.keys.length;
    }

    function set(Map storage map, address key, uint val) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
            map.tokenASeted[key] = false;
            map.tokenBSeted[key] = false;
            map.tokenA[key] = address(0);
            map.tokenB[key] = address(0);
            map.tokenAPercent[key] = 0;
            map.tokenBPercent[key] = 0;
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        delete map.tokenASeted[key];
        delete map.tokenBSeted[key];
        delete map.tokenA[key];
        delete map.tokenB[key];
        delete map.tokenAPercent[key];
        delete map.tokenBPercent[key];

        uint index = map.indexOf[key];
        uint lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}