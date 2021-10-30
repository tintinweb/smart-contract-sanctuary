//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Allowance.sol";

contract SharedWallet is Allowance {
    
    event MoneySent(address indexed _sentTo, uint _amount);
    event MoneyReceived(address indexed _from, uint _amount);
    
    
    function withdrawMoney(address payable _to, uint _amount) public ownerOrAllowed(_amount) {
        require(_amount <= address(this).balance, "Not enough money in the contract");
        if(!isOwner()){
            reduceAllowance(msg.sender, _amount);
        } else if(isOwner()) {
            
            reduceAllowance(_to, _amount);
        }
        _to.transfer(_amount);
        emit MoneySent(_to, _amount);
    }
    
    receive() external payable {
        emit MoneyReceived(msg.sender, msg.value);
        
    }
    
    fallback() external payable {
        emit MoneyReceived(msg.sender, msg.value);
    }
}