/**
 *Submitted for verification at polygonscan.com on 2021-12-28
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.5.12;

contract Wallet {
    address payable public owner;
    
    event Deposit (address sender, uint amount, uint balance);
    event WithDraw (uint amount, uint balance);
    event Transfer (address recipient, uint amount, uint balance);

    constructor() public payable {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Must be owner to withdraw" );
        _;
    }

    function deposit() public payable {
        emit Deposit(msg.sender, msg.value, address(this).balance );
    }//end deposit

    function withdraw(uint _amount) public  onlyOwner {
        owner.transfer(_amount);
        emit WithDraw(_amount, address(this).balance);
    }

    function transfer(address payable _to,uint _amount) public onlyOwner {
        _to.transfer(_amount);
        emit Transfer(_to, _amount, address(this).balance);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }//end getBalance

}//end Wallet