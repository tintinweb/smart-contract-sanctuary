/**
 *Submitted for verification at Etherscan.io on 2021-12-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9 <0.9.0;

contract DeployTest {

string private _name;
string private _symbol;


    constructor(string memory name, string memory symbol) {
        _name=name;
        _symbol=symbol;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

}