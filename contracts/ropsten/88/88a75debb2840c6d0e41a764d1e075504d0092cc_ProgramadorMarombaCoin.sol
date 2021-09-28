/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// Definindo versao do solidity para criar o contrato
pragma solidity 0.7.0;

// Criando uma biblioteca de codigos, e ainda por cima evitando overflow e underflow
library SafeMath {
    // ----------------- REPLICANDO A LIB SAFEMATH PARA ENTENDER O FUNCIONAMENTO DA MESMA ----------------
    // Essas funcoes agora sao internal e o usuario nao pode ve-las
    function addSafe(uint a,uint b) internal pure returns(uint){
        uint c = a + b;
        require(c >= a , "Sum Overflow!");

        return c;
    }

    function subSafe(uint a,uint b) internal pure returns(uint){
        require(b <= a , "Sub Overflow!");
        uint c = a - b;
        
        return c;
    }

    function mulSafe(uint a,uint b) internal pure returns(uint){
        // Impede multiplicacao por 0
        if(a == 0){
            return 0;
        }

        uint c = a * b;
        require(c / a == b , "Mult Overflow!");
        
        return c;
    }
    // Funcao de divisao nao tem como dar overflow 
    function divSafe(uint a,uint b) internal pure returns(uint){
        uint c = a / b;
        
        return c;
    }
}

contract Ownable {
    
    // Ao declarar uma variavel owner é necessario definir ela como payable
    address payable public owner;
    
    // Criando um evento que seja chamado quando uma funcao for executada
    event OwnershipTransferred(address newOwner);

    // Funcao default que define a carteira que fez o deploy do contrato como owner
    // Essa funcao roda uma unica vez na vida junto com o contrato
    constructor() public {
        owner = msg.sender;
    }

    // Funcao modifier pode ser incluida na chamada de outras funcoes
    // Nesse caso ela vai validar se o executor da funcao é o dono dela ou nao
    modifier onlyOwner(){
        require(msg.sender == owner, "you are not the owner!");
        // Caso o modifier seja verdadeira essa linha executa o resto da funcao
        _;
    }

    // Criando funcao para tansferir a posse do contrato, somente o dono pode chamar essa funcao
    function transferOwnership(address payable newOwner) onlyOwner public {
        // Inserindo na variavel o novo owner
        owner = newOwner;

        // Emitindo evento da transferencia de conta
        emit OwnershipTransferred(owner);
    }



}

// Padrao ERC20 defini quais funcoes padrao a variavel de token deve conter

contract ERC20 {
    // function totalSupply() public view returns (uint);
    // function balanceOf(address tokenOwner) public view returns (uint balance);
    // function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    // function transfer(address to, uint tokens) public returns (bool success);
    // function approve(address spender, uint tokens) public returns (bool success);
    // function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract BasicToken is Ownable, ERC20 {
    // Importacao da biblioteca safemath
    using SafeMath for uint;

    
    // Definindo variavel interna comecando com underscore
    uint internal _totalSupply;
    mapping(address => uint) internal _balances;

    // Mapping encadeado
    // Endereco => Endereco => uint
    // Evite ao maximo encadear mais que dois
    mapping(address => mapping(address => uint)) internal _allowed;

    

    // Retorna o supply do token
    function totalSupply() public view returns (uint){
        return _totalSupply;
    }

    // Retorna o saldo da carteira informada
    function balanceOf(address tokenOwner) public view returns (uint balance){
        return _balances[tokenOwner];
    }

    // Transferecnia de tokens entre carteiras
    function transfer(address to,uint tokens) public returns (bool success){
        // Valida se quem esta enviando tem o numero de token para enviar;
        require(_balances[msg.sender] >= tokens);
        
        // Validacao para que transferencia não seja realizada para carteira de queima
        require(to != address(0));

        // Subtrai o numero de token da carteira de quem envia
        _balances[msg.sender] = _balances[msg.sender].subSafe(tokens);
        // Adicionar o token para carteira de quem recebe
        _balances[to] = _balances[to].addSafe(tokens);

        // Emitindo evento de transferencia de token
        // msg.sender quem transferiu
        // to quem recebe
        // Quantidade
        emit Transfer(msg.sender,to,tokens);

        return true;
    }

    // Funcao que msg.sender vai aprovar que o spender vai gastar x numero de tokens
    function approve(address spender, uint tokens) public returns (bool success){
        // Adiciona valor na variavel _allowed
        _allowed[msg.sender][spender] = tokens;
        // Emite um evento de aproval seguindo padrao ERC20
        emit Approval(msg.sender,spender,tokens);

        return true;
    }

    // Retornar o valor de tokens que o spender pode transacionar, retorna um uint
    function allowance(address tokenOwner,address spender) public view returns (uint remaining) {
        return _allowed[tokenOwner][spender];
    }

    // Transaciona o saldo do dono das moedas, por isso a carteira e sempre do from

    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        // Valida que o procurador tenha ao menos a quantidade de tokens que ele esta querendo transferir
        require(_allowed[from][msg.sender] >= tokens);

        // Valida se quem esta enviando tem o numero de token tem para enviar;
        require(_balances[from] >= tokens);
        
        // Validacao para que transferencia não seja realizada para carteira de queima
        require(to != address(0));

        // Subtrai o numero de token da carteira de quem envia
        _balances[from] = _balances[from].subSafe(tokens);
        // Adicionar o token para carteira de quem recebe
        _balances[to] = _balances[to].addSafe(tokens);
        
        // Subtrai o numero de tokens do procurador
        _allowed[from][msg.sender] = _allowed[from][msg.sender].subSafe(tokens);
        
        // Emitindo evento de transferencia de token
        // msg.sender quem transferiu
        // to quem recebe
        // Quantidade
        emit Transfer(from,to,tokens);

        return true;
    }


}

// Criando um novo contrato para deixar no basictoken somente o que é do padrao ERC-20
// Só pelo fato dele ser um basic token ele ja herda o ownable e o ERC-20

// Essa funcao vai criar novos tokens
contract MintableToken is BasicToken {

    using SafeMath for uint;

    // Criando eventos de criacao e trasferencia de token
    // O indexed serve como chave primaria caso algum mecanismo web queira filtrar o evento
    event Mint(address indexed to,uint token);
    
    // Funcao criadora de tokens
    function mint(address to,uint tokens) onlyOwner public {
        
        // Adiciona token na carteira destino
        _balances[to] = _balances[to].addSafe(tokens);
        // Adiciona token no total supply
        _totalSupply - _totalSupply.addSafe(tokens);

        // Emitingo o evento de criacao de moedas
        // to é para quem esta sendo enviado e token é a quantidade de moeda
        emit Mint(to,tokens);
    }   

}

// Criando um contrado so para conter as informacoes do token
// Separando contrto dessa forma e criar varios contratos pois a heranca é em cadeia
contract ProgramadorMarombaCoin is MintableToken {

    // Criando inicializacao da moeda 
    /*
        - Nome
        - Simbolo
        - Casas decimais
        - Suply
        - Endereços que tem variavel na carteira
    */
    string public constant name = "Programador Maromba Coin";
    string public constant symbol = "PMC";
    uint8 public constant decimals = 18;
}