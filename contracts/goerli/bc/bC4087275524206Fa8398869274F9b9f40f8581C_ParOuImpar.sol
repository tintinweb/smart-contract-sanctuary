/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

// SPDX-License-Identifier: CC-BY-4.0

pragma solidity 0.8.4;

// Permite que duas pessoas tirem par ou ímpar à distância
// primeira versão: sem proteção (dados poderiam ser consultados por web3)
// segunda versão: com proteção de dados - primeiro o jogador informa o hash (numero e senha)
// o hash fica armazenado, mas não permite identificar qual foi o número escolhidos (por causa da senha)
// quando os dois jogadores tiverem jogado, é liberada a função revela jogada
// ela recebe o número escolhido e a senha e faz o hash, comparando com o hash armazenado - se erro, jogador desclassificado
// se correto, armazena o número e a senha e segue como antes

contract ParOuImpar{
    
    event mensagem(string _msg);
    
     uint public numeroJogador1; // quantidade de dedos abertos na mão do jogador 1
    
     uint public numeroJogador2; // quantidade de dedos abertos na mão do jogador 1
     
    string public escolhaJogador1; // par ou impar
    
    string public escolhaJogador2;  // par ou impar
    
    bytes32 public hashJogador1; // par ou impar
    
    bytes32 public hashJogador2;  // par ou impar
    
    address public owner; // o dono do SC (quem fez o deploy), que tem o poder de reinicializar, de modo que novos jogadores possam jogar
    
    address public jogador1; 
    
    address public jogador2;
    
    bool public jogador1Escolheu;
    
    bool public jogador2Escolheu;
    
    
    bool public jogador1Revelou;
    
    bool public jogador2Revelou;
    
    
    bool public jogador1Desclassificado;
    
    bool public jogador2Desclassificado;
    
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
        
        jogador1Revelou = false;
        jogador2Revelou = false;
        
        jogador1Desclassificado = false;
        jogador2Desclassificado = false;
        
        hashJogador1 = "";
        hashJogador1 = "";
        
        resultado = "";
        vencedor = "";
        
    }
    
    function compararStrings(string memory _a, string memory _b) public pure returns (bool iguais){
       
        iguais = (keccak256(bytes(_a)) == keccak256(bytes(_b)));

        return iguais;
        
    }
    
    function append(string memory _a, string memory _b) internal pure returns (string memory) {

    return string(abi.encodePacked(_a, _b));

    }
    
    function converterNumeroString(uint _n) internal pure returns (string memory){
        string[100] memory numeroString=["00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12", "13", "14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27", "28", "29", "30", "31", "32", "33", "34", "35", "36", "37", "38", "39", "40", "41", "42", "43", "44", "45", "46", "47", "48", "49", "50", "51", "52", "53", "54", "55", "56", "57", "58", "59", "60", "61", "62", "63", "64", "65", "66", "67", "68", "69", "70", "71", "72", "73", "74", "75", "76", "77", "78", "79", "80", "81", "82", "83", "84", "85", "86", "87", "88", "89", "90", "91", "92", "93", "94", "95", "96", "97", "98", "99"];
        return numeroString[_n];
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
            
            jogador1Revelou = false;
            jogador2Revelou = false;
            
            jogador1Desclassificado = false;
            jogador2Desclassificado = false;
            
            hashJogador1 = "";
            hashJogador1 = "";
            
            resultado = "";
            vencedor = "";
 

    }
    
    function defineNumeroEscolhaJogador1(bytes32 _hash, string memory _escolha) public {
          require(msg.sender == jogador1, "Apenas o jogador 1 pode escolher o seu numero");
          require(!jogador1Escolheu, "O jogador 1 ja fez sua escolha");
          require(compararStrings(_escolha, "par") || compararStrings(_escolha, "impar"), "So pode escolher par ou impar");
          require(!(compararStrings(_escolha, "par") && compararStrings(escolhaJogador2, "par")), "Os dois jogadores nao podem ambos escolher par");
          require(!(compararStrings(_escolha, "impar") && compararStrings(escolhaJogador2, "impar")), "Os dois jogadores nao podem ambos escolher impar"); 
         
          hashJogador1 = _hash;
          escolhaJogador1 = _escolha;
          jogador1Escolheu = true;
          

    }

    
    function defineNumeroEscolhaJogador2(bytes32  _hash, string memory _escolha) public {
          require(msg.sender == jogador2, "Apenas o jogador 2 pode escolher o seu numero");
          require(!jogador2Escolheu, "O jogador 2 ja fez sua escolha");
          require(compararStrings(_escolha, "par") || compararStrings(_escolha, "impar"), "So pode escolher par ou impar");
          require(!(compararStrings(_escolha, "par") && compararStrings(escolhaJogador1, "par")), "Os dois jogadores nao podem ambos escolher par");
          require(!(compararStrings(_escolha, "impar") && compararStrings(escolhaJogador1, "impar")), "Os dois jogadores nao podem ambos escolher impar"); 
          
          hashJogador2 = _hash;
          escolhaJogador2 = _escolha;
          jogador2Escolheu = true;
          


    }
    
   function revelaNumeroEscolhaJogador1(uint _numero, string memory _senha) public {
          require(msg.sender == jogador1, "Apenas o jogador 1 pode revelar o seu numero");
          require(jogador1Escolheu, "O jogador 1 so pode revelar o seu numero apos fazer sua escolha");
          require(jogador2Escolheu, "O jogador 1 so pode revelar o seu numero apos o jogador 2 fazer sua escolha");
          require(!jogador1Desclassificado, "O jogador 1 so pode revelar o seu numero se nao tiver sido desclassificado");

           jogador1Revelou = true;
           
          if (_numero < 0 || _numero > 99){
              jogador1Desclassificado = true;   // desclassificado porque escolheu fora da faixa 00-99
              emit mensagem("O jogador 1 foi desclassificado porque escolheu fora da faixa - 00 a 99");
              return;
          }
          
          string memory numeroString = converterNumeroString(_numero); 
          
          bytes32 hashCalculado = keccak256(bytes(append(numeroString, _senha))); // o hash calculado precisa ser bytes32
          
          if (hashCalculado != hashJogador1){
              jogador1Desclassificado = true;   // desclassificado porque escolheu fora da faixa 00-99
              emit mensagem("O jogador 1 foi desclassificado porque o hash informado no inicio nao bate com o hash calculado");
              return;
          }
          
          numeroJogador1 = _numero;
          
         
          
    }
    
    function revelaNumeroEscolhaJogador2(uint _numero, string memory _senha) public {
          require(msg.sender == jogador2, "Apenas o jogador 2 pode revelar o seu numero");
          require(jogador2Escolheu, "O jogador 2 so pode revelar o seu numero apos fazer sua escolha");
          require(jogador1Escolheu, "O jogador 2 so pode revelar o seu numero apos o jogador 1 fazer sua escolha");
          require(!jogador2Desclassificado, "O jogador 2 so pode revelar o seu numero se nao tiver sido desclassificado");
 
          jogador2Revelou = true;
          
          if (_numero < 0 || _numero > 99){
              jogador2Desclassificado = true;   // desclassificado porque escolheu fora da faixa 00-99
              emit mensagem("O jogador 2 foi desclassificado porque escolheu fora da faixa - 00 a 99");
              return;
          }
          
          string memory numeroString = converterNumeroString(_numero); 
          
          bytes32 hashCalculado = keccak256(bytes(append(numeroString, _senha))); // o hash calculado precisa ser bytes32
          
          if (hashCalculado != hashJogador2){
              jogador2Desclassificado = true;   // desclassificado porque escolheu fora da faixa 00-99
              emit mensagem("O jogador 2 foi desclassificado porque o hash informado no inicio nao bate com o hash calculado");
              return;
          }
          
          numeroJogador2 = _numero;
          
          
          
    }
    
    
     function resultadoParOuImpar() public returns (string memory _vencedor) {
          require(msg.sender == jogador1 || msg.sender == jogador2, "Apenas os jogadores podem saber o resultado");
          require(jogador1Escolheu && jogador2Escolheu, "Os jogadores ainda nao escolheram seus numeros");
          require(jogador1Revelou && jogador2Revelou, "Os jogadores ainda nao revelaram seus numeros");
          
          string memory _resultado;
          
          if (jogador1Desclassificado && jogador1Desclassificado){
              
              _vencedor = "Nao houve vencedores porque ambos os jogadores foram desclassificados";
              vencedor = _vencedor;
              return _vencedor;
          }
          
          if (jogador1Desclassificado){
              
              _vencedor = "O vencedor eh o jogador 2 porque o jogador 1 foi desclassificado";
              vencedor = _vencedor;
              return _vencedor;
          }
          
         if (jogador2Desclassificado){
              
              _vencedor = "O vencedor eh o jogador 1 porque o jogador 2 foi desclassificado";
              vencedor = _vencedor;
              return _vencedor;
          }
          
          
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