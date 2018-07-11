pragma solidity ^0.4.24;


contract Demo {

    mapping(address => string) public messagePool;

    // 合約初始化
    constructor() {
    }

    function writeMessage(string _msg) public {
      messagePool[msg.sender] = _msg;
    }

    function readMessage() returns(string){
      return messagePool[msg.sender];
    }

}