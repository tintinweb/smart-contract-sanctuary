// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.ht
pragma solidity >=0.7.3;

// Defines a contract named `HelloWorld`.
// A contract is a collection of functions and data (its state). Once deployed, a c
contract HelloWorld {
    //Emitted when update function is called
    //Smart contract events are a way for your contract to communicate that somethin
    event UpdatedMessages(string oldStr, string newStr);
    // Declares a state variable `message` of type `string`.
    // State variables are variables whose values are permanently stored in contract
    string public message;
    // Similar to many class-based object-oriented languages, a constructor is a spe
    // Constructors are used to initialize the contract's data. Learn more:https://s
    constructor(string memory initMessage) {
        // Accepts a string argument `initMessage` and sets the value into the contra
        message = initMessage;
    }
    // A public function that accepts a string argument and updates the `message` st
    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}