/**
 *Submitted for verification at polygonscan.com on 2021-10-05
*/

pragma solidity >=0.7.0 <0.9.0;


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