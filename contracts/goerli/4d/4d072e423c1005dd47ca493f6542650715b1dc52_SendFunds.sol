/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

pragma solidity ^0.5.13;

contract SendFunds {
    
  
    // Global Variables 
    

    
    // Functions
    
    
    function checkContractBalance() public view returns(uint) {
        return address(this).balance;
    } // this function allows the user to check the balance of funds in the contract.
    
    function depositFunds() public payable {
        
    }// this function allows the user to deposit funds to the contract.
    
     function sendFundsFromContract(address payable _address, uint256 _amount) payable public {
        _address.transfer(_amount);
    }// this function allows the user to withdraw a specific amount of funds from the contract to a specified address.
}