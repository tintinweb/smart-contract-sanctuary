/**
 *Submitted for verification at Etherscan.io on 2021-08-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ETHTest {
    mapping (address => uint256) public  balanceOf;

    constructor() {
    }

    fallback() external payable {}
    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] = msg.value + balanceOf[msg.sender];
    }
    function withdraw(uint256 wad) public {
        balanceOf[msg.sender] = balanceOf[msg.sender] - wad;
        address payable receiver = payable(msg.sender);
        receiver.transfer(wad);
    }
}