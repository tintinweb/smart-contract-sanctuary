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
     
    function store(string memory name, bool s) public {
        if(cnt < limitn){
            p[cnt] = Person(name,s);
            cnt++;
        }
    }

    function retrieve(uint256 n) public view returns (string memory na, bool s){
        na = p[n].name;
        s = p[n].se;
    }
}