pragma solidity ^0.4.24;

contract RentAFlat {
	address public owner;
	uint public flatId;
	uint public ownerBalanceOf;
	uint public balanceToDistribute;

	RentStatus currentRentStatus;
	address currentTenantAddress;
	uint currentRentStartTime;
	uint currentRentRequiredEndTime;
	uint rentValue;

	enum RentStatus {
		Available,
		Rented,
		// Puede no estar disponible por alg&#250;n motivo. Por ejemplo, en refacciones o el due&#241;o lo est&#225; usando
		Unavailable
	}

	event RentFlatDaily(address _currentTenantAddress, uint _rentValue, uint _rentalStart, uint _rentalEnd);
	event EndRentFlatDaily(address _currentTenantAddress, uint _rentalEnd, bool _endedInTime);

	constructor(uint _flatId, uint _rentValue) public {
		require(_flatId > 0);

		owner  			  = msg.sender;
		flatId 			  = _flatId;
		rentValue   	  = _rentValue;
		currentRentStatus = RentStatus.Available;
	}

	function rentFlatDaily(uint _daysToRent) public payable {
		// S&#243;lo se puede alquilar el departamento si no est&#225; ocupado y est&#225; disponible para ser alquilado 
		require (currentRentStatus == RentStatus.Available && currentRentStatus != RentStatus.Unavailable);

		// Se verifica que el valor recibido sea igual al valor del alquiler por la cantidad de d&#237;as que fue solicitado para ser alquilado
		// require (msg.value == RATE_DAILYRENTAL * _daysToRent);
		require (msg.value == rentValue * _daysToRent);

		// Se setea como direcci&#243;n del inquilino actual la del que requiere el alquiler, la misma ser&#225; usada para activar el departamento
		currentTenantAddress = msg.sender;

		// Se setea el estado del departamento como alquilado
		currentRentStatus = RentStatus.Rented;

		// Se establece el per&#237;odo en el que empieza a regir el alquiler
		currentRentStartTime = now;

		// Se setea el tiempo de finalizaci&#243;n del alquiler seg&#250;n la cantidad de d&#237;as requeridos
		currentRentRequiredEndTime = now + (_daysToRent * 1 days);

		// Se establece el valor de el dinero a distribuir. El mismo no se adjudicar&#225; al due&#241;o hasta que finalice el contrato exitosamente
		balanceToDistribute = msg.value;

		emit RentFlatDaily(currentTenantAddress, msg.value, currentRentStartTime, currentRentRequiredEndTime);
	}

	function activateFlat(address _tenant, uint _flatId) public view returns(bool) {
		// Si la direcci&#243;n ingresada coincide con la del que solicit&#243; el alquiler del departamento y el ID del departamento que se est&#225; verificando coincide con el que di&#243; origen al alquiler, se habilitar&#225; para ser usado. Podr&#237;a usarse la direcci&#243;n a modo de autenticaci&#243;n con una tarjeta magn&#233;tica por ejemplo.
		require(_tenant == currentTenantAddress && _flatId == flatId);

		return true;
	}

	function endRentFlatDaily() public {
		// El iniquilino pueden finalizar el alquiler cuando quiera pero abonar&#225; la tarifa completa como multa
		// El due&#241;o puede hacerlo siempre que se haya cumplido el tiempo estipulado del mismo
		require ((msg.sender == owner && now > currentRentRequiredEndTime) || (msg.sender == currentTenantAddress));

		// S&#243;lo puede terminarse el alquiler si el departamento se encuentra alquilado
		require(currentRentStatus == RentStatus.Rented);

		// Se verifica si el momento en el que se devuelve el departamento coincide con el tiempo estipulado
		bool endedInTime = now <= currentRentRequiredEndTime;

		emit EndRentFlatDaily(currentTenantAddress, now, endedInTime);

		// Se elimina la direcci&#243;n del inquilino que estaba utilizando el departamento
		currentTenantAddress = address(0);

		// Se setea el estado del departamento a disponible
		currentRentStatus = RentStatus.Available;

		// Se reestablecen las variables de inicio y fin del alquiler
		currentRentStartTime  	   = 0;
		currentRentRequiredEndTime = 0;

		// Se distribuyen las ganancias
		setOwnerEarnings();
	}

	function setUnavailableFlat() public returns(bool) {
		// S&#243;lo el due&#241;o puede llamar a esta funci&#243;n
		require(owner == msg.sender);

		// S&#243;lo puede ejecutarse si el departamento se encontraba con estado disponible. No puede hacerse si el departamento est&#225; alquilado
		require(currentRentStatus == RentStatus.Available);

		currentRentStatus = RentStatus.Unavailable;

		return true;
	}

	function setAvailableFlat() public returns(bool) {
		// S&#243;lo el due&#241;o puede llamar a esta funci&#243;n
		require(owner == msg.sender);

		// S&#243;lo puede ejecutarse si el departamento se encontraba con estado no disponible
		require(currentRentStatus == RentStatus.Unavailable);

		currentRentStatus = RentStatus.Available;

		return true;
	}	

	function setOwnerEarnings() internal {
		uint ownerEarnings  = balanceToDistribute;
		balanceToDistribute = 0;
		ownerBalanceOf      = ownerEarnings;
	}

	function withdraw() public {
		// S&#243;lo el due&#241;o del contrato puede llamar a este m&#233;todo
		require(owner == msg.sender);

		uint balanceToWithdraw = ownerBalanceOf;
		require(balanceToWithdraw > 0);

		ownerBalanceOf = 0;
		msg.sender.transfer(balanceToWithdraw);
	}
}