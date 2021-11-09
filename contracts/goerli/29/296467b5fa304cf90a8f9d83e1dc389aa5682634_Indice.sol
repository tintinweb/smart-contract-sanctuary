/**
 *Submitted for verification at Etherscan.io on 2021-11-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Indice {
    struct Registro {
        address contrato;
        string tipo;
    }
    //indice[selo=>Registro]
    mapping(string => Registro) private indice;
    mapping(address => bool) private authorizedAddress;
    mapping(string => address) private livrosAdress;
    mapping(string => uint256) private totalRegistros;

    address owner;

    constructor() {
        owner = msg.sender;
    }

    function addRegistro(string memory _seloDigital, string memory _tipo) public{
        require(authorizedAddress[msg.sender] == true, "Unauthorized");
        indice[_seloDigital] = Registro(msg.sender, _tipo);
        totalRegistros[_tipo]++;
    }

    function getSeloAddress(string memory _seloDigital) public view returns(address, string memory){
        return (
            indice[_seloDigital].contrato,
            indice[_seloDigital].tipo
        );
    }

    function getLivroAddress(string memory _livro) public view returns(address){
        return livrosAdress[_livro];
    }

    function authorizeAddress(address _addressLivro) public{
        require(owner == msg.sender, "Unauthorized");
        authorizedAddress[_addressLivro] = true;
    }

    function addLivro(string memory _livro, address _addressLivro) public{
        require(owner == msg.sender, "Unauthorized");
        livrosAdress[_livro] = _addressLivro;
        authorizedAddress[_addressLivro] = true;
    }

    function isAuthorized(address _addressLivro) public view returns(bool){
        return authorizedAddress[_addressLivro];
    }

    function getTotalRegistros(string memory _tipo) public view returns(uint256){
        return totalRegistros[_tipo];
    }

}