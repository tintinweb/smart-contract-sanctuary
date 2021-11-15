//Specifies the version of solidity, using semantic versioning
pragma solidity ^0.7.3;

// defines a contract named "Hello World"
// a contract is a collection of functions and data(its state). once deployed a contract resides at a specific address on the ethereum blockchain.
contract HelloWorld{
    //Emmited when update function is called 
    //Smart contract events are a way for your contract to communicate that something happened on the blockchain to your app front-end, which can be 'listening'
    //for certain events and take action when they happen
    event UpdatedMessages(string oldStr, string newStr);

    //Declares a state variable 'message' of type 'string'
    //State variables are variables whose values are permianently stored in contract storage. The keyword 'public' makes variables acessible 
    //from outside a contract and creates a function that other contracts or clients can call to access the value.
    string public message;

    //Similar to many class-based object-oriented languages, a constructor is a special function that is only executed upon contract creation
    //Constructors are used to initilize the contracts data. 
    constructor(string memory initMessage){
        //accepts a string argument 'initMessage' and sets the value into the contracts 'message' storage variable
        message = initMessage;

    }
    // A public function that accepts a string argument and updates the 'message' storage variable
    function update(string memory newMessage) public{
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }



    



}

