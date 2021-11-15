// SPDX-License-Identifier: MIT

// Set Solidity version
pragma solidity 0.8.4;

//name contract HelloWorld
contract HelloWorld {

    // Set a public state variable 'message' to be "Hello World!"
    // Public variables can be accessed outside of this contract
    string public message = "Hello World!";

    // Create private state variable 'owner' as an address
    // Private variables can only be accessed within this contract
    address private owner;

    // Constructor function is executed upon contract creation
    constructor() {

        // Set address of 'owner' to be the address that deployed the contract
        owner = msg.sender;
    }

    // setMessage() updates the state of the state variable 'message'
    function setMessage(string memory _message) public {

        // Require that the address calling this function must be 'owner'
        require(msg.sender == owner, "Function caller is not owner");

        // Set state variable 'message' to be the input parameter that setMessage() was called with
        message = _message;
    }

    // viewMessage() is a public function that any address can call, it returns the value of state variable 'message'
    function viewMessage() public view returns (string memory) {
        return message;
    }

}

