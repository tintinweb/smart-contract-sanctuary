// SPDX-License-Identifier: MIT
// 智能合约

pragma solidity >=0.7.3;

contract HelloWorld {
    event UpdatedMessages(string oldStr, string newStr);

    string public message;

    // 构造方法仅在部署合约时运行一次
    constructor(string memory initMessage) {
        message = initMessage;
    }

    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}