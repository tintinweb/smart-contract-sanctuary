/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: MIT

// Ayusocoin - simple ERC20 token for a campaign to educate
// spanish politicians about Ethereum and cryptocurrencies
// in general.

pragma solidity >=0.6.6; 

// Interfaz ERC20 - Estandar para tokens sobre Ethereum
// En Ethereum los "tokens" o "monedas" son contratos.
// Ojo: un contrato es un programa de ordenador.

// El código viene después de definir la interfaz del contrato.
// Es decir, primero decimos qué cosas se pueden hacer con el contrato
// y después ponemos el código del contrato.

/* Esto el lo que implementa el contrato:
  function totalSupply() public returns (uint256 supply);
  function balanceOf(address _owner) public returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  // solhint-disable-next-line no-simple-event-func-name
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}
 */

contract Ayusocoin {

  // Nombre y símbolo con el que se da a conocer el 'token':
  // Algunas wallets ignoran esto, pero mola verlo ;-)
  string public constant name = "Ayuso Coin v1";
  string public constant symbol = "AYUSOS";

  // Parámetros técnicos
  uint8 public constant decimals = 6;
  uint256 public _totalSupply = 47000000000000000; // 1000 ayusos * 47.000.000 de españoles (*1000000 - 6 decimales) - un número divertido
  
  // Propio de este token

  // El contrato tiene un balance maximo por direccion para evitar
  // que se haga trading con el token durante los primeros días.
  // Tambien sirve para "pausar" temporalmente el movimiento del token de un usuario a otro.
  // Al poner un límite al balance por dirección, si alguien quiere manipular el precio 
  // tiene que hacer una operación coordinada grande con un coste importante.

  uint256 public maxbalance_per_addr = 10000000000; // El limite de tokens que puede tener una direccion.

  address private _root ; // Direccion del superusuario del contrato: puede cambiar los limites y parámetros

  // Eventos
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  // Estos dos mapping sirven para guardar datos en el blockchain de Ethereum
  // el almacenamiento en el blockchain es _muy_ caro: estamos guardando
  // datos en millones de ordenadores hasta el final de los tiempos y eso
  // hay que pagarlo (con el GAS)

  // Primer mapping: ¿cuántos ayusos tiene cada dirección de Ethereum?
  mapping (address => uint256) private balance;

  // Segundo mapping: permisos para enviar tokens a otras direcciones
  // esto es lo que se toca cuando una aplicación pide permiso a tu wallet
  // para hacer una transacción.
  // Hay un doble mapping: el primero es para identificar el dueño,
  // y el segundo a qué dirección tiene permiso para enviar tokens.
  // El uint256 es la cantidad con la que se puede operar (MAX_UINT256 = ilimitado)
  mapping (address => mapping (address => uint256)) public allowed;

  // necesitamos esto por seguridad...
  uint256 constant private MAX_UINT256 = 2**256 - 1;

  // métodos del token

  // totalSupply -> ¿cuántos tokens hay en circulación
  function totalSupply() public view returns (uint256) { return _totalSupply; }

  // balanceOf -> ¿cuántos tiene cada dirección?
  function balanceOf(address _quien) public view returns (uint256 _balance) {
    return balance[_quien];
  }

  /*
  ** Gestion del contrato por el superusuario.
  */

  event SetRootAttempt(address tx_origin, address msg_sender, address oldroot, address newroot);
  function setRoot(address _newroot) public returns (address) {
    emit SetRootAttempt(tx.origin, msg.sender, _root, _newroot);
    require(isRoot(msg.sender));
    _root = _newroot;
    return _newroot;
  }

  function getRoot() public view returns (address) {
     return _root;
  }
   
  function isRoot(address addy) public view returns (bool) {
    require(msg.sender == tx.origin);
    address myroot = getRoot();
    return addy == myroot;
   //   return (tx.origin == _root) && (msg.sender == _root); // Humans only
  }

  function setMaxBalancePerAddress(uint256 maxbal) public returns (uint256) {
      require(isRoot(tx.origin)); // OnlyRoot
      maxbalance_per_addr = maxbal;
      return maxbal;
  }

  /*
  ** A partir de aqui _movemos_ "dinero" virtual.
  */

  // La funcion transfer(to,value) ordena uan transferencia de los tokens.
  // Se utiliza por el dueño de los tokens (sea o no un contrato).
  
  function transfer(address _to, uint256 _value) public returns (bool success) {

    // Antes de mover los tokens hay que asegurarse de que:
    // 1 - Tenemos saldo suficiente 
    // 2 - No nos llaman desde un contrato. Sólo para humanos.

    require(balance[msg.sender] >= _value);
    // require(msg.sender == tx.origin, 'Humans only');
    require(balance[_to] + _value <= maxbalance_per_addr, 'Limite de balance alcanzado');

    // Movemos balances

    balance[msg.sender] -= _value ;
    balance[_to] += _value;

    // Este mensaje avisa de que ha ocurrido algo...
    emit Transfer(msg.sender, _to, _value);

    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {

    // Esta funcion es casi igual que transfer(), pero dando con una dirección de origem.
    // ¿Para qué necesitamos esta función? ¿no basta con transfer() ?
    // Pues no, esta funcion se llama desde otro smart contract (como Uniswap, o cualquier otro DEX)
    // Por eso tenemos ese parámetro "allowance" en ERC20: Para que el smart contract
    // que llama a esta función no nos pueda dejar vacía la billetera.
    
    uint256 limit;

    // Por seguridad evitamos reentrada pero la transacción es más cara (cuesta más gas) :-S
    limit = allowed[_from][_to];

    // Antes de mover los tokens hay que asegurarse de que
    // 1 - Tenemos saldo suficiente 
    // 2 - Se permite mandar esa cantidad al destino

    require(balance[_from] >= _value);
    require(limit >= _value, 'Se debe permitir transferencia' );
    require(balance[_to] + _value <= maxbalance_per_addr, 'Limite de balance alcanzado');

    // Movemos balances

    if (limit < MAX_UINT256) {
        // actualizamos los permisos... con cuidado para que no nos ataquen con un underflow.
        require(limit - _value < limit, "Evita integer underflow");
        allowed[_from][_to] = 0;
        limit -= _value;
        allowed[msg.sender][_to] = limit;
    }

    balance[msg.sender] -= _value ;
    balance[_to] += _value;  // Lo ultimo que se hace siempre es _mover_ hacia otra direccion,

    // Este mensaje notifica que ha ocurrido algo... (se puede consultar en Etherscan / web3 / infura...)
    emit Transfer(_from, _to, _value);
    return true;

  }

  // Gestión de allowance (la asignación)

  // approve(_direccion, _valor) -> Aprueba que la dirección haga un gasto
  // Esta función se suele llamar desde el wallet.
  // No queremos que un contrato lo cambie. Sólo personas humanas.
  
  function approve(address _to, uint256 _value) public returns (bool success) {
    require(msg.sender == tx.origin, "Humans only");
    allowed[msg.sender][_to] = _value;
    emit Approval(msg.sender, _to, _value);

    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  // Constructor - desde aqui se crea el contrato y se acuñan los tokens

  constructor () {
     balance[msg.sender] = _totalSupply;
     _root = tx.origin; // Direccion del dueño del contrato
  }

}