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
    struct Person{
        string name;
        bool se;
    }
    uint256 limitn = 20;
    uint256 cnt = 0;
    Person[] p;
     
    function store(Person[] memory p) public {
        if(cnt < limitn){
            cnt++;
        }
    }

    function retrieve(uint256 n) public view returns (Person memory){
        return p[n-1];
    }
}