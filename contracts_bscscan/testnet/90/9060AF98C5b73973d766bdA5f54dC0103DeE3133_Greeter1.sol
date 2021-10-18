// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { StringToUintMap } from "./StringToUintMap.sol";

contract Greeter1 {

    StringToUintMap.Data private _stringToUintMapData;

    function test1(string calldata name, uint8 age) public {
        
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library StringToUintMap
{
    struct Data {
        mapping (string => uint8) map;
    }

}