/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";

//Cuanta más instrucciones más GAS

//CONTRATO: Los contratos tienen un address y un balance en theter
//Es como una wallet con saldo + código
//Un smart contract no puede ver cosas de fuera de la blockchain, es decir
//no puede ejecutar APIS externas a la blockchain, no puede ver los
//ficheros de logs, que se guardan fuera de la blockchain, etc.
contract Jefecillo {
    //address es nativo y simple de solicity

    //Si el jefe pudiera recibir ether en algún momento, se tendría 
    //que declarar el address como payable, pero es opcional

    address payable public jefe;



    //struct Humano{
    //    uint edad;
    //    bool esAlto;
    //}
    // enum Helados {Chocolate,Vainilla} 

//Se puede asociar cosas con un mapping
   // mapping (address =>uint) balances; //asocia address a números
   //function getBalance(address alguien) view public return(uint){
   //    return balances[alguien]; //devuelve el uint asociado a ese address
   //}

//Al generar un evento, se guarda en un fichero de logs, FUERA DE LA BLOCKCHAIN
//pero asociado a ella, la información que especifiquemos. Así que guardamos
//el historial de cambios de jefe que se produzcan, para llevar un registro
   //Luego hay programas que le pasas la dirección del contrato y te filtra
   //todos los eventos "JefeTrasferido" que encuentre en los logs del contrato
   //Se pone indexed para facilitar la búsqueda posterior
    event JefeTransferido(address indexed anteriorJefe, address indexed nuevoJefe);

//modificador que se usa en transferirJefe, para que solo el jefe
//actual pueda transferir al jefe. Modificadores que vienen con el lenguaje
//son public, private, internal y external
    modifier soloJefe() {
        //algunas variables globales vienen por defecto en el contrato
        //msg -> quien inicia con un mensaje la operación
        //ej: un contrato puede llamar a otro Carlos -> A -> B -> C
        //Carlos llama al contrato A, msg.sender ==Carlos,  para A 
        //El contrato A llama al contrato B, msg.sender ==A,  para B 
        //El contrato B llama al contrato C, msg.sender ==B,  para C 

        //block -> Cosas que suceden en el bloque donde la transacción
        //está siendo ejecutada. block.blockhash es el hash del bloque
        //block.coinbase es el address del minero que mina el bloque
        //jefe es de tipo address, que viene con alguna función interesante
        //por ejemplo, se puede usar jefe.transfer(10 eth), wei, gwei, etc
        //
        // Al ser de tipo address, se podría usar block.coinbase.transfer
        //o bien block.coinbase.balance, para ver el balance del minero

        //tx -> transaction. tx.origin es quien originó la transacción
       // tx.origin === Carlos para A, para B y para C

       //require(false) revierte todo y solo consume el gas
        require(msg.sender == jefe,"No eres el jefe, no puedes cambiarlo");
        _; //_ ejecuta el cuerpo de la función que tiene el modificador
   //Se podrían poner siguiendo require en las siguientes líneas, y si fallara
   //pues se revertería todo y el cuerpo de la función que tiene el modificador
   //quedaría sin efecto, pero se habría consumido algo de gas. Es bueno, por tanto
   //poner todos los require antes de ejecutar el cuerpo de la función que tiene el modificador
    }

    //cuando se haga deploid en el contrato se inicializa el dueño
    //con el constructor
    constructor(address payable _jefe){
        jefe = _jefe;
        //Se le podría transferir a la cuenta del nuevo jefe dinero
       //paga la cuenta del contrato, hacia jefe, que tiene que ser payable
       //para poder recibir dinero.
        //NO FUNCIONA jefe.transfer(1.5 ether);
        //El constructor podría coger el primer jefe al que deployea
        //el contrato con: jefe = msg.sender;
    }

//la visibilidad puede ser public, private, internal y external
//publica puede ser llamada desde fuera y desde todos los contratos que
//hereden de este. privada solo puede ser usada por este contrato
//internal puede ser usada por este contrato y los que hereden de este, pero
//no cualquiera desde el exterior y external solo puede ser llamada
//desde fuera, no desde dentro de este contrato ni los que heredan
    function transferirJefe (address payable nuevoJefe) soloJefe public {
        address anteriorJefe = jefe;

        jefe = nuevoJefe;
        //Se le podría transferir a la cuenta del nuevo jefe dinero
        //nuevoJefe.transfer(1.5 ether);

        //Se emite el evento para guardarlo en los logs
        emit JefeTransferido(anteriorJefe, nuevoJefe);

        //this se puede usar, pero es como una llamada a otro contrato.
       // this.transferirJefe(nuevoJefe);
       //o bien se puede usar para hacer casting
       //address(this).transfer(1 ether);
    }
}