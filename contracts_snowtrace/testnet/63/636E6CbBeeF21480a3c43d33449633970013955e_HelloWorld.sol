//Specifies the version of Solidity, using semantic versioning.
//Learn more://solidity.readthedocs.io/en/v8.5.10/layout-of-source-files.html#pragma
pragma solidity >=0.7.3;

//Defines a contract named 'HelloWorld'.
//A contract is a collection of functions and data(its state).
//Once deployed, a contract resides at a specific address on the Ethereum blockchain.
//Learn more: https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html
contract HelloWorld{

    //Emitted when update function is called
    //Smart contract events are a way for your contract to communicate that something happened on the blockchain to your app front-end, which can be 'listening' for certain events and take action when they happen.
    event UpdatedMessages(string oldStr, string newStr);

    //Declares a state variable 'message' of type string.
    //State variables are variables whose values are permanently stored in contract storage.
    string public message1;
    uint public value;
    //Constructors are used to initialize the contract's data.
    constructor(string memory initMessage, uint val){

        message1 = initMessage;
        value = val;
    }

    //A public function that accepts a string argument and updates the 'message' storage variable.
    function update(string memory newMessage, uint val) public{
        string memory oldMsg = message1;
        message1 = newMessage;
        value = val;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}