pragma solidity ^0.4.19;

contract ERC20Basic {
    string public constant name = "ERC20Basic";
    string public constant symbol = "BSC";
    uint8 public constant decimals = 18;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);

    // Balanco de token para cada dono de conta
    mapping(address => uint256) balances;
    // Todas as contas aprovadas para retirar dinheiro de uma conta e seu valor maximo para retirada, que sera somado com as outras contas aprovadas
    mapping(address => mapping(address => uint256)) allowed;

    // Variavel global que possuira o total de tokens da moeda
    uint256 totalSupply_;

    using SafeMath for uint256;

    // Funcao que enviara o total de tokens assim que der deploy no contrato
    // Somente contas que dao deploy podem chamar essa funcao
    constructor(uint256 total) public {
        // Altera a variavel global com o total de tokens enviado como parametro para a funcao
        totalSupply_ = total;
        // Adiciona esse total a quem executa a funcao atual de contrato (no caso quem deu deploy)
        balances[msg.sender] = totalSupply_;
    }

    // Retorna o total de tokens da rede
    function totalSupply() public view returns(uint256) {
        return totalSupply_;
    }

    // Retorna o balanco (tokens em conta) de determinado endereco
    function balanceOf(address tokenOwner) public view returns(uint) {
        return balances[tokenOwner];
    }

    // Funcao que realiza transferencia do executor da funcao(msg.sender) para o receiver de numTokens
    function transfer(address receiver, uint numTokens) public returns (bool) {
        // Predicado &#39;if&#39; para verificar se a carteira do executor da funcao (remetente) tem a quantidade necessaria de tokens para concretizar a transacao, caso nao a possua, sai da funcao e nenhuma alteracao no bloco eh feita, caso possua, realiza as proximas instrucoes
        require(numTokens <= balances[msg.sender]);
        // Remove tokens do executor da funcao (remetente)
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        // Adiciona os tokens no destino da transferencia
        balances[receiver] = balances[receiver].add(numTokens);
        // Funcao ERC20 que permite que os listeners registrados executem as acoes necessarias
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    // Funcao que permite que o dono de determinada carteira aprove outras contas para realizar transacoes (retiradas) com um determinado numero de tokens escolhido por ele
    // Essa funcao eh usada em cenarios no qual donos de tokens oferecem-os no mercado, permitindo assim que o mercado finalize as transacoes sem que seja necessario aguardar pela aprovacao do usuario
    function approve(address delegate, uint numTokens) public returns(bool) {
        // Atualiza a lista de contas aprovadas da carteira do executor da funcao com o delegado e a quantida de tokens
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    // Funcao que retorna a quantidade de tokens permitido para transacao de determinado delegado
    function allowance(address owner, address delegate) public view returns(uint) {
        return allowed[owner][delegate];
    }

    // Funcao que transfere tokens por meio de um delegado
    function transferFrom(address owner, address buyer, uint numTokens) public returns(bool) {
        // Verifica se o dono dos tokens possuo quantidade necessaria para concretizar a transacao
        require(numTokens <= balances[owner]);
        // Verifica se o delegado esta aprovado em relacao ao numero de tokens para aprovar a transacao
        require(numTokens <= allowed[owner][msg.sender]);
        // Altera a quantidade de tokens da conta que possue-os
        balances[owner] = balances[owner].sub(numTokens);
        // Altera a quantidade de tokens permitidos para transacao do delegado
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        // Transfere os tokens
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}


// Com as funcoes acima ja eh possivel criar uma implementacao valida em ERC20, mas para criar uma rede mais industrial e mais segura, continuaremos implementando mais funcoes.


// Funcao que impede ataques de overflow ao realizar operacoes matematicas. Gera pouco impacto no tamanho do contrato e penalidades de custo de armazenamento
library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        // Verifica se &#39;b&#39; eh menor que &#39;a&#39;, se sim continua, se nao, retorna
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        // Verifica se a soma eh menor que um dos parametros, se sim continua, se nao, retorna
        assert(c >= a);
        return c;
    }
}