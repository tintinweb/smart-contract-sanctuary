/**
 *Submitted for verification at BscScan.com on 2021-12-14
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

contract marketplace{
    struct Usuario {
        address wallet;
        uint id;
        string name;
    }
    Usuario[] usuarios;

    function addUsuarioImp(uint _id, string memory _name) external {
        Usuario memory usuario1 = Usuario(msg.sender,_id,_name);
        usuarios.push(usuario1);
    } 
    function addUsuarioExp(uint _id, string memory _name) external {
        Usuario memory usuario2 = Usuario({wallet: msg.sender, id: _id, name: _name});
        usuarios.push(usuario2);
    }
    function addUsuario(uint _id, string memory _name) external {
        usuarios.push(Usuario(msg.sender, _id, _name));
    }
    function nome(uint _position) external view returns(string memory){
        return usuarios[_position].name;
    }
}