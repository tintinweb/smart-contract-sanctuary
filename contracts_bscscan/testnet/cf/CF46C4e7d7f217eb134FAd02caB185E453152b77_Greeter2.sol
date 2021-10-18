// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { StringToUintMap } from "./StringToUintMap.sol";

contract Greeter2 {

    StringToUintMap.Data private _stringToUintMapData;

    function test2(string calldata name, uint8 age) public {
        
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