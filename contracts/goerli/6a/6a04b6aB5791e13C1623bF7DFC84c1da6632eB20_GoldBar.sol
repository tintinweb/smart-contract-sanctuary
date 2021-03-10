/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.1;

contract GoldBar {
    uint256 public value = 1400;
    bytes2 public constant symbol = "oz";
    bytes10 public constant name = "GoldBar";
    

    uint256 public constant decimals = 4;
    uint256 public constant totalSupply = 10000;

    mapping (address => uint256) public balanceOf;

    constructor () public {
        balanceOf[address(this)] = 10000;
        emit Transfer(address(0), address(this), 10000);
    }

    function setValue(uint256 _value) public {
        value = _value;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
}