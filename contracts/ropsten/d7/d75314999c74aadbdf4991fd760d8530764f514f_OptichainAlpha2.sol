/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

pragma solidity ^0.5.0;

// ----------------------------------------------------------------------------
// Interfaz estándar de un token ERC20
//
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address _owner) public view returns (uint balance);
    function allowance(address _owner, address _spender) public view returns (uint remaining);
    function transfer(address _to, uint _value) public returns (bool success);
    function approve(address _spender, uint _value) public returns (bool success);
    function transferFrom(address from, address to, uint _value) public returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// Libreria SafeMath
contract SafeMath {
    //Suma sin overflow
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    //Resta sin overflow y no negativos
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "ERC20: cantidad a transferir supera el balance"); 
        c = a - b; 
    } 
}


//Contrato de creación del token
contract OptichainAlpha2 is ERC20Interface, SafeMath {
    string public name; //nombre del token
    string public symbol; //simbolo del token
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    // Inicializacion del token usando el constructor
    constructor() public {
        name = "OptichainAlpha";
        symbol = "OCA2";
        _totalSupply = 100000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    //Metodo de obligada implementacion que devuelve el suministro total de la moneda
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    //Metodo de obligada implementacion que devuelve la cantidad de tokens en propiedad de un usuario
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
    
    //Metodo de obligada implementacion que devuelve la cantidad de tokens que un spender puede retirar del owner del token
    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }
    
    //Metodo de obligada implementacion que permite a un spender retirar del owner del token hasta un valor determinado
    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    //Metodo de obligada implementacion que permite tranferir del emisor a un receptor una cantidad determinada
    function transfer(address _to, uint _value) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    //Metodo de obligada implementacion que permite tranferir de una direccion a otra una cantidad determinada
    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }
}