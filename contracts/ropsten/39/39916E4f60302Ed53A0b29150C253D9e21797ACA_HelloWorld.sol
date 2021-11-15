// Solidity versioning
pragma solidity ^0.7.3;

// Contract named HelloWorld.
// Consists of functions and data (state).
// Will reside on a specific address on the ethereum blockchain.
contract HelloWorld {

  // Emitted when update function is called
  event UpdatedMessages(string oldStr, string newStr);

  // state variable of type string.
  // permanently stored in contract storage.
  // public means accessible from outside contract.
  string public message;

  // Executed on creation.
  constructor(string memory initMessage) {
    // sets the initial message value.
    message = initMessage;
  }

  // public function that accepts a string argument
  // and updates the message and emits event after.
  function update(string memory newMessage) public {
    string memory oldMsg = message;
    message = newMessage;
    emit UpdatedMessages(oldMsg, newMessage);
  }
}

