pragma solidity ^0.4.24;

/*
            ____                     
        / __ \___  ____ ___  ____ 
        / / / / _ \/ __ `__ \/ __ \
      / /_/ /  __/ / / / / / /_/ /
      /_____/\___/_/ /_/ /_/\____/ 
*/



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