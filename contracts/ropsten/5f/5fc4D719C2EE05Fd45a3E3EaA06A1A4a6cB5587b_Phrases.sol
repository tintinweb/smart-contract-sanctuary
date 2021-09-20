pragma solidity ^0.7.3;

contract Phrases 
{
   // evento emitido quando a função update é chamada
   event UpdatedMessages(string oldStr, string newStr);

    // Mensagem que será armazenada no contrato
   string public message;

   constructor(string memory initMessage) 
   {
      message = initMessage;
   }

   // Faz o update da mensagem
   function update(string memory newMessage) public 
   {
      string memory oldMsg = message;
      message = newMessage;
      emit UpdatedMessages(oldMsg, newMessage);
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