pragma solidity ^0.8.0;


contract HelloWorld {

   uint256 public publicIssued;

   event UpdatedMessages(uint256 newVal);

    string public message;

   constructor(string memory initMessage) {
      message = initMessage;
      publicIssued = 0;
   }

   function update(string memory newMessage) public {
      publicIssued += 1;
      message = newMessage;
      emit UpdatedMessages(publicIssued);
   }
}