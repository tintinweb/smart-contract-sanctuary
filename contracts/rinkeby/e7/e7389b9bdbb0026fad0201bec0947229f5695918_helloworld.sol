/**
 *Submitted for verification at Etherscan.io on 2022-01-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract helloworld {
    string name;

    constructor() public {
        name = "welight";
    }

    bool public saleIsActive = false;
    uint256 public state = 1;
    uint256 public publicTokenPrice = 0.0269 ether;

    function changeState(uint256 newState) public {
        state = newState;
    }

    function get() public view returns (string memory) {
        return name;
    }
    
    event Set(address indexed_from, string n);
    function set(string memory n) public {
        name = n;
        emit Set(msg.sender, n);
    }
}