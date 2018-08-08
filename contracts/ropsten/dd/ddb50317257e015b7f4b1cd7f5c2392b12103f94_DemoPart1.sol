pragma solidity ^0.4.24;

contract DemoPart1 {

    mapping(address => string) public messagePool;

    // 合約初始化
    constructor() {
    }
  
    function writeMessage(string _msg) public {
        messagePool[msg.sender] = "DemoPart1合約測試";
    }

    function readMessage() returns(string){
        return messagePool[msg.sender];
    }

}