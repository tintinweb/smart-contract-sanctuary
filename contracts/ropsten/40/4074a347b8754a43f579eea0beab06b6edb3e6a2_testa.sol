/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

pragma solidity ^0.4.17;

contract testa{
    uint myData = 100;
    function readData()public view returns(uint){
        return myData;
    }
    function changeData(uint data) public{
        myData = data;
    }
    function findMsg() public view returns(address) { 
        return msg.sender;
    }
}