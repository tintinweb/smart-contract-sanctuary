/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface Leader {
    function tokenBurn(
        string memory _coin,
        address _userAddress,
        uint256 _amount
    ) external;

    function tokenMint(
        string memory _coin,
        address _userAddress,
        uint256 _amount
    ) external;
}

contract Controller {
    // Ownership Logic
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    constructor() {
        owner = msg.sender;
    }

    //statics
    address internal LEADER = 0x9Ae8786C620A0d0D20C5Ef96566907836D9F6743;

    // Mint Logic
    struct Queue {
        string coin;
        address addr;
        uint256 amount;
        string txnhash;
    }

    Queue[] public userMints;

    mapping(string => uint256) public timestampSolver;
    mapping(string => bool) public transactionsProceeded;

    function registerDeposit(
        string memory _coin,
        address _userAddress,
        uint256 _amount,
        string memory _txnhash,
        uint256 _lastTimestamp
    ) external onlyOwner {
        if (transactionsProceeded[_txnhash] == false) {
            if (timestampSolver[_coin] <= _lastTimestamp) {
                Queue memory m;
                m.coin = _coin;
                m.addr = _userAddress;
                m.amount = _amount;
                m.txnhash = _txnhash;

                userMints.push(m);

                timestampSolver[_coin] = _lastTimestamp;
                Leader(LEADER).tokenMint(_coin, _userAddress, _amount);

                transactionsProceeded[_txnhash] = true;
            }
        }
    }

    /// Burn logic
    struct QueueBlock {
        string coin;
        string addr;
        uint256 amount;
        bool success;
        string txnhash;
    }

    QueueBlock[] public userWithdraws;

    function registerWithdraw(
        string memory _coin,
        string memory _address,
        uint256 _amount
    ) external {
        Leader(LEADER).tokenBurn(_coin, msg.sender, _amount);

        QueueBlock memory m;
        m.coin = _coin;
        m.addr = _address;
        m.amount = _amount;
        m.success = false;
        m.txnhash = "x";

        userWithdraws.push(m);
    }

    // counter

    function registerWithdrawSuccess(uint256 _queue, string memory txnhash)
        external
        onlyOwner
    {
        userWithdraws[_queue].success = true;
        userWithdraws[_queue].txnhash = txnhash;
    }

    // length

    function getMintsLength() public view returns (uint256) {
        return userMints.length;
    }

    function getBurnsLength() public view returns (uint256) {
        return userWithdraws.length;
    }
}