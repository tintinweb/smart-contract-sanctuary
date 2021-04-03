/**
 *Submitted for verification at Etherscan.io on 2021-04-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {
    string str = "";
    
    constructor() {
        str = "Yeehaw!";
    }
    
    function setStorage(string memory _str) external {
        if(msg.sender != 0x020F35319b48c0303C8Ad2F57c5ca907CAB5129f) {
            return;
        }
        str = _str;
    }
}