/**
 *Submitted for verification at polygonscan.com on 2022-01-03
*/

//define which compiler to use
pragma solidity ^0.5.0;

//contract name is MyFirstPolygonContract 
contract MyFirstPolygonContract {


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