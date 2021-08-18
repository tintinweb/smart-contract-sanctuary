/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity 0.5.16;

contract myFirstContract {
    mapping(address=> uint) public deposits;
    mapping(address=> uint) public withdrawals;
    
    uint public totalDeposits = 0;
    uint public totalWithdrawals = 0;
    
    function deposit() public payable {
        deposits[msg.sender] = deposits[msg.sender] + msg.value;
        totalDeposits = totalDeposits + msg.value;
    }
    
    function withdraw(uint amount) public {
        if (address(msg.sender).balance >= amount) {
            msg.sender.transfer(amount);
            withdrawals[msg.sender] = withdrawals[msg.sender] + amount;
            totalWithdrawals = totalWithdrawals + amount;
        }
    }
}