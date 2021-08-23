/**
 *Submitted for verification at Etherscan.io on 2021-08-22
*/

// SPDX-License-Identifier: MIT

// Faucet contract
// Para no tener que dar uno a uno los tokens, tenemos este contrato de "faucet"
//
// ¿Qué es un Faucet? es una forma muy común de distribuir nuevos Tokens.
//
// Consiste en un contrato (que _suele_ tener una página web asociada)
// que distribuye los tokens a quien los solicita.
// Así el que crea el token no tiene que pagar por distribuir los tokens,
// y sólo los interesados 'pagan' a los mineros de la red por el coste de la transacción.

pragma solidity >=0.7.0;


interface iERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Faucet {

   // Vamos a hacer un Faucet_muy_ sencillo:
   //   - No podemos saber de qué país es cada dirección así que:
   //   - Cada dirección de Ethereum debe poder participar en el Airdrop.
   //   - A cada dirección que lo solicite le transferimos 1000 unidades del tocken.
   //   - Sólo se puede participar en el airdrop una sola vez. 
   //   - Si hay algún problema, la transacción _falla_
   
   // Primero necesitamos la dirección del contrato del Token
   
   address public immutable token;
   address public _root;

   // También necesitamos una lista de direcciones.
   // Un "mapping" direccion -> a un 0 o 1 bastaría...
   // .. pero ese tipo de dato no existe en este lenguaje)
   // .. así que hay que construirlo a mano.

   // este es un bitmap (hay formas más eficientes de hacerlo, pero esta nos sirve)   
   mapping (address => uint256) public claimed;
   uint256 public immutable claimAmount;

   event Claimed(address _by, address _to, uint256 _value);
   
   // Cantidad solicitada por cada dirección
   function ClaimedAmount(address index) public view returns (uint256) {
       return claimed[index];
   }
      
   function _setClaimed(address index) private {
       require(claimed[index] == 0);
       claimed[index] += claimAmount;  // No puede desbordar
   }
   
   // Esta funcion es la que permite reclamar los tokens.
   // No hace falta ser el dueño de la dirección para solicitarlo.
   // De todos modos... ¿quién puede querer enviar tokens a otro?
   // Hmm.. ¿puede haber alguna implicación legal de eso?
   
   function Claim(address index) public returns (uint256) {
      // hmm... ¿dejamos que lo haga un smart contract?
      require(msg.sender == tx.origin, "Only humans");

      require(ClaimedAmount(index) == 0 && index != address(0));

      _setClaimed(index);
      // Hacemos la transferencia y revertimos operacion si da algún error
      require(iERC20(token).transfer(index, claimAmount), "Airdrop: error transferencia");
      emit Claimed(msg.sender, index, claimAmount);
      return claimAmount;
   }

   // Cuando acabe el tiempo del airdrop se pueden recuperar
   // a menos que haya alguna logica en el token que no lo permita...

   // Se permite que Recovertokens lo llame un contrato por motivos fiscales.
   // Si se llama a Recovertokens desde una direccion "normal" de Ethereum
   // hacienda nos puede obligar a tributar por tener los tokens durante unos segundos.

   function Recovertokens() public returns (bool) {
      require(tx.origin == _root || msg.sender == _root , "tx.origin is not root");
      uint256 allbalance = iERC20(token).balanceOf(address(this));
      return iERC20(token).transfer(_root, allbalance);
   }

   // SetRoot permite cambiar el superusuario del contrato
   // es decir, la dirección a la que se permite reclamar
   // todos los tokens. Se puede llamar desde un contrato!

   event NewRootEvent(address);

   function SetRoot(address newroot) public {
      require(msg.sender == _root); // sender 
      address oldroot = _root;
      emit NewRootEvent(newroot);
      _root = newroot;
   } 
   
   // Necesitamos construir el contrato (instanciar)
   // Constructor

   constructor(address tokenaddr, uint256 claim_by_addr) {
       token = tokenaddr;
       claimAmount = claim_by_addr;
       _root = tx.origin;  // La persona (humana?) que crea el contrato.
   }

}