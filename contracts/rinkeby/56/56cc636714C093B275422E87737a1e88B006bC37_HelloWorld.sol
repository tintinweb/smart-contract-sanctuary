// Using Alchemy docs
// Credit to Albert @thatguyintech

// Require minimum version of solidity
pragma solidity >=0.7.3;

// Define a contract called HelloWorld
contract HelloWorld {

   event UpdatedMessages(string oldStr, string newStr);

   // Create state variable for string with keyword "public"
   string public message;

   // Initialize message when contract is created
   constructor(string memory initMessage) {

      // Set message to input "initMessage"
      message = initMessage;
   }

   // Update "message" var
   function update(string memory newMessage) public {
      string memory oldMsg = message;
      message = newMessage;
      emit UpdatedMessages(oldMsg, newMessage);
   }
}