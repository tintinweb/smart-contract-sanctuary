/**
 *Submitted for verification at Etherscan.io on 2021-06-14
*/

pragma solidity 0.5.16;


contract Bolao {
    address private gerente;
    address[] private jogadores;
    address payable private vencedor;

    constructor() public {
        gerente = msg.sender;
    }
    
    // event for EVM logging
    event log(address indexed novoParticipante, bytes32 indexed mensagem);

    function entrar() public payable {
        // valida o valor da transação (custo) 
        require(msg.value == .1 ether, "Taxa de entrada precisa ser 0.1 ETH");
        jogadores.push(msg.sender);
        emit log(msg.sender, "Entrou no bolão");
    }

    function descobrirGanhador() public restricted {
        uint index = randomico() % jogadores.length;
        vencedor = address(uint160(jogadores[index]));
        // transfere o valor para o ganhador
        vencedor.transfer(address(this).balance);
        jogadores = new address[](0);
        vencedor = address(uint160(0x0));
        emit log(vencedor, "Ganhou o bolão");
    }

    modifier restricted() {
        emit log(vencedor, "Tentou executar o sorteio");
        require(msg.sender == gerente, "Somente o gerente do bolão pode efetuar o sorteio");
        _;
    }
    
    function getSaldo() public view returns (uint) {
        return uint(address(this).balance);
    }

    function randomico() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, jogadores)));
    }
}