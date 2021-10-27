/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

pragma solidity ^0.5.0;

contract financialContract{

    uint balance;
    address owner = msg.sender;
    
    function getBalance() public view returns(uint){
        return balance;
    }

    function deposit(uint newDeposit) public{
        balance = balance + newDeposit;
    }
    
    modifier restricted(){
        require(
        msg.sender == owner, 
        "This function is restricted to the contract's owner"
        );
        _;
    }

    function withDraw(uint withDrawamount) public restricted{
        balance = balance - withDrawamount;
    }
}