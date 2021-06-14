/**
 *Submitted for verification at Etherscan.io on 2021-06-13
*/

pragma solidity 0.5.16;

contract Bolao {
    address private gerente;
    address[] private jogadores;
    address payable private vencedor;

    constructor() public {
        gerente = msg.sender;
    }

    function entrar() public payable {
        // valida o valor da transação (custo) 
        require(msg.value == .1 ether);
        jogadores.push(msg.sender);
    }

    function descobrirGanhador() public restricted {
        uint index = randomico() % jogadores.length;
        vencedor = address(uint160(jogadores[index]));
        // transfere o valor para o ganhador
        vencedor.transfer(address(this).balance);
        jogadores = new address[](0);
        vencedor = address(uint160(0x0)); 
    }

    modifier restricted() {
        require(msg.sender == gerente);
        _;
    }
    
    function getSaldo() public view returns (uint) {
        return uint(address(this).balance);
    }

    function randomico() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, jogadores)));
    }
}