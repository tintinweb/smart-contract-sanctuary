// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library StringToUintMap
{
    struct Data {
        mapping (string => uint8) map;
    }

    function insert(Data storage self, string calldata key, uint8 value) public returns (bool updated)
    {
        require(value > 0);

        updated = self.map[key] != 0;
        self.map[key] = value;
    }

    function get(Data storage self, string calldata key) public view returns (uint8)
    {
        return self.map[key];
    }
}