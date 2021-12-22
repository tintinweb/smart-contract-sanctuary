//SPDX-License-Identifier: MIT

pragma solidity >= 0.7.3;

contract HelloWorld{
    //when this event is broadcasted, everyone will see this event happening
    event UpdatedMessages(string oldStr, string newStr);

    //States
    string public message;

    //run only once when smart contract is deployed
    //require an argument to be passed in
    constructor(string memory initMessage){
        message = initMessage;
    }

    //public function to update message
    function update(string memory newMessage) public{
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages((oldMsg), newMessage);
    }
}