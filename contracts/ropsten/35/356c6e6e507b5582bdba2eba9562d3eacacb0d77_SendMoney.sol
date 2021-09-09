/**
 *Submitted for verification at Etherscan.io on 2021-09-09
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

contract SendMoney {
    
    uint public balanceReceived;
    uint public lockedUntil;
    
    function receiveMoney() public payable {
        balanceReceived += msg.value;
        lockedUntil = block.timestamp + 1 minutes;
    }
    
    function getBalanceOf(address _address) public view returns(uint) {
        return _address.balance;
    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    
    function withdrawMoney() public {
       if(lockedUntil < block.timestamp) {

        address payable to = payable(msg.sender);
        to.transfer(getBalance());
        // to.transfer(this.getBalance());
       }
    }
    
    function withdrawMoneyFrom(address _address) public {
        address payable to = payable(msg.sender);
        to.transfer(_address.balance);
    }
    
    function withdrawMoneyTo(address payable _to) public {
      if(lockedUntil < block.timestamp) {

        _to.transfer(getBalance());
      }
    }
}