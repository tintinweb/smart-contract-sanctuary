/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



contract Bank{
  
    mapping(address=>uint) _balance;
   uint _totalSupply;
    //uint _balance;
    
    function deposit() public payable {
        
        _balance[msg.sender]+=msg.value;
        _totalSupply+=msg.value;
    }
    
    function withdraw(uint amount) public {
        require(amount<=_balance[msg.sender],"not enough money");
       payable(msg.sender).transfer(amount);
        _balance[msg.sender]-=amount;
        _totalSupply-=amount;
    }
    function checkbalance() public view returns(uint balance){
        return _balance[msg.sender];
    }
    function CheckTotalSupply()public view returns(uint totalSupply){
    return _totalSupply;
        
    }
  
}