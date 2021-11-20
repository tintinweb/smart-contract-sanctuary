// Especifica la versión de Solidity, usando versiones semánticas.
// Más información: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma

pragma solidity >=0.7.3;

// Define un contrato llamado `HelloWorld`.
// Un contrato es una colección de funciones y datos (su estado). Una vez implementado, un contrato reside en una dirección específica en la cadena de bloques Ethereum. Más información: https://solidity.readthedocs.io/en/v0.5.10/structure-of-a-contract.html

contract HelloWorld {

   // Emitido cuando se llama a la función de actualización
   // Los eventos de contrato inteligente son una forma de que su contrato comunique que algo sucedió en la cadena de bloques al front-end de su aplicación, que puede estar 'escuchando' ciertos eventos y tomar medidas cuando suceden.

   event UpdatedMessages (string oldStr, string newStr);

   // Declara una variable de estado `mensaje` de tipo` cadena`.
   // Las variables de estado son variables cuyos valores se almacenan permanentemente en el almacenamiento del contrato. La palabra clave `público` hace que las variables sean accesibles desde fuera de un contrato y crea una función que otros contratos o clientes pueden llamar para acceder al valor.

   string public message;

   // Similar a muchos lenguajes orientados a objetos basados ​​en clases, un constructor es una función especial que solo se ejecuta al crear el contrato.
   // Los constructores se utilizan para inicializar los datos del contrato. Más información: https: //solidity.readthedocs.io/en/v0.5.10/contracts.html#constructors

   constructor(string memory initMessage) {

      // Acepta un argumento de cadena `initMessage` y establece el valor en la variable de almacenamiento` message` del contrato).

      message = initMessage;
   }
   
   // Una función pública que acepta un argumento de cadena y actualiza la variable de almacenamiento `message`.

   function update(string memory newMessage) public {
      string memory oldMsg = message;
      message = newMessage;
      emit UpdatedMessages(oldMsg, newMessage);
   }
}