pragma solidity ^0.4.24;

contract Eleicao{

    // Modelo de candidato
    struct Candidato {
        uint id;
        string nome;
        uint voteQuantidade;
    }

    //eventostru
  event eventoConfirmaVoto(uint index_candidatoId);

    //GERAR O QRCODE
    //https://chart.googleapis.com/chart?chs=150x150&cht=qr&chl=0x583031d1113ad414f02576bd6afabfb302140225&choe=UTF-8

    // Armazena as contas de eleitores
    mapping(bytes32 => bool) public eleitores;

    bytes32[] public hashEleitoresArray;

    // Read/write candidatos
    mapping(uint => Candidato) public candidatos;

    // Armazena a quatidade de candidatos
    uint public eleitoresQuantidade;

    // Armazena a quantidade de eleitores
    uint public candidatosQuantidade;

    // Armazena a quantidade de eleitores que j&#225; votaram
    uint public jaVotaram;

    constructor (bytes32[] _qtdEleitores) public {

        addCandidato("Nome Comum");
        addCandidato("Nome Legal");
        addCandidato("Nome Estranho");

        eleitoresQuantidade = _qtdEleitores.length;

        hashEleitoresArray = _qtdEleitores;

    }

    function () payable public{

    }

    function addCandidato (string _name) private {

        candidatosQuantidade ++;
        candidatos[candidatosQuantidade] = Candidato(candidatosQuantidade, _name, 0);
    }

    function votar(uint _candidatoId, bytes32 _hashEleitor) public {

        //vari&#225;vel de controle que valida o eleitor
        bool eleitorValido = false;

        // impede que o hash nulo seja usado para vota&#231;&#227;o
        eleitores[0x00] = true;

        // verifica se o eleitor &#233; v&#225;lido e altera a vari&#225;vel de controle
        for(uint i = 0 ; i < hashEleitoresArray.length ; i++){

            if(hashEleitoresArray[i] == _hashEleitor){
                eleitorValido = true;
            }

        }

        //valida o eleitor pela vari&#225;vel de controle
        require(eleitorValido);

        // verifica se o _hashEleitor j&#225; foi usado para votar
        require(!eleitores[_hashEleitor]);

        // valida o candidato
        require(_candidatoId > 0 && _candidatoId <= candidatosQuantidade);

        // informa que o _hashEleitor j&#225; votou
        eleitores[_hashEleitor] = true;

        // atualiza a quandidade de votos do canditato
        candidatos[_candidatoId].voteQuantidade ++;

        // incrementa a quantidade de eleitores que j&#225; qtdJaVotaram
        jaVotaram++;
        //gatilho do evento
        emit eventoConfirmaVoto(_candidatoId);
    }
}