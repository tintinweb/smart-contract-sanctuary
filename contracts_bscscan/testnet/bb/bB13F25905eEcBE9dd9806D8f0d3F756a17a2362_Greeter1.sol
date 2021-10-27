// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { StringMap } from "./StringMap.sol";

contract GreeterA{
    StringMap.Data private _stringToUintMapData;

    function addAge(string calldata name, uint8 age) public
    {
        StringMap.insert(_stringToUintMapData, name, age);
    }

    function getAge(string calldata name) public view returns (uint8)
    {
        uint8 age = StringMap.get(_stringToUintMapData, name);
        return age;
    }
}

contract Greeter1{
    GreeterA public TestGreeterA;

    constructor()
    {
        TestGreeterA = new GreeterA();
    }

    function addPerson(string calldata name, uint8 age) public
    {
        TestGreeterA.addAge(name, age);
    }

    function getPerson(string calldata name) public view returns (uint8)
    {
        return TestGreeterA.getAge(name);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library StringMap
{
    struct Data
    {
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