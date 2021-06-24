/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.4.24;
contract game {
    event win(address);
    
    function get_random() public view returns(uint) {
        bytes32 random = keccak256(abi.encodePacked(now,blockhash(block.number-1)));
        return uint(random) % 5;
    }
    
    function play(uint num) public payable {
        require(msg.value == 1 ether);
        if(num == get_random()) {
            msg.sender.transfer(2 ether);
            emit win(msg.sender);
        }
    }
    
    function () public payable {
        require(msg.value == 4 ether);
    }
    
    constructor () public payable {
        require(msg.value == 4 ether);
    }
    
    function killcontract() public {
        require(msg.sender == 0x786B753cE867E0f6aE81d7Bff6D0cD392A9AeA93); // 誰可以使用毀約功能
        selfdestruct(0x786B753cE867E0f6aE81d7Bff6D0cD392A9AeA93); // 合約內剩餘的餘額會轉入哪個帳戶
    }
}