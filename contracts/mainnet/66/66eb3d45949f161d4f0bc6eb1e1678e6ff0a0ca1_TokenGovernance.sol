/**
 *Submitted for verification at Etherscan.io on 2021-06-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract TokenGovernance {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    uint256 public maxSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) private allowances;

    constructor() {
        name = "RUNCOIN";
        symbol = "RUN";
        decimals = 18;
        totalSupply = 30000000 * (uint256(10)**decimals);
        balanceOf[msg.sender] = totalSupply;
        maxSupply = totalSupply ;
    }

    function transfer(address recipient, uint256 amount)
        external
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool success) {
        require(balanceOf[sender] >= amount);
        require(allowances[sender][msg.sender] >= amount);
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        allowances[sender][msg.sender] -= amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool success) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }




    function burn(uint256 _amount) external  returns (bool success) {
        require(balanceOf[msg.sender] >= _amount);
        balanceOf[msg.sender] -= _amount;
        totalSupply -= _amount;
        maxSupply -= _amount;
        emit Transfer(msg.sender, address(0), _amount);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    event Transfer(address indexed from, address indexed to, uint256 value);
  

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}