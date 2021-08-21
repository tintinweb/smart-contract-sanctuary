pragma solidity ^0.7.0;

contract HelloWorld {
    //declare a state variable - value permanently stored in contract storage. The keyword 'public'
    //makes variable accessible from outside a contract and creates a function that other contracts or clients
    //can call to access its value (Getter).
    string public message;

    //executed upon contract creation - creates the object
    constructor(string memory initMessage) {
        message = initMessage;
    }

    //public function that accets a string argument and updates the message store variable
    function update(string memory newMessage) public {
        message = newMessage;
    }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}