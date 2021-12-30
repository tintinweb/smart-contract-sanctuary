/**
 *Submitted for verification at BscScan.com on 2021-12-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ARTE {

	uint   private _total_Supply; 												//Total de tokens que se crearán en un principio
	uint8  private _decimals;     												//Número de decimales que tendrá el token. En principio serán 18
	string private _symbol;       												//Símbolo del token: ARTE
	string private _name;         												//Nombre largo del token. Podemos llamarlo ARTE o cualquier otra cosa que se nos ocurra. Consultar a Enric

	mapping (address => uint256) public coinBalance;							//Contendrá el número de tokens para cada wallet (address)
	mapping (address => mapping (address => uint256)) public allowance;     	//Cantidad de tokens en una cartera que un usuario podrá delegar a otra cartera para ser usados
	mapping (address => bool) public frozenAccount;                         	//Indica si una wallet ha sido bloqueada
	address public owner;                                                   	//Owner del contrato. En este caso la wallet que lo crea
    
	event Transfer(address indexed from, address indexed to, uint256 value);	//Evento transferencia de Tokens
	event FrozenAccount(address target, bool frozen);   						//Evento bloqueo de wallet
   
	modifier onlyOwner {														//Modificador onlyOwner para permitir que solo el owner del contrato realice una acción
		if (msg.sender != owner) revert();
		_;
	}

	constructor(string memory token_name, string memory short_symbol, uint8 token_decimals, uint256 token_initialSupply) {

		_name        = token_name;
		_symbol      = short_symbol;
		_decimals    = token_decimals;
		_total_Supply = 0;//El total supply será en principio 0 hasta que se actualice con el token_initialSupply

		owner        = msg.sender;

		mint(owner, token_initialSupply);//Se envía al owner del contrato el token_initialSupply y se establace que _totalSupply = 0 + token_initialSupply
	}
   
    /**
	*
	* Función de transferencia de tokens arte a la dirección _to desde la wallet del que ejecuta la función
	*
	*/   
	function transfer(address _to, uint256 _amount) public {
		require(_to != address(0)); 										// No puede ser una dirección vacía (0x0)
		require(coinBalance[msg.sender] >= _amount);				// La cantidad de tokens del que envía debe ser mayor o igual que el _amount que se desea enviar
		require(coinBalance[_to] + _amount >= coinBalance[_to] );   // La cantidad enviada (_amount) debe ser mayor o igual que 0
		coinBalance[msg.sender] -= _amount;                         // Se resta la cantidad de la wallet que envía
		coinBalance[_to] += _amount;                                // Se suma la cantidad a la wallet que recibe
		emit Transfer(msg.sender, _to, _amount);                    // Se realiza la transferencia
	}

    /**
	*
	* Función que permite a un usuario de una wallet autorizar a otra para que haga uso de un número determinado de sus tokens
	*
	*/      
	function authorize(address _authorizedAccount, uint256 _allowance) 
		public returns (bool success) {
		allowance[msg.sender][_authorizedAccount] = _allowance; //el que ejecuta la función permite a la wallet _authorizedAccount a utilizar un máximo de _authorizedAccount tokens
		return true;
	}
    
    /**
	*
	* Función que permite a un usuario autorizado a enviar tokens desde otra wallet
	*
	*/      	
	function transferFrom(address _from, address _to, uint256 _amount) 
		public returns (bool success) {
		require(_to != address(0));                                      // No puede ser una dirección vacía (0x0)
		require(coinBalance[_from] > _amount);                    // La cantidad de tokens del que envía debe ser mayor o igual que el _amount que se desea enviar
		require(coinBalance[_to] + _amount >= coinBalance[_to] ); // La cantidad enviada (_amount) debe ser mayor o igual que 0
		require(_amount <= allowance[_from][msg.sender]);         // La canitidad enviada deber ser menor o igual al límite que se ha establecido en la función authorize 
    
		coinBalance[_from] -= _amount;                            // Se resta la cantidad de la wallet que envía
		coinBalance[_to] += _amount;                              // Se suma la cantidad a la wallet que recibe
		allowance[_from][msg.sender] -= _amount;                  // Se actualiza la cantidad autorizada
		emit Transfer(_from, _to, _amount);                       // Se emite la transferencia
		return true;
	}
    
    /**
	*
	* Función que permite al propietario de un contrato a aumentar el totalsupply de las monedas y enviar la cantidad a una wallet
	*
	*/	
	function mint(address _recipient, uint256  _mintedAmount) 
		onlyOwner public {
		require(_recipient != address(0), "ARTE: cannot mint to zero address"); // No puede ser una dirección vacía (0x0)
		_total_Supply = _total_Supply + (_mintedAmount);                          // Se incrementa el total supply por la cantidad que se ha añadido _mintedAmount
		coinBalance[_recipient] += _mintedAmount;                               // Se incrementa la wallet del _recipient por la cantidad que se ha añadido _mintedAmount
		emit Transfer(owner, _recipient, _mintedAmount);                        // Se realiza la transferencia 
	}
    
    /**
	*
	* Función que permite al propietario de un contrato a reducir el totalsupply de las monedas y restar la cantidad de una wallet
	*
	*/		
	function burn(address _recipient, uint256 amount) onlyOwner public {
		require(_recipient != address(0), "ARTE: cannot burn from zero address");                      // No puede ser una dirección vacía (0x0)
		require(coinBalance[_recipient] >= amount, "ARTE: Cannot burn more than the _recipient owns"); // Cantidad eliminada debe ser mayor o igual de lo que hay en cartera

		// Remove the amount from the _recipient balance
		coinBalance[_recipient] = coinBalance[_recipient] - amount;                                    // Se decrementa la wallet del _recipient por la cantidad amount
		// Decrease totalSupply
		_total_Supply = _total_Supply - amount;                                                          // Se decrementa el total supply por la cantidad amount
		// Emit event, use zero address as reciever
		emit Transfer(_recipient, address(0), amount);                                                 // Se emite la transferencia
	}
  
  
	/**
	*
	* Función que permite al owner del contrato a congelar/descongelar (true/false) una wallet
	*
	*/
	function freezeAccount(address target, bool freeze) 
		onlyOwner public { //#A

		frozenAccount[target] = freeze;  
		emit FrozenAccount(target, freeze);
	}
	
	
	
	/**
	* Función que devuelve el número de decimales del token
	*/
	function decimals() external view returns (uint8) {
		return _decimals;
	}
	
	/**
	* Función que devuelve el nombre del símbolo del token
	*/
	function symbol() external view returns (string memory){
		return _symbol;
	}
	
	/**
	* Función que devuelve el nombre del token 
	*/
	function name() external view returns (string memory){
		return _name;
	}
	
	/**
	* Función que devuelve el token supply actual 
	*/
	function totalSupply() external view returns (uint256){
		return _total_Supply;
	}	
}