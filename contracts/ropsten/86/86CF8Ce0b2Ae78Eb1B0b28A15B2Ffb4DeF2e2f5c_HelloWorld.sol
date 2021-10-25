pragma solidity >=0.7.3;

contract HelloWorld {
    //State variable, publicly accessible, permanently stored in contract storage
    string public message;

    //Emit and envent when update function is called
    //app frontend can be listening for events and react
    event UpdatedMessages(string oldStr, string newStr);

    //Only executed on contract creation
    constructor(string memory initMessage) {
        message = initMessage;
    }

    //public function
    function update(string memory newMessage) public {
        string memory oldMsg = message;
        message = newMessage;

        //emit an event
        emit UpdatedMessages(oldMsg, newMessage);
    }
}