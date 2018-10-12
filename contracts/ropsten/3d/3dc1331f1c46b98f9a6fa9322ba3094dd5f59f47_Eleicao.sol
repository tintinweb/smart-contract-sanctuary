pragma solidity ^0.4.24;

// T&#237;tulo: Contrato para vota&#231;&#227;o de elei&#231;&#227;o do nome da Biblioeca do IFTM - Campus Paracatu

// Desenvolvido por: Nataniel P. Santos (<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="c6a8a7b2a7a8afa3aab5a786a1aba7afaae8a5a9ab">[email&#160;protected]</a>)

// Descri&#231;&#227;o: Esse Smart Contract foi desenvolvido com o objetivo de ser utilizaddo para realizar
// a vota&#231;&#227;o da escolha do nome da biblioteca. Sua utliza&#231;&#227;o foi pensada na facilidade do eleitor,
// que receber&#225; o c&#243;digo de acesso por email e realizar&#225; seu voto que ficar&#225; armazenado na blockchain
// p&#250;blica da ethereum (vers&#227;o de teste Ropsten).

// Observa&#231;&#227;o: Esse contrato ser&#225; utilizado em car&#225;ter de testes e apesar de suprir as necessidades
// do caso de uso em que ser&#225; usado, n&#227;o atende a todas as recomenda&#231;&#245;es de seguran&#231;a exigidas para um smart contracts.

//  VANTAGENS

// - Armazenamento dos votos de forma inalter&#225;vel (na rede Ropsten)
// - Auditoria dos votos (qualquer eleitor, ap&#243;s a vota&#231;&#227;o e divulga&#231;&#227;o de resultado, poder&#225; verificar o contrato e os votos realizados)
// - Transpar&#234;ncia (todos os votos ficam dispon&#237;veis na internet e podem ser facilmente verificados )
// - Praticidade (os eleitores realizam o voto pela internet, com c&#243;digo &#250;nico recebido por email)
// - Seguran&#231;a ( o c&#243;digo de vota&#231;&#227;o &#233; enviado para o email do eleitor)
// - Confiabilidade ( ap&#243;s a execu&#231;&#227;o do contrato, seu c&#243;digo n&#227;o pode ser ALTERADO OU ATUALIZADO. Dessa forma, todo processo de vota&#231;&#227;o &#233;
// realizado, organizado e finalizado por um algoritmo, sem interfer&#234;ncia humana de qualquer natureza )

contract Eleicao{

    // Modelo de candidato
    struct Candidato {
        uint id;
        string nome;
        uint voteQuantidade;
    }


    // Eventos
    event eventoConfirmaVoto(uint index_candidatoId);

    // Determina o n&#250;mero m&#225;ximo de eleitores
    uint private NUM_MAX_ELEITORES = 1400;

    // Determina o tempo de dura&#231;&#227;o da vota&#231;&#227;o
    uint public dataFinal;
    uint public dataCriacao;

    // Endere&#231;o de quem critou o contrato
    // address public criador;

    // Armazena as contas de eleitores
    mapping(bytes32 => bool) public eleitores;

    // Armazena os hashes com permiss&#227;o de votar
    mapping(bytes32 => bool ) private hashEleitoresMapping; // lembrar de deixar privado

    bytes32[] public hashEleitoresArray;

    // Determinar a quantidade de hashes
    uint public contador = 0;

    // Armazena as informa&#231;&#245;es sobre os candidatos
    mapping(uint => Candidato) public candidatos;

    // Armazena a quatidade de eleitores
    uint public eleitoresQuantidade;

    // Armazena a quantidade de candidatos
    uint public candidatosQuantidade;

    // Armazena a quantidade de eleitores que j&#225; votaram
    uint public jaVotaram;

    // Esse &#233; o constructor do contrato que &#233; executado uma uńica vez ( na cria&#231;&#227;o do contrato ), e que determina as condi&#231;&#245;es para a vota&#231;&#227;o
    constructor () public {

        // Adiciona os candidatos que podem receber votos
        addCandidato("[1] - An&#237;sio Sp&#237;nola Teixeira");
        addCandidato("[2] - Branca Adjuto Botelho");
        addCandidato("[3] - Jos&#233; Leite Lopes");

        // Determina a data da cria&#231;&#227;o do contrato (timestamp)
        dataCriacao = now;

        // Determina o prazo final para vota&#231;&#227;o, sendo de 3 dias ap&#243;s a cria&#231;&#227;o do contrato
        dataFinal = dataCriacao + 6 * 1 days;

        // O endere&#231;o do criador do contrato
        // criador = msg.sender;

    }

    // // Essa fun&#231;&#227;o permite que o contrato receba ether e que uma vez recebido seja imposs&#237;vel retirar
    // function () payable public{

    // }

    // // Fun&#231;&#227;o modificadora que restringe o acesso &#224; algumas fun&#231;&#245;es apenas para o criador do contrato
    // // Para uma auditoria poderia, por exemplo, permitir acesso s&#243; a um grupo de usu&#225;rios
    // modifier somenteCriador {

    //     require(msg.sender == criador);
    //     _;
    // }

    // Fun&#231;&#227;o privada que adiciona os candidatos na elei&#231;&#227;o
    function addCandidato (string _name)  private {

        candidatosQuantidade ++;
        candidatos[candidatosQuantidade] = Candidato(candidatosQuantidade, _name, 0);

    }

    // func&#227;o que gera os hashes no contrato
     // As chaves de permiss&#227;o de vota&#231;&#227;o foram geradas separadamente,
    // em blocos de 50 por causa do pre&#231;o do gas.
    // Para garantir a seguran&#231;a e transpar&#234;ncia, elas s&#243; podem ser adicionadas
    // em at&#233; uma hora ap&#243;s a cria&#231;&#227;o do contrato

    function geraHash(string _string) public{
        // limita o tempo que essa fun&#231;&#227;o pode ser usada
        require(now <= dataCriacao + 1 hours);

        // limita o n&#250;mero de hashes v&#225;lidos que podem ser gerados
        require(contador < NUM_MAX_ELEITORES);

        for (uint i = 1; i <= 50 ; i++){
            bytes32 _hash = keccak256("eleicaoiftm",abi.encodePacked(i,now,_string,contador));
            hashEleitoresArray.push(_hash);
            hashEleitoresMapping[_hash] = true;
            contador++;
        }
    }

    function votar(uint _candidatoId, bytes32 _hashEleitor) public {

        // Verifica se ainda est&#225; no prazo para votar
        require(now <= dataFinal);

        // valida o candidato
        require(_candidatoId > 0 && _candidatoId <= candidatosQuantidade);

         // impede que o hash nulo seja usado para vota&#231;&#227;o
        eleitores[0x00] = true;

        // hash valida&#231;&#227;o
        require(hashEleitoresMapping[_hashEleitor]);

        // verifica se o _hashEleitor j&#225; foi usado para votar
        require(!eleitores[_hashEleitor]);

        // informa que o _hashEleitor j&#225; votou
        eleitores[_hashEleitor] = true;

        // atualiza a quandidade de votos do canditato
        candidatos[_candidatoId].voteQuantidade ++;

        // incrementa a quantidade de eleitores que votaram
        jaVotaram++;

        //gatilho do evento
        emit eventoConfirmaVoto(_candidatoId);

    }
}