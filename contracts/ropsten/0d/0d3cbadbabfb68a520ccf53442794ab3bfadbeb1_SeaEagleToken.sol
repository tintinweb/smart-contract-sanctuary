/**
 *Submitted for verification at Etherscan.io on 2021-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract SeaEagleToken{
    string public name;
    uint256 public balance;
    struct Eagle {
        uint256 eggs;
        string color;
    }
    Eagle[] public eagles;

    constructor(string memory _name){
        name = _name;
    }

    function getBalance() public view returns(uint256) {
        return balance;
    }

    function setBalance(uint256 _balance) external {
        balance = _balance;
    }

    function setEagle(uint256 _eggs, string memory _color) external {
        eagles.push(Eagle(_eggs,_color));
    }

    function getEagle(uint256 eid) external view returns( Eagle memory){
        return eagles[eid];
    }

    function getEagles() external view returns(Eagle[] memory){
        return eagles;
    }

    ///@dev 给合约发送msg.value的ETH，balance自动加上传送的eth数。仅测试而已，函数没有特别意义。web3调用方式 addBalance({value:100*10**9})
    function addBalance() payable external {
        require(msg.value>0, "No ETH");
        balance += msg.value;
    }

    receive() external payable {}
}