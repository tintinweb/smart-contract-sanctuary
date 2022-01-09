// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0 <0.6.0;

/* @title Smart Bank contract for the Testnet
@author daraujo92 
*/
import "./Ownable.sol";

contract SmartBank is Ownable {
    uint bankBalance = 0;
    uint transactionFee = 0.01 ether;


    function _checkContractBalance() public view onlyOwner returns(uint) {
        return bankBalance;
    
    }

    mapping(address => uint256) balance;

    function deposit(uint _amount) public payable {
        require(_amount > 0.01 ether);
        balance[msg.sender] = (msg.value - 0.01 ether);
        bankBalance = bankBalance + msg.value;
    }

    function checkUserBalance(address userAddress) public view returns(uint){
        require(userAddress == msg.sender);
        uint personalBalance = balance[userAddress];
        return personalBalance;
    }
}