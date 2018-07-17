pragma solidity ^0.4.24;


contract DataContract {


    address public callMsgSenderAddr;

    address public theOwner;

    constructor() public{
        theOwner = msg.sender;
    }

    function writeAddr() public{
        callMsgSenderAddr = msg.sender;
    }

    function readAddr() public view returns (address){
        return callMsgSenderAddr;
    }

}