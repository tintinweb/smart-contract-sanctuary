/**
 *Submitted for verification at polygonscan.com on 2021-11-27
*/

// Specifies that the source code is for a version
// of Solidity greater than 0.5.10
pragma solidity ^0.5.10;

// A contract is a collection of functions and data (its state)
// that resides at a specific address on the Ethereum blockchain.
contract HelloWorld {

    string public message;

    string public concatmessage;

    bytes public b;


    constructor(string memory initMessage) public {
        // Takes a string value and stores the value in the memory data storage area,
        // setting `message` to that value
        message = initMessage;
    }

    // A publicly accessible function that takes a string as a parameter
    // and updates `message`
    function update(string memory newMessage) public {
        message = newMessage;
    }
    function update_new(string memory newMessage) public {
      b = abi.encodePacked(newMessage);
      b = abi.encodePacked(b, newMessage);
      concatmessage = string(b);
    }
}