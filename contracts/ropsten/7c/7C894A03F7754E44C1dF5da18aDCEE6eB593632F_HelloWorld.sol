//Defines a contract named 'HelloWorld'
//A contract is a collection of functions and data (its state). Once deployed, a contract resides at a specific address on the Eth blockchain
contract HelloWorld{
    //Smart contract events are a way for contract to communicate that something happened on the blockchain to your app FE, which can be listening for certain events and take action
    event UpdatedMessages(string oldStr, string newStr);
    //Declares state var 'message' of type string
    //State vars are variables whose values are permanently stored in contract storage. pub variables are accessible outside contract and creates function that other contracts can access
    string public message;
    //constructors used to init contracts data
    constructor(string memory initMessage){
        message = initMessage;
    }
    // A public function that accespts string arg and updates the 'message' storage variable
    function update(string memory newMessage) public{
        string memory oldMsg = message;
        message = newMessage;
        emit UpdatedMessages(oldMsg, newMessage);
    }
}