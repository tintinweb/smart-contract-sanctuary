/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

pragma solidity ^0.4.18;
contract ETHhomepage7 {

    struct Collage {
        string Coordenadas;
        string Imagen;
        string Url;
    }

    mapping (uint => Collage) Collages;
    uint[] public contador;

    function guardarimagen (uint _address, string _coordenadas, string _imagen, string _url) public{
        var Collage = Collages[_address];
        Collage.Coordenadas = _coordenadas;
        Collage.Imagen = _imagen;
        Collage.Url = _url;
        contador.push(_address) -1;

    }

    function contador () view public returns(uint[]){
        return contador;
    }
    function leerimagen(uint _address) view public returns(string, string, string){
        return (Collages[_address].Coordenadas,Collages[_address].Imagen, Collages[_address].Url);

    }
    function numerodeimagenes() view public returns(uint){
        return contador.length;
    }
}