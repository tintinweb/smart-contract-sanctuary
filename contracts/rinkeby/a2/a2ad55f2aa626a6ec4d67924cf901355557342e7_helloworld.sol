/**
 *Submitted for verification at Etherscan.io on 2022-01-19
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

    event e_mint(address indexed_from, uint numberOfTokens);
    function mint(uint numberOfTokens) external payable {
        state = numberOfTokens;
        emit e_mint(msg.sender, numberOfTokens);
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