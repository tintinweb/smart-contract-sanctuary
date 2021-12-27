/**
 *Submitted for verification at polygonscan.com on 2021-12-27
*/

// Licensa do Contrato vai aqui...
pragma solidity >=0.6.0 <0.9.0;

// Contrato
contract HashProvas {

    // Endereco do Admin Principal
    address internal admin;

    // Adicionar Admin Principal
    constructor() {
        admin = msg.sender;
    }

    // Mapping com os Administradores
    mapping(address => bool) internal admins;

    // Array com os Hashes das Provas
    bytes32[] public dataBase;

    // Adicionar outros Admins
    function addAdmin(address new_admin_address) external {
        require(msg.sender == admin, "Apenas Administrador Principal");
        admins[new_admin_address] = true;
    }

    // Funcao para adicionar novos Hashes na Array
    function addData(bytes32 hash) external {
        require(admins[msg.sender] == true, "Apenas Administradores");
        dataBase.push(hash);
    }

    // Funcao que retorna a Array com os Hashes
    function getDataBase() external view returns (bytes32[] memory) {
        return dataBase;
    }

}