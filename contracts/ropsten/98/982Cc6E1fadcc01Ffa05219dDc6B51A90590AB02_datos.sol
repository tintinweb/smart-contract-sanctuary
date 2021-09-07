/**
 *Submitted for verification at Etherscan.io on 2021-09-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */

contract datos {

address private owner;
event OwnerSet(address indexed oldOwner, address indexed newOwner);
modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

 function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }










/*
jugador 0: tank
jugador 1: electricidad
jugador 2: hielo
jugador 3: fuego
jugador 4: viento
jugador 5: inventor
jugador 6: telekinetiko
jugador 7: mago oscuro
jugador 8: toxico
jugador 9: libreform
this list is not closed, we may add new type players
*/


struct Jugador { 
      string name;
      uint tipo;
      uint cons;
      uint presence;
      uint intelligence;
      uint dext;
      uint ego;
      uint rec;
   }
Jugador[] public jugadores;
uint public longitud =0;


struct Poder {
    uint owndebuffduration;
    uint rivaldebuffduration;
    uint damage1;
    uint damage2;
    uint damage3;
    uint energycons;
    bool nextiscritical;
    bool cc;
    
}

string[][6] public names_A_to_F;
function addNamesF() public isOwner  {
    names_A_to_F[5] = ["Faythe", "Frank"];
}


/*
Estructura de poder:
ownedbuff, rivaldebuff, damage,energycons, energyrec,nextiscritical, ccamount
poder 0: puñetazo ligero
this list is not closed, we may add new type players
*/

function AddJugador(string memory name, uint tipo, uint cons, uint presence, uint intelligence, uint dext, uint ego, uint rec) public { // Function
    
Jugador memory j;
j.name = name;
j.tipo = tipo;
j.cons = cons;
j.presence = presence;
j.intelligence = intelligence;
j.dext = dext;
j.ego = ego;
j.rec=rec;
jugadores.push(j);
longitud = longitud+1;
    }



function EditJugador(uint id,string memory name, uint tipo, uint cons, uint presence, uint intelligence, uint dext, uint ego, uint rec) public { // Function
    
Jugador memory j;
j.name = name;
j.tipo = tipo;
j.cons = cons;
j.presence = presence;
j.intelligence = intelligence;
j.dext = dext;
j.ego = ego;
j.rec=rec;
jugadores[id]=j;
    }

}