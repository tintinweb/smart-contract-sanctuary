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

interface Dydx {
    function deposit(address account, uint256 amount) external;
    function withdraw(address account, address destination, uint256 amount) external; 
}

contract createOrdertoBuyEth {
    IERC20 public token0; // token0 is USDC.
    Dydx constant DYDX = Dydx(0xE883b3efdaE637fC599b467478a23199778F2cCf);
    address public gov;

    mapping(address => uint256) public depositBalancePerUser;

    uint public totalDeposit;

    event Deposited(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);

    constructor () payable {
        token0 = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48); // USDC
        gov = msg.sender;
    }

    modifier onlyGov() {
        require(msg.sender == gov, "!governance");
        _;
    }

    function deposit(uint amount) external {
        if (amount > 0) {
            token0.transferFrom(msg.sender, address(this), amount);
            DYDX.deposit(address(this), amount);
            depositBalancePerUser[msg.sender] += amount;
            totalDeposit += amount;
            emit Deposited(msg.sender, amount);
        }
    }

    function withdraw(uint256 amount) external {
        require(token0.balanceOf(address(this)) > 0, "no withdraw amount");
        
        if (amount > depositBalancePerUser[msg.sender]) {
            amount = depositBalancePerUser[msg.sender];
        }

        require(amount > 0, "can't withdraw 0");

        token0.transfer(msg.sender, amount);
        depositBalancePerUser[msg.sender] = depositBalancePerUser[msg.sender] - amount;
        totalDeposit = totalDeposit - amount;

        emit Withdrawn(msg.sender, amount);
    }
}