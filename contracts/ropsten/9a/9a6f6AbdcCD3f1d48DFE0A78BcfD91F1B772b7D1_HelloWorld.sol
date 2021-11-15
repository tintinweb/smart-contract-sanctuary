// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.7.3;

contract HelloWorld {
   event UpdatedMessages(string oldStr, string newStr);
   string public message;
   constructor(string memory initMessage) {
      message = initMessage;
   }
   function update(string memory newMessage) public {
      string memory oldMsg = message;
      message = newMessage;
      emit UpdatedMessages(oldMsg, newMessage);
   }
}

