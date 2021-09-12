/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Task1 {

    uint256 limitn = 20;
    uint256 cnt = 0;

    string[] name;
    bool[] se;
     
    function store() public {
            name.push("AAA");
            se.push(true);
            name.push("BBB");
            se.push(true);
            name.push("CCC");
            se.push(true);
            name.push("DDD");
            se.push(true);
            name.push("EEE");
            se.push(true);
    }

    function retrieve(uint256 n) public view returns (string memory na, bool s){
        na = name[n-1];
        s = se[n-1];
    }
}