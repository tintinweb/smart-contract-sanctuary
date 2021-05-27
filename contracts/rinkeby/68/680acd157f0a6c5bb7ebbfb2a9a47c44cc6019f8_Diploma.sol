/**
 *Submitted for verification at Etherscan.io on 2021-05-27
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract Diploma {


        string id;
        string mensaje; 


    function escribirDiploma(
        string calldata _id, 
        string calldata _mensaje) public {
            id = _id;
            mensaje = _mensaje;
    }


    function leerDiploma() public view returns (string memory, string memory){
        return (id, mensaje); 
    }
}