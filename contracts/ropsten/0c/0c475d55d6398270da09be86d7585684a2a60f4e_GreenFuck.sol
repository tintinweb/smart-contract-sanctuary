pragma solidity ^0.4.24;
/**
 * 
 */
contract GreenFuck {
	
	mapping(address => ClassSocio) GFcoin;
	address public ownerONG;
	address public oracle;
	uint public periodo;

	struct ClassProyect {
		address ProyectOwner;
		uint balance;
		string ProyectName;
		bool activo;
	}

	struct ClassSocio {
		uint balance;
		string socioName;
		bool activo;
		//uint periodo;
	}

	ClassProyect[] proy;

	constructor () public {
		periodo = 1;
        ownerONG = msg.sender;
        oracle = 0x4b0897b0513fdc7c541b6d9d7e929c4e5364d2db; 
    }

	function createProyect( string _name) public returns(uint _id) {
		require(msg.sender == ownerONG);
		ClassProyect memory  temp;
		temp.ProyectOwner = msg.sender;
		temp.ProyectName = _name;
		temp.balance = 0;
		temp.activo = true;
		proy.push(temp);
		_id = proy.length;
	}

	function comprarGFcoin(address _socio, uint _cant) public {
		require(msg.sender == ownerONG);
		require(periodo == 1);
		GFcoin[_socio].balance = _cant;
		GFcoin[_socio].activo = true;
		//GFcoin[_socio].periodo = 1;
	}

	function asignarGFcoin(uint _idProy, uint _cant) public{
		require(GFcoin[msg.sender].balance >= _cant);
		require(periodo == 2);
		require(proy[_idProy].activo);
		
		GFcoin[msg.sender].balance -= _cant;
		//GFcoin[msg.sender].periodo = 2;

		proy[_idProy].balance += _cant;

	}
	function siguientePeriodo() public {
		require(oracle == msg.sender);
		//require(GFcoin[_vencido].periodo < 3);
		//require(GFcoin[_ven].balance >= 0 );
		
		periodo ++;
		if (periodo > 3){
			periodo = 1;
		}
	}

	function asignarGFcoinVen(uint _idProy, uint _cant, address _ven) public{
		require(msg.sender == ownerONG);
		require(GFcoin[_ven].balance >= _cant);
		require(periodo == 3);
		
		GFcoin[_ven].balance -= _cant;
		proy[_idProy].balance += _cant;

	}

	function deshabilitarSocio(address _socio) public {
		require(msg.sender == ownerONG);
		require(GFcoin[_socio].activo);
		GFcoin[_socio].activo = false;
	}

	function deshabilitarProy( uint _idProy) public {
		require(msg.sender == proy[_idProy].ProyectOwner);
		require(proy[_idProy].activo);
		proy[_idProy].activo = false;
	}
	function cambioOwnerProy(address _newO, uint _idProy) public {
		require(msg.sender == proy[_idProy].ProyectOwner);
		require(proy[_idProy].activo);
		proy[_idProy].ProyectOwner = _newO;
	}
}