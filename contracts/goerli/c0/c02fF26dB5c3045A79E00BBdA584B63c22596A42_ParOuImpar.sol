/**
 *Submitted for verification at Etherscan.io on 2021-05-28
*/

// SPDX-License-Identifier: CC-BY-4.0

pragma solidity 0.8.4;

// Permite que duas pessoas tirem par ou ímpar à distância
// primeira versão: sem proteção (dados poderiam ser consultados por web3)
contract ParOuImpar{
    
     uint private numeroJogador1; // quantidade de dedos abertos na mão do jogador 1
    
     uint private numeroJogador2; // quantidade de dedos abertos na mão do jogador 1
     
    string private escolhaJogador1; // par ou impar
    
    string private escolhaJogador2;  // par ou impar

    address public owner; // o dono do SC (quem fez o deploy), que tem o poder de reinicializar, de modo que novos jogadores possam jogar
    
    address public jogador1; 
    
    address public jogador2;
    
    bool private jogador1Escolheu;
    
    bool private jogador2Escolheu;
    
    string public resultado; // Indica se a soma dos numeros informados pelos jogadores é par ou ímpar
    
    string public vencedor; // Indica qual foi o jogador vencedor, a partir da sua escolha e da variável resultado
    
    
    constructor(address _jogador1, address _jogador2){
        owner = msg.sender;
        jogador1 = _jogador1;
        jogador2 = _jogador2;
        
        numeroJogador1 = 0;
        escolhaJogador1 = "";
        numeroJogador2 = 0;
        escolhaJogador2 = "";
        
        jogador1Escolheu = false;
        jogador2Escolheu = false;
        
        resultado = "";
        vencedor = "";
        
    }
    
    function compararStrings(string memory _a, string memory _b) public pure returns (bool iguais){
       
        iguais = (keccak256(bytes(_a)) == keccak256(bytes(_b)));

        return iguais;
        
    }
    
    function reinicializaParOuImpar(address _jogador1, address _jogador2) public {
            require(msg.sender == owner, "Apenas o proprietario do contrato pode reinicializar");
            jogador1 = _jogador1;
            jogador2 = _jogador2;
            
            numeroJogador1 = 0;
            escolhaJogador1 = "";
            numeroJogador2 = 0;
            escolhaJogador2 = "";
            
            jogador1Escolheu = false;
            jogador2Escolheu = false;
            
            resultado = "";
            vencedor = "";
 

    }
    
    function defineNumeroEscolhaJogador1(uint _numero, string memory _escolha) public {
          require(msg.sender == jogador1, "Apenas o jogador 1 pode escolher o seu numero");
          require(!jogador1Escolheu, "O jogador 1 ja fez sua escolha");
          require(compararStrings(_escolha, "par") || compararStrings(_escolha, "impar"), "So pode escolher par ou impar");
          require(!(compararStrings(_escolha, "par") && compararStrings(escolhaJogador2, "par")), "Os dois jogadores nao podem ambos escolher par");
          require(!(compararStrings(_escolha, "impar") && compararStrings(escolhaJogador2, "impar")), "Os dois jogadores nao podem ambos escolher impar"); 
         
          numeroJogador1 = _numero;
          escolhaJogador1 = _escolha;
          jogador1Escolheu = true;
          


    }
    
    function defineNumeroJogador2(uint _numero, string memory _escolha) public {
          require(msg.sender == jogador2, "Apenas o jogador 2 pode escolher o seu numero");
          require(!jogador2Escolheu, "O jogador 2 ja fez sua escolha");
          require(compararStrings(_escolha, "par") || compararStrings(_escolha, "impar"), "So pode escolher par ou impar");
          require(!(compararStrings(_escolha, "par") && compararStrings(escolhaJogador1, "par")), "Os dois jogadores nao podem ambos escolher par");
          require(!(compararStrings(_escolha, "impar") && compararStrings(escolhaJogador1, "impar")), "Os dois jogadores nao podem ambos escolher impar"); 
         
          numeroJogador2 = _numero;
          escolhaJogador2 = _escolha;
          jogador2Escolheu = true;
          


    }
    
     function resultadoParOuImpar() public returns (string memory _vencedor) {
          require(msg.sender == jogador1 || msg.sender == jogador2, "Apenas os jogadores podem saber o resultado");
          require(jogador1Escolheu && jogador2Escolheu, "Os jogadores ainda nao escolheram seus numeros");
          
          string memory _resultado;
          if ((numeroJogador1 + numeroJogador2) % 2 == 0) {
              _resultado = "par";
          } else {
              _resultado = "impar";
          }
      
          resultado = _resultado;
          
          if (compararStrings(escolhaJogador1, _resultado)){
              _vencedor = "O jogador1 venceu";
          }
          else{
              _vencedor = "O jogador2 venceu";
          }
          
          vencedor = _vencedor;
          return _vencedor;

    }
    
}