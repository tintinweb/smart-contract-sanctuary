//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//    __       ___ ___
//  /'_ `\   /' __` __`\
// /\ \L\ \  /\ \/\ \/\ \
// \ \____ \ \ \_\ \_\ \_\
//  \/___L\ \ \/_/\/_/\/_/
//    /\____/
//    \_/__/

contract GreeterV1 {
    function greet() public pure returns (string memory) {
        return "gm!";
    }
}