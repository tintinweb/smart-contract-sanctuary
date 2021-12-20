/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title Token Generator
 * @author Create My Token (https://www.createmytoken.net/)
 * @dev Implementation of the Token Generator
 */
contract TokenGenerator {
    string public constant _GENERATOR = "https://www.createmytoken.net/";
    string public constant _VERSION = "v2.0.3";

    function generator() public pure returns (string memory) {
        return _GENERATOR;
    }

    function version() public pure returns (string memory) {
        return _VERSION;
    }
}