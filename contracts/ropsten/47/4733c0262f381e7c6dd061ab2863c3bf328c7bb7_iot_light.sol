/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// contract for changing light values
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract iot_light {

    struct Light {
        uint red;
        uint green;
        uint blue;
    }

    Light public light;



    function set_light(uint _r, uint _g, uint _b) public {
        light.red = _r;
        light.green = _g;
        light.blue = _b;
    }
}