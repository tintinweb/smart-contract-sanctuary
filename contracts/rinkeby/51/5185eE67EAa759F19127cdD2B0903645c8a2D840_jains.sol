// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

contract jains {

    // this will get intialized to 0!
    uint256 pvtNumber;
    bool pvtBool;

    struct People {
        uint256 pvtNumber; 
        string name;   
    }
    
    People[] public people;
    mapping(string => uint256) public nameToPvtNumber;
    
    function store(uint256 _pvtNumber) public {
        pvtNumber = _pvtNumber;
    }
    
    function retrieve() public view returns(uint256) {
        return pvtNumber;
    }

     function addperson(string memory _name, uint256 _pvtNumber) public{
        people.push(People(_pvtNumber, _name));
        nameToPvtNumber[_name] = _pvtNumber;
    }
}