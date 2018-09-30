pragma solidity ^0.4.21;

// File: contracts/EIP20Interface.sol

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
pragma solidity ^0.4.21;


contract EIP20Interface {
    /* This is a slight change to the ERC20 base standard.
    function totalSupply() constant returns (uint256 supply);
    is replaced with:
    uint256 public totalSupply;
    This automatically creates a getter function for the totalSupply.
    This is moved to the base contract since public getter functions are not
    currently recognised as an implementation of the matching abstract
    function by the compiler.
    */
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) public view returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);

    // solhint-disable-next-line no-simple-event-func-name
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// File: contracts/EIP20.sol

contract EIP20 is EIP20Interface {

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;
    /*
    NOTE:
    The following variables are OPTIONAL vanities. One does not have to include them.
    They allow one to customise the token contract & in no way influences the core functionality.
    Some wallets/interfaces might not even bother to look at this information.
    */
    string public name;                   //fancy name: eg Simon Bucks
    uint8 public decimals = 18;                //How many decimals to show.
    string public symbol;                 //An identifier: eg SBX

    constructor(
        uint256 _initialAmount
    ) public {
        totalSupply = _initialAmount * 10 ** uint256(decimals);                        // Update total supply
        balances[msg.sender] = totalSupply;               // Give the creator all initial tokens
        name = "Custodia de Pagamento";                                   // Set the name for display purposes
        symbol = "CDP";                               // Set the symbol for display purposes
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "Saldo do endere&#231;o inferior ao de transfer");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value, "Saldo insuficiente ou allowance n&#227;o permitida");
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value); //solhint-disable-line indent, no-unused-vars
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

// File: contracts/CustodiaPagamento.sol

