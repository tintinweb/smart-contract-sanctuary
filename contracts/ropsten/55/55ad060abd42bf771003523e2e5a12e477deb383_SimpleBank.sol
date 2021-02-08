/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

pragma solidity ^0.5.8;

contract SimpleBank {
    uint8 private clientCount;
    mapping (address => uint) private balances;
    address public owner;

    event LogDepositMade(address indexed accountAddress, uint amount);

    constructor() public payable {
        owner = msg.sender;
        clientCount = 0;
    }


    function enroll() public returns (uint) {
        if (clientCount < 3) {
            clientCount++;
            balances[msg.sender] = 10 ether;
        }
        return balances[msg.sender];
    }


    function deposit() public payable returns (uint) {
        balances[msg.sender] += msg.value;
        emit LogDepositMade(msg.sender, msg.value);
        return balances[msg.sender];
    }


    function withdraw(uint withdrawAmount) public returns (uint remainingBal) {
        // Check enough balance available, otherwise just return balance
        if (withdrawAmount <= balances[msg.sender]) {
            balances[msg.sender] -= withdrawAmount;
            msg.sender.transfer(withdrawAmount);
        }
        return balances[msg.sender];
    }


    function balance() public view returns (uint) {
        return balances[msg.sender];
    }

    function depositsBalance() public view returns (uint) {
        return address(this).balance;
    }
}