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

    mapping (address => uint) public myMap;

    function set(address _addr, uint _i) public {
        myMap[_addr] = _i;
    }

}