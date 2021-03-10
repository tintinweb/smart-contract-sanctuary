/**
 *Submitted for verification at Etherscan.io on 2021-03-10
*/

//SPDX-License-Identifier: GPL-3
pragma solidity ^0.8.0;


contract SimpleStorage{

    //uint == uint256
    uint storeddata;
    string name;

    event Newnumber(
        uint _number
    );

    event Newstring(
        string _number
    );
    
    

    function set(uint x) public {
        storeddata = x;
        // generar un evento.
        // en el momento en el que se realiza un cambio, se notifica a todos 
        // los clientes que se han registrado con el SC (se han suscrito a sus eventos)
        emit Newnumber(storeddata);
    }

    function get() public view returns(uint) {
        return storeddata;
    }
    
    //function setName(string memory x) public {
    function setName(string calldata x) public {
        name = x;
        emit Newstring(name);
    }
   

}