contract CustodiaPagamento is EIP20{
    address public comprador;
    address public vendedor;
    address public intermediador;
    uint256 public valorCustodia;
    uint256 public status;

    uint256 private constant AGUARDANDO_PAGAMENTO = 0;
    uint256 private constant VIGENCIA = 1;
    uint256 private constant DEVOLUCAO_SOLICITADA = 2;
    uint256 private constant DEVOLUCAO_LIBERADA = 3;
    uint256 private constant DEVOLUCAO_INTERMEDIADOR = 4;
    uint256 private constant PAGAMENTO_SOLICITADO = 5;
    uint256 private constant PAGAMENTO_LIBERADO = 6;
    uint256 private constant PAGAMENTO_LIBERADO_INTERMEDIADOR = 7;
    uint256 private constant AGUARDANDO_INTERMEDIADOR = 8;
    uint256 private constant ENCERRADO = 9;

    mapping (uint256 => string) statusPossiveis;

    constructor(
        address _comprador,
        address _intermediador,
        uint256 _valor
    ) EIP20(_valor) public{
        vendedor = msg.sender;
        comprador = _comprador;
        intermediador = _intermediador;
        valorCustodia = _valor;

        inicializaStatusPossiveis();
    }

    modifier seNaoDepositado(){
        require(status == AGUARDANDO_PAGAMENTO, "Contrato n&#227;o aguardando pagamento.");
        _;
    }

    modifier devolucaoSolicitada(){
        require(status == DEVOLUCAO_SOLICITADA, "Devolu&#231;&#227;o n&#227;o foi solicitada");
        _;
    }

    modifier emVigencia(){
        require(status == VIGENCIA, "Acordo n&#227;o est&#225; em vig&#234;ncia");
        _;
    }

    modifier encerrado(){
        require(status == ENCERRADO, "Acordo n&#227;o encerrado");
        _;
    }

    modifier aguardandoIntermediador(){
        require(status == AGUARDANDO_INTERMEDIADOR, "Acordo n&#227;o est&#225; aguardando intermediador");
        _;
    }

    modifier pagamentoSolicitado(){
        require((status == VIGENCIA || status == PAGAMENTO_SOLICITADO), "N&#227;o &#233; poss&#237;vel solicitar pagamento");
        _;
    }

    modifier pagamentoLiberado(){
        require(status == PAGAMENTO_LIBERADO, "Pagamento n&#227;o liberado");
        _;
    }

    modifier somenteIntermediador(){
        require(msg.sender == intermediador, "N&#227;o &#233; o intermediador");
        _;
    }

    modifier somenteComprador(){
        require(msg.sender == comprador, "N&#227;o &#233; o comprador");
        _;
    }

    modifier somenteVendedor(){
        require(msg.sender == vendedor, "N&#227;o &#233; o vendedor");
        _;
    }

    function inicializaStatusPossiveis() internal{
        statusPossiveis[AGUARDANDO_PAGAMENTO] = "Aguardando Pagamento";
        statusPossiveis[VIGENCIA] = "Acordo em Vig&#234;ncia";
        statusPossiveis[DEVOLUCAO_SOLICITADA] = "Devolu&#231;&#227;o do pagamento solicitada";
        statusPossiveis[DEVOLUCAO_LIBERADA] = "Devolu&#231;&#227;o de pagamento liberado";
        statusPossiveis[DEVOLUCAO_INTERMEDIADOR] = "Devolu&#231;&#227;o liberada pelo intermediador";
        statusPossiveis[PAGAMENTO_SOLICITADO] = "Acordo com pagamento pendente";
        statusPossiveis[PAGAMENTO_LIBERADO] = "Pagamento Liberado";
        statusPossiveis[PAGAMENTO_LIBERADO_INTERMEDIADOR] = "Pagamento liberado pelo intermediador";
        statusPossiveis[AGUARDANDO_INTERMEDIADOR] = "Aguardando decis&#227;o do intermediador";
        statusPossiveis[ENCERRADO] = "Acordo encerrado";
    }

    function getStatus() public view returns(string){
        return statusPossiveis[status];
    }

    function depositaPagamento() public seNaoDepositado somenteComprador payable{
        uint256 _valor = msg.value;

        if(_valor < valorCustodia){
            msg.sender.transfer(_valor);
        }else if(_valor > valorCustodia){
            msg.sender.transfer(_valor - valorCustodia);
            status = VIGENCIA;
        }else{
            status = VIGENCIA;
        }
    }

    function aprovaPagamento(bool _aprovacao) public somenteComprador pagamentoSolicitado{
        if(_aprovacao == true){
            status = PAGAMENTO_LIBERADO;
        } else {
            status = AGUARDANDO_INTERMEDIADOR;
        }
    }

    function solicitaPagamento() public somenteVendedor emVigencia{
        status = PAGAMENTO_SOLICITADO;
    }

    function solicitaDevolucao() public somenteComprador emVigencia{
        status = DEVOLUCAO_SOLICITADA;
    }

    function aprovaDevolucao(bool _aprovacao) public somenteVendedor devolucaoSolicitada{
        if(_aprovacao == true){
            comprador.transfer(valorCustodia);
        } else {
            status = AGUARDANDO_INTERMEDIADOR;
        }
    }

    function intermediadorAprovaDevolucao(bool _aprovacao) public somenteIntermediador aguardandoIntermediador{
        if(_aprovacao){
            comprador.transfer(valorCustodia);
            status = DEVOLUCAO_INTERMEDIADOR;
        } else {
            status = PAGAMENTO_LIBERADO_INTERMEDIADOR;
        }
    }

    function intermediadorAprovaPagamento(bool _aprovacao) public somenteIntermediador aguardandoIntermediador{
        if(_aprovacao){
            status = PAGAMENTO_LIBERADO_INTERMEDIADOR;
        } else {
            comprador.transfer(valorCustodia);
            status = DEVOLUCAO_INTERMEDIADOR;
        }
    }

    function reclamaPagamento() public{
        uint256 valor = balanceOf(msg.sender);

        msg.sender.transfer(valor);
    }
}