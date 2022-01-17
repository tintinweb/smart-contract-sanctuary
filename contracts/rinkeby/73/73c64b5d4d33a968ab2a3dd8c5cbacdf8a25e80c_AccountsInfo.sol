/**
 *Submitted for verification at Etherscan.io on 2022-01-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

 
//@title AccountsInfo
/*@notice Users can call the contract to set name and age 
for that particular account.
*/
contract AccountsInfo {
    
    struct Account{
        string name;
        uint age;
    }

    mapping (address => Account) public accounts;

    //@dev can set and modify for its own address 
    function setAccountInfo(string memory _name, uint _age) public {
        accounts[msg.sender].name = _name;
        accounts[msg.sender].age = _age;                
    }

    //@dev can return stored values for its own address 
    function getAccountInfo() public view 
        returns (string memory _name, uint _age)
    {
        _name = accounts[msg.sender].name;
        _age = accounts[msg.sender].age;
    }
}