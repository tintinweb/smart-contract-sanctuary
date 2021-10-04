/**
 *Submitted for verification at Etherscan.io on 2021-10-04
*/

pragma solidity >=0.5.0 <0.9.0;
 
contract Property10111A{
    // declaring state variables saved in contract's storage
    uint price; // by default is private
    string public location;
    
    
    // setter function, sets a state variable
    function setPrice(uint _price) public{
        int a; // local variable saved on stack
        a = 10;
        price = _price;
    }
    
    function setLocation(string memory _location) public{ //string types must be declared memory or storage
        location = _location;
    }
    
}