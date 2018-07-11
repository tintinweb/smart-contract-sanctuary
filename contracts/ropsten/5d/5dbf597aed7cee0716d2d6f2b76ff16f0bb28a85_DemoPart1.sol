pragma solidity ^0.4.24;

contract DemoPart1 {

    mapping(address => string) public messagePool;

    // 合約初始化
    constructor() {
    }
    

    function oldWriteMessage(string _msg) public{
        messagePool[msg.sender] = &quot;oldWriteMessage&quot;;
    }

    function writeMessage(string _msg) public {
        messagePool[msg.sender] = &quot;DemoPart1合約測試1&quot;;
    }

    function readMessage() returns(string){
        return messagePool[msg.sender];
    }

}


contract DemoPart2 is DemoPart1 {

    // mapping(address => string) public messagePool;

    // 合約初始化
    constructor() {
    }
  
    function writeMessage(string _msg) public {
      messagePool[msg.sender] = &quot;DemoPart2合約測試....&quot;;
    }

    function readMessage() returns(string){
      return messagePool[msg.sender];
    }

}