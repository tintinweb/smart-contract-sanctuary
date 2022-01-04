/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

pragma solidity 0.8.5;

//SPDX-License-Identifier:UNLICENSED
contract SimpleStroage{
    uint myData;
    function SetData(uint newData) public{
        require(newData<10);
        myData = newData;
    }
    function GetData() view public returns(uint){
        return myData;
    } 
}