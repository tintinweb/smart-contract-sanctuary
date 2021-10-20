/**
 *Submitted for verification at Etherscan.io on 2021-10-20
*/

//define which compiler to use
pragma solidity ^0.5.0;

//contract name is MyFirstFantomContract 
contract MyFirstFantomContract {


    string private name;
    uint private amount;

//set
    function setName(string memory newName) public {
        name = newName;
    }

//get
    function getName () public view returns (string memory) {
        return name;
    }
    
//set
    function setAmount(uint newAmount) public {
        amount = newAmount;      
    }

//get
    function getAmount() public view returns (uint) {
        return amount;
    }
}