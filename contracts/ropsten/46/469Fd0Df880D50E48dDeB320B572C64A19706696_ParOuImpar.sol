/**
 *Submitted for verification at Etherscan.io on 2021-06-10
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
// terceira versão: armazenamento das partidas passadas, eventos (integração melhor com DAPP) e pagamento de tarifa ao owner

contract ParOuImpar{
    
    event mensagem(string _msg);
    
    struct Jogador {
        address endereco;                   // endereço do jogador
        address payable enderecoPayable;    // endereço Payable do jogador
        uint256 numero;                        // quantidade de dedos abertos na mão do jogador
        string escolha;                     // par ou impar
        bytes32 hash;                       // keccak256 de numero+senha do jogador, de modo a ocultar a quantidade de dedos antes da revelacao
        bool escolheu;                      // registra se o jogador já escolheu ou não o seu número e sua opção par ou ímpar
        bool revelou;                       // registra se o jogador já revelou o seu número
        bool desclassificado;               // aponta se o jogador foi desclassificado porque o keccak256 da senha+numero não bate com o hash armazendo
     }
     
    Jogador public jogador1; 
    Jogador public jogador2; 
    
    
    address public owner;                   // o dono do SC (quem fez o deploy) - para reinicializar o contrato é preciso transferir 1 wei para ele
    address payable public ownerPayable;    // o dono do SC (quem fez o deploy) - para reinicializar o contrato é preciso transferir 1 wei para ele
    uint256 public reinicializaDevidoOwner; // valor devido ao owner para cada reinicialização
    uint256 public percentualDevidoOwner;   // percentual devido ao owner em cada aposta de par ou impar
    uint256 public valorDevidoOwner;        //  valor devido ao owner em cada aposta de par ou impar
    
  
    string public resultado; // Indica se a soma dos numeros informados pelos jogadores é par ou ímpar
    
    string public vencedor; // Indica qual foi o jogador vencedor, a partir da sua escolha e da variável resultado
    
    bool public jogoEncerrado; // Indica que o jogo foi encerrado e pode ser consultado o resultado
    
    mapping(address => mapping(address => string)) public resultadosAnteriores;  // armazena os vencedores anteriores das partidas (jog1xjog2=>vencedor)
    
    uint256 public valorAposta; // valor (em wei) que deve ser depositado por cada jogador - o vencedor recebe de volta o seu e o do vencido, menos o percentual do owner
    
    uint256 public saldoContrato; // saldo do contrato em wei (valores transferidos pelos jogadores)
    
    modifier somenteOwner(string memory _mensagem) {
        require(msg.sender == owner, _mensagem);
        _;
    }
    
    
    constructor(){
        
        owner = msg.sender;
        ownerPayable = payable(owner);
        reinicializaDevidoOwner = 1 wei;
        percentualDevidoOwner = 10;
        
        jogador1.endereco = address(0);
        jogador1.enderecoPayable = payable(jogador1.endereco);
        jogador1.numero = 0;
        jogador1.escolha = "";
        jogador1.hash = "";
        jogador1.escolheu = false;
        jogador1.revelou = false;
        jogador1.desclassificado = false;
        
        jogador2.endereco = address(0);
        jogador2.enderecoPayable = payable(jogador2.endereco);
        jogador2.numero = 0;
        jogador2.escolha = "";
        jogador2.hash = "";
        jogador2.escolheu = false;
        jogador2.revelou = false;
        jogador2.desclassificado = false;
        
        jogoEncerrado = true;
        resultado = "";
        vencedor = "";
        
        valorAposta = 0 wei;
        
    }
    
    function compararStrings(string memory _a, string memory _b) public pure returns (bool iguais){
       
        iguais = (keccak256(bytes(_a)) == keccak256(bytes(_b)));

        return iguais;
        
    }
    
    function append(string memory _a, string memory _b) internal pure returns (string memory) {

    return string(abi.encodePacked(_a, _b));

    }
    
    function converterNumeroString(uint _n) internal pure returns (string memory){
        string[11] memory numeroString=["00", "01", "02", "03", "04", "05", "06", "07", "08", "09", "10"];
        return numeroString[_n];
    }
    
    // "Somente o proprietario pode atualizar a taxa de reinicializacao" - SOPPAATDR
    // "A taxa de reinicializacao foi atualizada"  - ATDRFA
    
    function atualizaReinicializaDevidoOwner(uint _novaTaxa) public somenteOwner("SOPPAATDR"){

         reinicializaDevidoOwner = _novaTaxa * 1 wei;
         
         emit mensagem("ATDRFA");
         
        
    }
    
    // "Somente o proprietario pode atualizar o percentual devido ao proprietario por cada jogada" - SOPPAOPDAPPCJ   
    // "Somente pode atualizar a taxa de reinicializacao quando o jogo estiver encerrado" - SPAATRQOJEE
    // "O percentual devido ao proprietario por cada jogada foi atualizado" - OPDAPPCJFA
    
     function atualizaPercentualDevidoOwner(uint _novoPercentual) public somenteOwner("SOPPAOPDAPPCJ"){
        
         require(jogoEncerrado, "SPAATRQOJEE");
         
         percentualDevidoOwner = _novoPercentual;
         
         emit mensagem("OPDAPPCJFA");
         
        
    }
  
    // "Somente eh possivel reinicializar apos o encerramento do jogo" - SEPRAOEDJ
    // "Somente eh possivel reinicializar com o pagamento de taxa minima ao proprietario" - SEPRCOPDTMAP
    // "O jogo foi reinicializado e a taxa de reinicializacao transferida ao proprietario" - OJFREARDRTAP
    
    function reinicializaParOuImpar(address _jogador1, address _jogador2, uint _valorAposta) payable public {

        // nesta função só é depositada a quantia necessária para pagar o owner pela reinicialização
        // não é paga ainda a aposta
        
        require(jogoEncerrado, "SEPRAOEDJ");
        require(msg.value >= reinicializaDevidoOwner, "SEPRCOPDTMAP");
        
        ownerPayable.transfer(msg.value);    
            
        jogador1.endereco = _jogador1;
        jogador1.enderecoPayable = payable(_jogador1);
        jogador1.numero = 0;
        jogador1.escolha = "";
        jogador1.hash = "";
        jogador1.escolheu = false;
        jogador1.revelou = false;
        jogador1.desclassificado = false;
        
        jogador2.endereco = _jogador2;
        jogador2.enderecoPayable = payable(_jogador2);
        jogador2.numero = 0;
        jogador2.escolha = "";
        jogador2.hash = "";
        jogador2.escolheu = false;
        jogador2.revelou = false;
        jogador2.desclassificado = false;
        
        jogoEncerrado = false;
        resultado = "";
        vencedor = "";
        
        valorAposta = _valorAposta * 1 wei;
        
        emit mensagem("OJFREARDRTAP");
 

    }
    
    // "Apenas o jogador 1 pode escolher o seu numero" - AOJ1PEOSN
    // "O jogador 1 ja fez sua escolha" - OJ1JFSE
    // "So pode escolher par ou impar" - SPEPOI
    // "Os dois jogadores nao podem ambos escolher par" - ODJNPAEP
    // "Os dois jogadores nao podem ambos escolher impar" - ODJNPAEI
    // "Para escolher o seu numero, o jogador 1 deve depositar o valor da aposta" - PEOSNOJ1DDOVDA
    // "O jogador1 escolheu seu numero e opcao" - OJ1ESNEO
    
    function defineNumeroEscolhaJogador1(bytes32 _hash, string memory _escolha) payable public {
          require(msg.sender == jogador1.endereco, "AOJ1PEOSN");
          require(!jogador1.escolheu,"OJ1JFSE");
          require(compararStrings(_escolha, "par") || compararStrings(_escolha, "impar"), "SPEPOI");
          require(!(compararStrings(_escolha, "par") && compararStrings(jogador2.escolha, "par")), "ODJNPAEP");
          require(!(compararStrings(_escolha, "impar") && compararStrings(jogador2.escolha, "impar")), "ODJNPAEI");
          require(msg.value == valorAposta, "PEOSNOJ1DDOVDA");
         
          jogador1.hash = _hash;
          jogador1.escolha = _escolha;
          jogador1.escolheu = true;
          
          emit mensagem("OJ1ESNEO");
          

    }

    // "Apenas o jogador 2 pode escolher o seu numero" - AOJ2PEOSN
    // "O jogador 2 ja fez sua escolha" - OJ2JFSE
    // "So pode escolher par ou impar" - SPEPOI
    // "Os dois jogadores nao podem ambos escolher par" - ODJNPAEP
    // "Os dois jogadores nao podem ambos escolher impar" - ODJNPAEI
    // "Para escolher o seu numero, o jogador 2 deve depositar o valor da aposta" - PEOSNOJ2DDOVDA
    // "O jogador2 escolheu seu numero e opcao" - OJ2ESNEO
    
    function defineNumeroEscolhaJogador2(bytes32  _hash, string memory _escolha) payable public {
          require(msg.sender == jogador2.endereco, "AOJ2PEOSN");
          require(!jogador2.escolheu, "OJ2JFSE");
          require(compararStrings(_escolha, "par") || compararStrings(_escolha, "impar"), "SPEPOI");
          require(!(compararStrings(_escolha, "par") && compararStrings(jogador1.escolha, "par")), "ODJNPAEP");
          require(!(compararStrings(_escolha, "impar") && compararStrings(jogador1.escolha, "impar")), "ODJNPAEI"); 
          require(msg.value == valorAposta, "PEOSNOJ2DDOVDA");
          
          jogador2.hash = _hash;
          jogador2.escolha = _escolha;
          jogador2.escolheu = true;
          
          emit mensagem("OJ2ESNEO");

    }
    
    // "Apenas o jogador 1 pode revelar o seu numero" - AOJ1PROSN
    // "O jogador 1 so pode revelar o seu numero apos fazer sua escolha" - OJ1SPROSNAFSE
    // O jogador 1 so pode revelar o seu numero apos o jogador 2 fazer sua escolha - OJ1SPROSNAOJ2FSE
    // O jogador 1 ja revelou sua jogada - OJ1JRSJ
    // O jogador 1 so pode revelar o seu numero se nao tiver sido desclassificado - OJ1SPROSNSNTSD
    // O jogador 1 foi desclassificado porque escolheu fora da faixa - 00 a 10 - OJ1FDPEFDF
    // O jogador 1 foi desclassificado porque o hash informado no inicio nao bate com o hash calculado - OJ1FDPOHCNINBCOHC
    // "O jogador1 revelou o seu numero" - OJ1ROSN
    
   function revelaNumeroEscolhaJogador1(uint _numero, string memory _senha) public {
          require(msg.sender == jogador1.endereco, "AOJ1PROSN");
          require(jogador1.escolheu, "OJ1SPROSNAFSE");
          require(jogador2.escolheu, "OJ1SPROSNAOJ2FSE");
          require(!jogador1.revelou, "OJ1JRSJ");
          require(!jogador1.desclassificado, "OJ1SPROSNSNTSD");

          jogador1.revelou = true;
           
          if (_numero > 10){
              jogador1.desclassificado = true;   // desclassificado porque escolheu fora da faixa 00-10
              emit mensagem("OJ1FDPEFDF");
              return;
          }
          
          string memory numeroString = converterNumeroString(_numero); 
          
          bytes32 hashCalculado = keccak256(bytes(append(numeroString, _senha))); // o hash calculado precisa ser bytes32
          
          if (hashCalculado != jogador1.hash){
              jogador1.desclassificado = true;   // desclassificado porque o hash informado não bate com o calculado
              emit mensagem("OJ1FDPOHCNINBCOHC");
              return;
          }
          
          jogador1.numero = _numero;
          
          emit mensagem("OJ1ROSN");
          
         
          
    }
    
    // "Apenas o jogador 2 pode revelar o seu numero" - AOJ2PROSN
    // "O jogador 2 so pode revelar o seu numero apos fazer sua escolha" - OJ2SPROSNAFSE
    // O jogador 2 so pode revelar o seu numero apos o jogador 1 fazer sua escolha - OJ2SPROSNAOJ1FSE
    // "O jogador 2 ja revelou sua jogada" - OJ2JRSJ
    // "O jogador 2 so pode revelar o seu numero se nao tiver sido desclassificado" - OJ2SPROSNSNTSD
    // "O jogador 2 foi desclassificado porque escolheu fora da faixa - 00 a 10" - OJ2FDPEFDF
    // "O jogador 2 foi desclassificado porque o hash informado no inicio nao bate com o hash calculado" - OJ2FDPOHININBCOHC
    // "O jogador2 revelou o seu numero" - OJ2ROSN
    
    function revelaNumeroEscolhaJogador2(uint _numero, string memory _senha) public {
          require(msg.sender == jogador2.endereco, "AOJ2PROSN");
          require(jogador2.escolheu, "OJ2SPROSNAFSE");
          require(jogador1.escolheu, "OJ2SPROSNAOJ1FSE");
          require(!jogador2.revelou, "OJ2JRSJ");
          require(!jogador2.desclassificado, "OJ2SPROSNSNTSD");
 
          jogador2.revelou = true;
          
          if ( _numero > 10){
              jogador2.desclassificado = true;   // desclassificado porque escolheu fora da faixa 00-10
              emit mensagem("OJ2FDPEFDF");
              return;
          }
          
          string memory numeroString = converterNumeroString(_numero); 
          
          bytes32 hashCalculado = keccak256(bytes(append(numeroString, _senha))); // o hash calculado precisa ser bytes32
          
          if (hashCalculado != jogador2.hash){
              jogador2.desclassificado = true;   // desclassificado porque o hash informado não bate com o calculado
              emit mensagem("OJ2FDPOHININBCOHC");
              return;
          }
          
          jogador2.numero = _numero;
          
          emit mensagem("OJ2ROSN");
          
          
          
    }
    
    
    // "Apenas os jogadores podem saber o resultado" - AOJPSOR
    // "Os jogadores ainda nao escolheram seus numeros" - OJANESN
    // "Os jogadores ainda nao revelaram seus numeros" - OJANRSN
    // "O jogo ja se encerrou" - OJSSE
    // "Nao houve vencedores porque ambos os jogadores foram desclassificados" - NHVPAOJFD
    // "Nao houve vencedores porque ambos os jogadores foram desclassificados - o valor das apostas sera transferido para o proprietario" - NHVPAOJFDOVDASTPOP
    // O vencedor eh o jogador 2 porque o jogador 1 foi desclassificado- OVEOJ2POJ1FD
    // O vencedor eh o jogador 1 porque o jogador 2 foi desclassificado - OVEOJ1POJ2FD
    // O jogador1 venceu - OJ1V
    // O jogador2 venceu - OJ2V

    
     function resultadoParOuImpar() public returns (string memory _vencedor) {
          require(msg.sender == jogador1.endereco || msg.sender == jogador2.endereco, "AOJPSOR");
          require(jogador1.escolheu && jogador2.escolheu, "OJANESN");
          require(jogador1.revelou && jogador2.revelou, "OJANRSN");
          require(!jogoEncerrado, "OJSSE");
          
          
          string memory _resultado;
          
          jogoEncerrado = true;
          
          saldoContrato = address(this).balance;
          
          if (jogador1.desclassificado && jogador2.desclassificado){
              
              _vencedor = "NHVPAOJFD";
              vencedor = _vencedor;
              resultadosAnteriores[jogador1.endereco][jogador2.endereco]=_vencedor;
              
              // neste caso, todo o valor apostado é transferido para o owner
              ownerPayable.transfer(saldoContrato);
              
              emit mensagem("NHVPAOJFDOVDASTPOP");
              return _vencedor;
          }
          
          // nos casos abaixo, deve ser calculada a taxa do proprietario e transferido este valor para ele
          valorDevidoOwner = (saldoContrato * percentualDevidoOwner) / 100;   // pode haver erro de arredondamento, mas OK, tolerar
          ownerPayable.transfer(valorDevidoOwner);
          
          if (jogador1.desclassificado){
              
              _vencedor = "OVEOJ2POJ1FD";
              vencedor = _vencedor;
              resultadosAnteriores[jogador1.endereco][jogador2.endereco]=_vencedor;
              
              // transferir o saldo do contrato para o jogador 2
              jogador2.enderecoPayable.transfer(saldoContrato - valorDevidoOwner);
              
              
              emit mensagem("OVEOJ2POJ1FD");
              return _vencedor;
          }
          
         if (jogador2.desclassificado){
              
              _vencedor = "OVEOJ1POJ2FD";
              vencedor = _vencedor;
              resultadosAnteriores[jogador1.endereco][jogador2.endereco]=_vencedor;
              
              // transferir o saldo do contrato para o jogador 1
              jogador1.enderecoPayable.transfer(saldoContrato - valorDevidoOwner);
              
              
              emit mensagem("OVEOJ1POJ2FD");
              return _vencedor;
          }
          
          
          if ((jogador1.numero + jogador2.numero) % 2 == 0) {
              _resultado = "par";
          } else {
              _resultado = "impar";
          }
      
          resultado = _resultado;
          
          if (compararStrings(jogador1.escolha, _resultado)){
              _vencedor = "OJ1V";
              
              // transferir o saldo do contrato para o jogador 1
              jogador1.enderecoPayable.transfer(saldoContrato - valorDevidoOwner);
              
          }
          else{
              _vencedor = "OJ2V";
              
              // transferir o saldo do contrato para o jogador 2
              jogador2.enderecoPayable.transfer(saldoContrato - valorDevidoOwner);
          }
          
          vencedor = _vencedor;
          resultadosAnteriores[jogador1.endereco][jogador2.endereco]=_vencedor;
          
          emit mensagem(_vencedor);
          
          return _vencedor;

    }
    
    function consultaVencedor(address _jogador1, address _jogador2) public returns (string memory _vencedor ){
          _vencedor = resultadosAnteriores[_jogador1][_jogador2];

          emit mensagem(_vencedor);
          return _vencedor; 
      }
      
      function atualizaSaldoContrato() public{
      
            saldoContrato=address(this).balance;
      }
    
    // "Apenas o proprietario pode coletar os fundos" - AOPPCOF
    // "Somente eh possivel coletar quando o jogo estiver encerrado" - SEPCQOJEE
    
    function coletarFundos() public somenteOwner("AOPPCOF"){

        // esta funcao permite que o proprietario colete quaisquer fundos que ficarem depositados no contrato após o jogo
        // estar encerrado - o que pode acontecer por alguma falha nas transações do blockchain
        
        require(jogoEncerrado, "SEPCQOJEE");
        
        ownerPayable.transfer(address(this).balance);
        
    }
}