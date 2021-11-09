/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract Indice {
    function addRegistro(string memory, string memory) public {}
}

contract RegistroCasamento {

    struct Casamento {
        string nomeNubente1;
        string nomeNubente2;
        uint256 dataCasamento;
        uint16 folha;
        uint32 termo;
        uint256 dataBlock;
        bool hasAnotacao;
    }
    Indice indice;
    uint32 numLivro;
    uint256 dataAberturaLivro;
    uint256 dataFechamentoLivro;
    uint32 termos;
    uint32 versao;
    string tipoContrato = "casamento_civil";
    address owner;

    mapping(string => Casamento) casamentos;

    /// Cria um novo contrato com um número de livro e data de abertura
    constructor(uint32 _numLivro, address _indiceAddress) {
        owner = msg.sender;
        numLivro = _numLivro;
        dataAberturaLivro = block.timestamp;
        indice = Indice(_indiceAddress);
        versao = 1;
    }

    // Endereço do dono do contrato
    function getOwner() public view returns(address){
        return owner;
    }

    // Registra Casamento
    function addCasamento(
            string memory _nomeNubente1,
            string memory _nomeNubente2,
            uint256 _dataCasamento,
            uint16 _folha,
            uint32 _termo,
            string memory _selo
        ) public{
            require(owner == msg.sender, "Unauthorized");
            require(dataFechamentoLivro == 0, "Book already closed!");
            require(casamentos[_selo].folha == 0, "Selo already registered on Blockchain");
            casamentos[_selo] = Casamento(_nomeNubente1, _nomeNubente2, _dataCasamento, _folha, _termo, block.timestamp, false);
            indice.addRegistro(_selo, tipoContrato);
            termos++;
            if(termos == 200) {
                dataFechamentoLivro = block.timestamp;
            }
    }

    function addAnotacaoToCasamento(string memory _selo) public {
        require(owner == msg.sender, "Unauthorized");
        casamentos[_selo].hasAnotacao = true;
    }

    // Retorna a data de fechamento do livro
    function getDataAberturaLivro() public view returns(uint256) {
        return dataAberturaLivro;
    }

    // Retorna a data de fechamento do livro
    function getDataFechamentoLivro() public view returns(uint256) {
        return dataFechamentoLivro;
    }

    //Retorna o número do livro
    function getLivro() public view returns(uint32) {
        return numLivro;
    }

    // Retorna os dados pessoais do RC
    function getDadosPessoais(string memory _selo) public view returns(string memory, string memory){
        return (
            casamentos[_selo].nomeNubente1,
            casamentos[_selo].nomeNubente2
            );
    }
    // Retorna os dados do registro no cartório
    function getDadosCartorio(string memory _selo) public view returns(uint32, uint16, uint32, uint256, bool){
        return (
            numLivro,
            casamentos[_selo].folha,
            casamentos[_selo].termo,
            casamentos[_selo].dataCasamento,
            casamentos[_selo].hasAnotacao
            );
    }
    //Retorna os dados de registro na Blockchain
    function getDadosBlockchain(string memory _selo) public view returns(uint256, address){
        return (
            casamentos[_selo].dataBlock,
            address(this)
            );
    }
}