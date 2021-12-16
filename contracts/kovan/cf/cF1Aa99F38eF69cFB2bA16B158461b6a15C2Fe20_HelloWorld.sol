pragma solidity >= 0.7.3;

/**
 * The HelloWorld contract does this and that...
 */
contract HelloWorld {

  event UpdatedMessages(string oldStr, string newStr);

  string public message;

  constructor(string memory initMessage) public {
    message = initMessage;
  }

function update (string memory newMessage) public {

  string memory oldMsg = message;
  message = newMessage;
  emit UpdatedMessages(oldMsg, newMessage);

}



}