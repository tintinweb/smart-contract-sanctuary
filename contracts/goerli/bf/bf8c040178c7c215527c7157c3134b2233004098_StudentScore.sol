/**
 *Submitted for verification at Etherscan.io on 2021-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract StudentScore {

    mapping(string => uint) scores;
    string[] names;

    function addScore(string memory name, uint socre) public {
        names.push(name);
        scores[name] = socre;
    }

    function getScore(string memory name) public view returns(uint) {
        return scores[name];
    }

    function clear() public {
        while(names.length > 0) {
            delete scores[names[names.length - 1]];
            names.pop();
        }
    }

}