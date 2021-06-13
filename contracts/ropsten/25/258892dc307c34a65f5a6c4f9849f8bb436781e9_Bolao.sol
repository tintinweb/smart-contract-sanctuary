/**
 *Submitted for verification at Etherscan.io on 2021-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;


contract Bolao{
    address gerente;
    address[]  private jogadores;
    address payable private vencedor;

    constructor() {
        gerente = msg.sender;
    }

    function entrar() public payable{
        require(msg.value >= 1 ether);
        jogadores.push(msg.sender);
    }

    function escolherGanhador() public restricted {
        uint index = randomico() % jogadores.length;
        vencedor = payable(jogadores[index]);
        vencedor.transfer(address(this).balance);
        limpar();
    }

    modifier restricted {
        require(msg.sender == gerente);
        _;
    }

    function getJogadores() public view returns (address[] memory){
        return jogadores;
    }

    function getGerente() public view returns (address){
        return gerente;
    }

    function getSaldo() public view returns (uint){
        return address(this).balance;
    }

    function limpar() private{
        jogadores = new address[](0);
    }

    function randomico() public view returns (uint){
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, jogadores)));
    }
}