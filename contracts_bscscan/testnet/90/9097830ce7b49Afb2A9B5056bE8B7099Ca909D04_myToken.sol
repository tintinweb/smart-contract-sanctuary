/**
 *Submitted for verification at BscScan.com on 2022-01-04
*/

pragma solidity ^0.8.2;

contract myToken{
    //Nombre y Símbolo de nuestro Token
    string public name;
    string public symbol;
    //Decimales y totalSupply de nuestro Token
    uint8 public decimals;
    uint256 public totalSupply;
    //Mapeamos el número de Tokens que tiene cada address
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    //CONSTRUCTOR
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply){
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply * (uint256(10) ** decimals);
        balanceOf[msg.sender] = totalSupply;
    }

    //EVENTOS
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    //GETTERS

    //transfer:
    //1.- Comprueba que el balace de la billetera es mayor o igual a la transferencia que se quiere hacer
    //2.- Se resta la trasnsferencia al balance de la billetera que la hace y se le suma a la billetera a la que va la transferencia
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balanceOf[msg.sender] >= _value, "El balance de la billetera es demasiado bajo");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        //Se emite el evento para avisar que la transferencia se ha llevado a cabo
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }

//Esta función lo que hace es:
//1.- Autoriza a una tercera dirección de billetera manejar una cierta cantidad de dinero de la persona que invoca el contrato
  function approve(address _spender, uint256 _value) public returns (bool success){
      allowance[msg.sender][_spender] = _value;  //"msg.sender" autoriza a "_spender" a mover la cantidad de "_value" tokens en su nombre
      emit Approval(msg.sender, _spender, _value);
      return true;
  }

//Esta función lo que hace es:
//1.- Comprobar que hay suficientes fondos en la billetera _from (la que envía los tokens)
//2.- Comprobar que la billetera que invoca la función es una autorizada de la billetera _from
//3.- Hace el balance entre las billeteras _from, _to
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
      require(balanceOf[_from] >= _value, "El balance de la billetera es demasiado bajo");
      require(allowance[_from][msg.sender] >=_value);
      balanceOf[_from] -= _value;
      balanceOf[_to] += _value;
      
      emit Transfer(_from, _to, _value);
      return true;
  }



}