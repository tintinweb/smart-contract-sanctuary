/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

pragma solidity ^0.5.0;

contract financialContract {
    
    uint balance = 313000;
    address public owner = msg.sender;

    modifier restricted() {
        // only owner can change the value
        require(
          msg.sender == owner,
          "This function is restricted to the contract's owner which is ME"
        );
      _;
    }
    
    // get the balance
    function getBalance() public view returns(uint){
        return balance;
    }
    
    // input new deposit
   function deposit(uint newDeposit) public{
        balance = balance + newDeposit;
    }
    
    // withdraw the deposit
    /*function withdraw(uint _withdraw) public{
        balance = balance - _withdraw;
    }*/
    
    // withdraw the deposit only owner
    function withdraw(uint _withdraw) public restricted{
        balance = balance - _withdraw;
    }
}