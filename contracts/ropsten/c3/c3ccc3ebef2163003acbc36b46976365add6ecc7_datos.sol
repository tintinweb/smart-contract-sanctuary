/**
 *Submitted for verification at Etherscan.io on 2021-09-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract datos {

 struct Jugador { 
      string name;
      uint tipo;
      uint cons;
      uint presence;
      uint intelligence;
      uint dext;
      uint ego;
      uint rec;
      uint experience;
   }
Jugador[] jugadores;
uint longitud =0;

function AddJugador(string memory name, uint tipo, uint cons, uint presence, uint intelligence, uint dext, uint ego, uint rec, uint experience) public { // Function
    
Jugador memory j;
j.name = name;
j.tipo = tipo;
j.cons = cons;
j.presence = presence;
j.intelligence = intelligence;
j.dext = dext;
j.ego = ego;
j.rec=rec;
j.experience=experience;
jugadores.push(j);
longitud = longitud+1;
    }

}