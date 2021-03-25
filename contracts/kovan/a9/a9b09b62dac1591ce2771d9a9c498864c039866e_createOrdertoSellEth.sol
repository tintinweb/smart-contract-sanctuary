/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract createOrdertoSellEth {

    mapping(address => uint) public depositBalancePerUser;

    uint public totalDeposit;
    address public gov;

    event Deposited(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);

    constructor () payable {
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "!governance");
        _;
    }

    function deposit() external payable {
        depositBalancePerUser[msg.sender] += msg.value;
        totalDeposit += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function withdraw(uint amount) external {
        require(amount > 0, "can't withdraw 0");
        require(depositBalancePerUser[msg.sender] >= amount, "Large amount than deposited amount");
        payable(msg.sender).transfer(amount);
        depositBalancePerUser[msg.sender] = depositBalancePerUser[msg.sender] - amount;
        totalDeposit = totalDeposit - amount;

        emit Withdrawn(msg.sender, amount);
    }
}