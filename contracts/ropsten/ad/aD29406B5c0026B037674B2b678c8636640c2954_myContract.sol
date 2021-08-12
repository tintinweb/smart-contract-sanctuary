/**
 *Submitted for verification at Etherscan.io on 2021-08-12
*/

pragma solidity 0.5.16;

contract myContract {
    mapping(address => uint) public deposits;
    uint public totalDeposits = 0;

    function deposit() public payable{
        deposits[msg.sender] = deposits[msg.sender] + msg.value;
        totalDeposits = totalDeposits + msg.value;
    }
    function withdraw(uint amount) public{
        if(deposits[msg.sender] >= amount){
            msg.sender.transfer (amount);
            
            deposits[msg.sender] = deposits[msg.sender] - amount;
            totalDeposits = totalDeposits - amount;
        }
    }
}