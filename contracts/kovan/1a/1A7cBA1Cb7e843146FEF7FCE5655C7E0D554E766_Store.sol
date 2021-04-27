/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

// "SPDX-License-Identifier: Apache-2.0"
pragma solidity ^0.6.12;

contract Store {
    event Deposit(address indexed _from, uint256 _value);
    event Retrieve(address indexed _from, uint256 _value);
    event Send(address indexed _from, address indexed _to, uint256 value);

    mapping(address => uint256) public values;
    mapping(address => mapping(address => uint256)) private transactions;
    mapping(uint256 => address) private reverseValues;
    uint256 latest;
    Transaction[] history;

    struct Transaction {
        address from;
        address to;
        uint256 amount;
    }

    constructor() public {
        values[msg.sender] = 2000;
        latest = 0;
        emit Deposit(msg.sender, 200);
    }

    function whoami() external view returns (address) {
        return msg.sender;
    }

    function fail() external view {
        require(0 > 1, 'This will fail');
    }

    function store(uint256 value) public payable {
        values[msg.sender] += value;
        latest = msg.value;
        reverseValues[value] = msg.sender;
        emit Deposit(msg.sender, value);
    }

    function retrieve(uint256 value) public {
        require(value <= values[msg.sender], 'Not enough stored');
        values[msg.sender] -= value;
        emit Retrieve(msg.sender, value);
    }

    function read() external view returns (uint256) {
        return values[msg.sender];
    }

    function send(address to, uint256 amount) public {
        require(amount <= values[msg.sender], 'Amount too big');
        values[msg.sender] -= amount;
        values[to] += amount;
        transactions[msg.sender][to] = amount;

        Transaction storage trx;
        trx.from = msg.sender;
        trx.to = to;
        trx.amount = amount;

        history.push(trx);

        emit Send(msg.sender, to, amount);
    }
}