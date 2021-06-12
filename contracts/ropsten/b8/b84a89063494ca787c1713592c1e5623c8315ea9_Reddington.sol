/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

contract Reddington {
    string public name = "Reddington";
    string public symbol = "RDTN";

    uint256 totalSupply = 1000000000;

    address owner;

    mapping(address => uint256) balances;

    constructor() {
        balances[msg.sender];
        owner = msg.sender;
    }

    function getTotalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function getName() public view returns (string memory) {
        return name;
    }
}