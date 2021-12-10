/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract Oracle {
    // Ownership
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    // Oracle
    constructor() {
        owner = msg.sender;
    }

    struct Balance {
        string coin;
        string addr;
        uint256 oldBalance;
        uint256 balance;
        uint256 updatedAtBlock;
    }

    struct BalanceQueue {
        string coin;
        string addr;
        bool updated;
    }

    BalanceQueue[] public balanceRequests;
    mapping(string => Balance) public balance;

    function requestUpdateBalance(string memory _coin, string memory _addr)
        external
    {
        BalanceQueue memory bq;

        bq.addr = _addr;
        bq.coin = _coin;
        bq.updated = false;
        balanceRequests.push(bq);
    }

    function updateBalance(
        uint256 _queue,
        string memory _coin,
        string memory _addr,
        uint256 _balance
    ) external onlyOwner {
        balanceRequests[_queue].updated = true;

        balance[_addr].coin = _coin;
        balance[_addr].addr = _addr;
        balance[_addr].oldBalance = balance[_addr].balance;
        balance[_addr].balance = _balance;
        balance[_addr].updatedAtBlock = block.number;
    }

    function balanceRequestsLength() public view returns (uint256) {
        return balanceRequests.length;
    }
}