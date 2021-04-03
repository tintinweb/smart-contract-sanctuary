//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.3;

import "./Allowance.sol";

contract SharedWallet is Allowance {
    
    event MoneySent (address indexed _beneficiary, uint _amount);
    event MoneyReceived (address indexed _from, uint _amount);
    
    // View Contract Balance
    function contractBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    // Allow Contract to Receive Money
    function receiveMoney() public payable{
        emit MoneyReceived(msg.sender, msg.value);
    }
    
    // Allow Users to Withdraw Money
    function withdrawMoney(address payable _to, uint _amount) public ownerOrAllowed(_amount){
        require(_amount <= address(this).balance, "Not enough money in the contract.");
        
        if(!isOwner()) {
            reduceAllowance(msg.sender, _amount);
        }
        
        emit MoneySent(msg.sender, _amount);
        
        _to.transfer(_amount);
        
    }
    
    // Prevents Renouncing Ownership
    function renounceOwnership() public override onlyOwner {
        revert("Can't renounceOwnership here!");
    }
}