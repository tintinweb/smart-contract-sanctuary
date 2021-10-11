/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

pragma solidity  ^0.8.0;


// SPDX-License-Identifier: MIT
contract Tests {
    uint256 aadharNumber;
    
    constructor(uint256 _aadharNumber){
       aadharNumber = _aadharNumber; 
    }
    
    function getAadharNumber()public view returns(uint256){
    return aadharNumber;
}
}


contract Test is Tests{
    
    string private firstName;
    string private lastName;
    
    constructor(string memory _firstName, string memory _lastName, uint256 _aadharNumber) Tests(_aadharNumber) {
        firstName = _firstName;
        lastName = _lastName;
    }
    
    function getFirstName()public view returns(string memory){
        return firstName;
    }

    function getLastName()public view returns(string memory){
        return lastName;
    }
}