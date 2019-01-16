pragma solidity >=0.4.22 <0.6.0;

//pragma solidity ^0.4.24;
// ----------------------------------------------------------------------------
// &#39;CryptomasterCoin token contract
//
// Deployed to : 0xdE913b8478AD48bdB34e3989b3543fca67cf1976
// Symbol      : crypmcoin
// Name        : CryptoCoin Token
// Total supply: 100000000
// Decimals    : 18
//
// Enjoy.
//
// (c) by Raul Torres / Cryptomaster. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Calculos Seguros
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Funci&#243;n de contrato para recibir la aprobaci&#243;n y ejecutar la funci&#243;n en una llamada.
//
// Tomado de MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Contracto de Propiedad
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// Token ERC20, con la adici&#243;n de s&#237;mbolo, nombre y decimales y demas.
// token transferencias.
// ----------------------------------------------------------------------------
contract CryptoCoin is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "crypmcoin";
        name = "CryptoCoin Token";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        balances[0xdE913b8478AD48bdB34e3989b3543fca67cf1976] = _totalSupply;
        emit Transfer(address(0), 0xdE913b8478AD48bdB34e3989b3543fca67cf1976, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Oferta Total
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Obtener el saldo de token para propietario de token de cuenta
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transferir el saldo de la cuenta del propietario del token a la cuenta. 
    // La cuenta del propietario debe tener un saldo suficiente para transferir 
    // 0 se permiten transferencias de valor
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // El propietario del token puede aprobar la transferencia del token desde (...) 
    // tokens desde la cuenta del propietario del token
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recomiendo que no haya comprobaciones para el ataque de doble gasto de aprobaci&#243;n,
    // ya que esto deber&#237;a implementarse en las interfaces de usuario
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfiera tokens de la cuenta de a la cuenta
    // 
    // La cuenta que llama debe tener ya suficientes tokens aprobar (...) para gastar 
    // de la cuenta de y la cuenta de debe tener un saldo suficiente para transferir.
    // Spender debe tener un margen suficiente para transferir.
    // Se permiten transferencias de valor 0
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Devuelve la cantidad de tokens aprobados por el propietario que se pueden
    // transferir a la cuenta del usuario.
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // El propietario del token puede aprobar la transferencia de tokens desde 
    // (...) desde la cuenta del propietario del token. A continuaci&#243;n, se 
    // ejecuta la funci&#243;n de aprobaci&#243;n del contrato Spender (aprobaci&#243;n)
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // El propietario puede transferir cualquier tokens ERC20 enviados accidentalmente
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}