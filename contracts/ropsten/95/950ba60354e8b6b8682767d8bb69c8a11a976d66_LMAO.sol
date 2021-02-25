/**
 *Submitted for verification at Etherscan.io on 2021-02-25
*/

pragma solidity ^0.4.16;
contract Token {

    /// indica la cantidad total de monedas existira, asi como bitcoin tiene 21 millones aca tambien decidimos el limite
    function totalSupply() constant returns (uint256 supply) {}

    /// adress owner indica la direccion de la cuenta de donde se extraera los tokens 
    /// esta funcion regresa el balance final
    function balanceOf(address _owner) constant returns (uint256 balance) {}

    /// funcion con entrada de direccion de recibidor y el valor de la transferencia
    /// _to es la direccion del recibidor
    /// _value es la cantidad de tokens a ser transferida
    /// retorna un valor bool el cual indica si la funcion fue exitosa o no
    function transfer(address _to, uint256 _value) returns (bool success) {}

    /// funcion de transferencia de tokens de una cuenta a otra si fue aprobada
    /// parametro _from es la direccion del vendedor
    /// parametro _to es la direccion del recibidor
    /// parametro _value es la cantidad de tonkes ha tranferir
    /// Retorna un valor bool el cual indica si la tranferencia fue exitosa o no
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

    /// funcion para aprobar una transferencia
    /// @param _spender direccion del vendedor
    /// @param _value cantidad de tokens ha transferir
    /// regresa un valor bool si la transaccion fue aprobada
    function approve(address _spender, uint256 _value) returns (bool success) {}

    /// @param _owner direccion de la cuenta que recibe los tokens 
    /// @param _spender direccion de cuenta del vendedor de tokens
    /// retorna la cantidad de tokens que quedan al final de la transaccion
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}





contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
        //Default assumes totalSupply can't be over max (2^256 - 1).
        //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn't wrap.
        //Replace the if with this one instead.
        //if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        //Funcion que evita repeticion de la moneda
       
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalSupply;
}



contract LMAO is StandardToken {

    function () {
        
        throw;
    }

    //Variables publicas ,osea visibles para todos

    /*
    Estas variables son opcionales la cuales no afectan al uso del token en inguna manera ya que 
    no son encesitadas al momento de una transaccion.
    Solo son utilizidas para personalizar la moneda
    Algunas billeteras y programas ni siquiera se revisan estas indicaciones
   
    */
    string public name;                   //Nombre de token 
    uint8 public decimals;                //Cuentos decimales tendria la moneda 
    string public symbol;                 //Identificador como Bitcoin BTC
    string public version = 'H1.0';       //Esquema de control de versiones aleatoria




    function LMAO(
        ) {
        balances[msg.sender] = 1000000;               // Cantidad de tokens que existiran al inicio
        totalSupply = 100000000;                        // Cantidad de tokens que existiran 
        name = "LMAO";                                   // Nombre del token 
        decimals = 9;                            // Cantidad de decimales
        symbol = "LAO";                               // Simbolo de la moneda 
    }

    /* Aprueba la interaccion con otro contrato */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);

        
        if(!_spender.call(bytes4(bytes32(sha3("receiveApproval(address,uint256,address,bytes)"))), msg.sender, _value, this, _extraData)) { throw; }
        return true;
    }
}