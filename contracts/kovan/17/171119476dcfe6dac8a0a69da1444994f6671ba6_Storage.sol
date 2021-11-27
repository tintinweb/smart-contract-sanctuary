/**
 *Submitted for verification at Etherscan.io on 2021-11-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    mapping (address => string) public myMap;

    function set(address _addr, string memory _string) public {
        myMap[_addr] = _string;
    }

    function get(address _addr) public view returns (string memory) {
        return myMap[_addr];
    }

    function remove(address _addr) public {
        delete myMap[_addr];
    }

}