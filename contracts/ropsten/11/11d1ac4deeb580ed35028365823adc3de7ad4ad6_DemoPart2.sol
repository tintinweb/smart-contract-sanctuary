pragma solidity ^0.4.24;


contract DemoPart2 {

    mapping(address => string) public messagePool;

    // 合約初始化
    constructor() {
    }

    function writeMessage(string _msg) public {
      messagePool[msg.sender] = &quot;YES123測試OK>>&quot;;
    }

    function readMessage() returns(string){
      return messagePool[msg.sender];
    }

}