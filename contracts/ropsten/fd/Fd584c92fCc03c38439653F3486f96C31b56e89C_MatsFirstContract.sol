/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

contract MatsFirstContract {

    // declaring a variable
    string public x = "";
    
    // writing a constructor
    constructor(string memory  _x) {
        x = _x;
    }
    
    // setting the variable 
    function setData(string memory  _x) public {
        x = _x;
    }
    
    // getting the variable
    function getData() public view returns (string memory ) {
        return x;
    }
}