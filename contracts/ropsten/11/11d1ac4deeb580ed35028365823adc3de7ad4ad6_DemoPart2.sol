pragma solidity ^0.4.24;


contract DemoPart2 {

    mapping(address => string) public messagePool;

    // 合約初始化
    constructor() {
    }

    function writeMessage(string _msg) public {
      messagePool[msg.sender] = "YES123測試OK>>";
    }

    function readMessage() returns(string){
      return messagePool[msg.sender];
    }

}