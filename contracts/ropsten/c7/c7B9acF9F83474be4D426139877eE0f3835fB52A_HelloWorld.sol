pragma solidity ^0.7.3;

contract HelloWorld {
  // Emit when update function is called
  // Smart contract events are a way for your contract to communicate 
  // that something happened on the blockchain to your app front-end, 
  // which can be 'listening' for certain events and take action when they happen.
  event UpdatedMessage(string oldStr, string newStr);

  // Declares a state variable `message` of type `string`.
  // State variables are variables whose values are permanently stored in contract storage. 
  // The keyword `public` makes variables accessible from outside a contract and creates 
  // a function that other contracts or clients can call to access the value.
  string public message;

  constructor(string memory initMessage) {
    message = initMessage;
  }

  function update(string memory newMessage) public {
    string memory oldMsg = message;
    message = newMessage;
    emit UpdatedMessage(oldMsg, newMessage);
  }
}

