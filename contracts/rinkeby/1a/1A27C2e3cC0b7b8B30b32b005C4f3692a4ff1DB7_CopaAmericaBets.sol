pragma solidity ^0.4.24;

import "./SafeMath.sol";

contract CopaAmericaBets {
    
    using SafeMath for uint; 
    
    constructor() public {
	    owner = msg.sender;
	}
    
    struct Usuario {
        string nombre;
        string apellido;
    }

	struct Partido {
		uint id;
		string descripcion;
		string pais1;
		string pais2;
		uint resultadoPais1;
		uint resultadoPais2;
		bool bloqueado;
		bool cancelado;
		bool finalizado;
		uint balance;
	}
	
	struct Apuesta {
	    Usuario usuario;
	    address direccion;
	    uint idPartido;
	    uint marcadorPais1;
		uint marcadorPais2;
		uint monto;
		bool ganador;
	}

	address private owner;
	mapping (uint => Partido) private partidos;
	mapping (uint => mapping(address => Apuesta)) private apuestas;
	mapping (uint => Apuesta[]) private matchToBets;

	uint housePercentage = 1; 
    uint multFactor = 1000000;
    uint internal minimumBet = 0.025 ether;
    
	event onUserJoined(address, string);

	function crearPartido(uint _id, string _descripcion, string _pais1, string _pais2) public isOwner {
	    
	    require(!validarPartidoRegistrado(_id));
		
		Partido memory _partido = Partido({
			id: _id,
			descripcion: _descripcion,
			pais1: _pais1,
			pais2: _pais2,
			resultadoPais1: 0,
			resultadoPais2: 0,
			bloqueado: false,
			cancelado: false,
			finalizado: false,
			balance: 0
		});
		
		partidos[_id] = _partido;
	}
	
	function obtenerPartido(uint _id) public view returns (uint, string, string, string, bool, bool, bool, uint)  {
	    require(validarPartidoRegistrado(_id));
	    Partido memory partido = partidos[_id];
	    return (partido.id, partido.descripcion, partido.pais1, partido.pais2, partido.bloqueado, partido.cancelado, partido.finalizado, partido.balance);
	}
    
	function apostar(uint _id, uint _marcadorPais1, uint _marcadorPais2, string _nombre, string _apellido) public payable {
	    
	    require(msg.value > minimumBet);
	    require(validarPartidoRegistrado(_id));
	    require(!validarUsuarioRegistrado(_id, msg.sender));
		
		Partido storage _partido = partidos[_id];
		require(_partido.finalizado == false && _partido.cancelado == false && _partido.bloqueado == false);
		
		_partido.balance = _partido.balance.add(msg.value);
		
		Usuario memory _user;
		_user.nombre = _nombre;
		_user.apellido = _apellido;
		
		Apuesta memory _apuesta = Apuesta({
		    usuario: _user,
			direccion: msg.sender,
			idPartido: _id,
			marcadorPais1: _marcadorPais1,
			marcadorPais2: _marcadorPais2,
			monto: msg.value,
			ganador: false
		});
		
		apuestas[_id][msg.sender] = _apuesta;
		
		Apuesta[] storage bets = matchToBets[_id];
		bets.push(_apuesta)-1;
		
		emit onUserJoined(msg.sender, string(abi.encodePacked(_nombre, " ", _apellido)));
	}
    
    function validarUsuarioRegistrado(uint _id, address _sender) private view returns (bool) {
        Apuesta memory apuesta = apuestas[_id][_sender];
        return apuesta.idPartido > 0;
    }
    
    function validarPartidoRegistrado(uint _id) private view returns (bool) {
        Partido memory partido = partidos[_id];
        return partido.id > 0;
    }
    
    function cerrarApuestas(uint _id) public isOwner {
	    require(validarPartidoRegistrado(_id));
	    Partido storage _partido = partidos[_id];
	    _partido.bloqueado = true;
	}
	
	function cancelarPartido(uint _id) public isOwner {
	    require(validarPartidoRegistrado(_id));
	    require(address(this).balance == 0);
		Partido storage _partido = partidos[_id];
		require (_partido.finalizado == false);
		_partido.cancelado = true;
	}

    function publicarResultado(uint _id, uint _resultadoPais1, uint _resultadoPais2) public isOwner {
         require(validarPartidoRegistrado(_id));
         Partido storage _partido = partidos[_id];
         require(_partido.balance > 0 && _partido.bloqueado == true);
        
         _partido.resultadoPais1 = _resultadoPais1;
	     _partido.resultadoPais2 = _resultadoPais2;
	     _partido.finalizado = true;
	}
	
    function pagarGanadores(uint _id) public isOwner {
        require(validarPartidoRegistrado(_id));
        
        Partido storage _partido = partidos[_id];
        require(_partido.balance > 0 && _partido.finalizado == true);
        
        
        uint winningTotal = 0;
        uint losingTotal = 0;
        uint totalPot = 0;
      
            
        Apuesta[] storage bets = matchToBets[_id]; 
        uint[] memory _payouts = new uint[](bets.length);
           
        uint n;
        for (n = 0; n < bets.length; n++) {
            uint amount = bets[n].monto;
            if (bets[n].marcadorPais1 == _partido.resultadoPais1 && bets[n].marcadorPais2 == _partido.resultadoPais2) {
                winningTotal = winningTotal.add(amount);
            } else {
                losingTotal = losingTotal.add(amount);
            }
        }
            
        totalPot = (losingTotal.add(winningTotal));
            
        for (n = 0; n < bets.length; n++) {
            if (bets[n].marcadorPais1 == _partido.resultadoPais1 && bets[n].marcadorPais2 == _partido.resultadoPais2) {
                
                uint proportion = (bets[n].monto.mul(multFactor)).div(winningTotal);
                uint rawShare = totalPot.mul(proportion).div(multFactor);
                if (rawShare == 0) 
                    rawShare = minimumBet;
                       
                _payouts[n] = rawShare/(100 * housePercentage);
            } else {
                _payouts[n] = 0;
            }
        }
            
        for (n = 0; n < _payouts.length; n++) {
            if(_payouts[n] > 0){
                _partido.balance = _partido.balance.sub(_payouts[n]);
                transferTo(_payouts[n], bets[n].direccion); 
            }
        }
        
        transfer(_partido.balance);
        _partido.balance = 0;
	}
	
	function transfer(uint amount) private isOwner{
	    require(address(this).balance >= amount);
	    owner.transfer(amount);	
    }
	
	function transferTo(uint amount, address to) private isOwner{
	    require(address(this).balance >= amount);
	    require(to != address(0));
	    to.transfer(amount);	
    }
	
    function close() public isOwner {
        selfdestruct(owner);
    }

    modifier isOwner(){
        require(owner == msg.sender);
    	_;
    }
}