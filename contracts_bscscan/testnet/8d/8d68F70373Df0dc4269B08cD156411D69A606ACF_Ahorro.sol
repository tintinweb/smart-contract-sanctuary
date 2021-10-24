/**
 *Submitted for verification at BscScan.com on 2021-10-23
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Ahorro {
	address public owner;
	uint256 public lastUpdateTime;
	uint256 public tiempoInicial;

	uint256 public tiempoDesbloqueo;
	uint256 public retirosRestantes;

	constructor() {
		owner = msg.sender;
		tiempoDesbloqueo = 31536000; // TIEMPO DE BLOQUEO DE UN AÑO
		retirosRestantes = 2; // CANTIDAD RESTANTE
		tiempoInicial = block.timestamp;
	}

	event Retiro(uint256 _monto, uint256 _lastTime);
	event Deposito(uint256 _monto, uint256 _lastTime);

	modifier onlyOwner() {
		require(owner == msg.sender);
		if (!((block.timestamp - tiempoInicial) >= tiempoDesbloqueo)) {
			require(retirosRestantes > 0, "No hay retiros disponibles");
		}
		lastUpdateTime = block.timestamp;
		_;
	}

	// ---------------- FUCIONES DE AHORRO ------------------------

	function retirarToken(
		address _token,
		address _destino,
		uint256 _monto
	) external onlyOwner {
		IERC20 token = IERC20(_token);
		token.transfer(_destino, _monto);

		emit Retiro(_monto, lastUpdateTime);
	}

	function retirarBNB(uint256 _monto, address payable _destino) external onlyOwner {
		require(_monto <= address(this).balance, "Saldo BNB insuficiente");
		_destino.transfer(_monto);

		emit Retiro(_monto, lastUpdateTime);
	}

	// ---------------- FUCIONES DE CONFIGURACION ------------------------
    
	function reiniciar() external {
		retirosRestantes = 2; // CANTIDAD RESTANTE
		tiempoInicial = block.timestamp;
	}

	function cambiarTiempoBloqueo(uint256 _newTime) external {
		tiempoDesbloqueo = _newTime;
	}

	function cambiarOwner(address _newOwner) external {
		owner = _newOwner;
	}

	fallback() external payable {}

	receive() external payable {
		lastUpdateTime = block.timestamp;
		emit Deposito(msg.value, lastUpdateTime);
	}
}

interface IERC20 {
	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);

	event Transfer(address indexed from, address indexed to, uint256 value);
	event Approval(address indexed owner, address indexed spender, uint256 value);
}