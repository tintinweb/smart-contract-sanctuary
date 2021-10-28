// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyStorage{
    uint myData;
    function setData(uint _mydata) public {
        myData = _mydata;
    }
    function getData() public view returns(uint ){
        return myData;
    }
}