/**
 *Submitted for verification at Etherscan.io on 2022-01-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract StudentScores{
    mapping(string => uint) scores;
    string[] names;

    function addScores(string memory name, uint score) public {
        scores[name]=score;
        names.push(name);
    }
    function getScores(string memory name) public view returns (uint) {
        return scores[name];
    }
    function clear() public {
        while (names.length > 0) {
        delete scores[names[names.length-1]];
        names.pop();
        }
    }
}