// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @notice This ERC20 is only for the testnet.
 */
contract TestContract1 {

    struct Point {
        uint256 x;
        uint256 y;
    }

    uint256 temp01;
    string temp02;
    Point temp03;
    bytes temp04;

    constructor(uint256 param1, string memory s, Point memory point, bytes memory b) {
        temp01 = param1;
        temp02 = s;
        temp03 = point;
        temp04 = b;
    }
    // constructor() {
    //     temp01 = 10;
    //     temp02 = "111";
    //     temp03.x = 2;
    //     temp03.y = 3;
    //     temp04 = "0x1234";
    // }
}