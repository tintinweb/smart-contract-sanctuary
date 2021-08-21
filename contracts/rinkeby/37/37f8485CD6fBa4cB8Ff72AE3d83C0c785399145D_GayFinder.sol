/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract GayFinder {
    mapping(string => bool) private gays;

    address admin;

    modifier onlyAdmin() {
        require(msg.sender == admin, "GayFinder: sender is not admin");
        _;
    }

    constructor() {
        admin = msg.sender;
        string memory mainGay = "Roman Meyder";
        gays[mainGay] = true;
    }

    function isGay(string memory person) external view returns (bool) {
        return gays[person];
    }

    function setGay(string memory gay) onlyAdmin external {
        gays[gay] = true;
    }
}