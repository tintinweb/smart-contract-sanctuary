/**
 *Submitted for verification at BscScan.com on 2021-08-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract Loteria {

	address payable dono;
	string nomeDoDono;
	uint inicio;

	struct Sorteio {
		uint data;
		uint numeroSorteado;
		//address remetente;
		uint countPalpites;
	}

	Sorteio[]sorteios;

	mapping (address => uint) palpites;
	address payable[]palpiteiros;
	address payable[]ganhadores;

	constructor(string memory _nome) {
		dono = payable(msg.sender);
		nomeDoDono = _nome;
		inicio = block.timestamp;
		// inicio = now;
	}

	modifier apenasDono() {
		require (msg.sender == dono, "Apenas o dono do contrato pode fazer isso");
		_;
	}

	modifier excetoDono() {
		require (msg.sender != dono, "O dono do contrato nao pode fazer isso");
		_;
	}

	event TrocoEnviado(address pagante, uint troco);
	event PalpiteRegistrado(address remetente, uint palpite);

	function enviarPalpite(uint palpiteEnviado) payable public { // excetoDono() {
		require (palpiteEnviado >= 1 && palpiteEnviado <= 60, "Voce tem que escolher um number-1mero entre 1 e 60");

		require (palpites[msg.sender] == 0, "Apenas um palpite pode ser enviado por sorteio");

		require (msg.value >= 1 ether, "A taxa para palpitar e 1 ether");

		// calcula e envia troco
		uint troco = msg.value - 1 ether;
		if ( troco > 0 ) {
			payable(msg.sender).transfer(troco);
			emit TrocoEnviado(msg.sender, troco);
		}

		//registra o palpite
		palpites[msg.sender] = palpiteEnviado;
		palpiteiros.push(payable(msg.sender));
		emit PalpiteRegistrado(msg.sender, palpiteEnviado);
	}
	
	function mostrarEnderecoContaPalpiteSeq(uint ordem) view public returns(uint palpite) {
	    require (ordem <= palpiteiros.length - 1, "Nessa sequencia (posicao) ainda nao ha palpite registrado");
	    
	    address endereco = palpiteiros[ordem];

	    return palpites[endereco];
	}
	
	function mostrarNumeroPalpites() view public returns(uint count) {
	    return palpiteiros.length;
	}
	
	function mostrarNomeContrato() view public returns(string memory _n) {
	    return nomeDoDono;
	}
	
	function mostrarPalpiteSeq(uint ordem ) view public returns(address payable _x) {
	    require (ordem <= palpiteiros.length - 1, "Nessa sequencia (posicao) ainda nao ha palpite registrado");
	    return palpiteiros[ordem];
	}

	event SorteioPostado(uint resultado);
	event PremiosEnviados(uint premioTotal, uint premioIndividual);
	
	function sortear() public apenasDono() returns (uint8 _numeroSorteado) {
	    require (block.timestamp > inicio + 1 minutes, "O sorteio so pode ser feito depois de um intervalo de 1 minuto");
	    
	    require (palpiteiros.length >= 1, "Um minimo de 1 pessoa e exigida para poder sortear");
	    
	    // sortear um número
	    uint8 numeroSorteado = 2;
	    //uint8 numeroSorteado = uint8(keccak256(abi.encodePacked(blockhash(block.number-1))))/64+1; //1000
	    
	    sorteios.push(Sorteio({
	        data: block.timestamp,
	        numeroSorteado: numeroSorteado,
	        //remetente: msg.sender,
	        countPalpites: palpiteiros.length
	    }));
	    emit SorteioPostado(numeroSorteado);
	    
	    // procura os ganhadores
	    for (uint p = 0;p<palpiteiros.length;p++){
	        address payable palpiteiro = palpiteiros[p];
	        if (palpites[palpiteiro] == numeroSorteado){
	            ganhadores.push(palpiteiro);
	        }
	        delete palpites[palpiteiro];
	    }
	    
	    uint premioTotal = address(this).balance;
	
	    if (ganhadores.length > 0 ) {
	        uint premio = premioTotal / ganhadores.length;
	    
	        // envia os Premios
	        for (uint p = 0;p<ganhadores.length;p++) {
	            ganhadores[p].transfer(premio);
	        }
	        emit PremiosEnviados(premioTotal, premio);
	    }
	
	    // resetar o Sorteio
	    delete palpiteiros;
	    delete ganhadores;
	
	    return numeroSorteado;
	}
	
	function matarContrato () public apenasDono() {
	    dono.transfer(address(this).balance);
	    selfdestruct(dono);
	}
	
}