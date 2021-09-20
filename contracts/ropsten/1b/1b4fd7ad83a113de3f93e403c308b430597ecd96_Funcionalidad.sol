// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "./NFTVehiculo.sol";

contract Funcionalidad is NFTVehiculo {
    
    
    struct Pagos{
        bool _EstaEnVenta; //Predeterminado en false
        address _comprador;
        uint256 _precio;
        HistVentas[] _HistVentas;
    }
    
    struct HistVentas{
        address _Propietarios;
        uint256 _ValorDeVenta;
    }

    
    // mapping de token a Struct de pagos
    mapping (uint256 => Pagos) private _Ventas;
 
    address contract_owner;

    constructor(string memory name_, string memory symbol_) NFTVehiculo(name_, symbol_) {
        contract_owner = _msgSender();
    }
    
    


// Poner coche en venta

    function EnVenta(uint256 tokenId, address comprador, uint256 precio) public returns(address, bool, uint256){
        require(_isApprovedOrOwner(_msgSender(), tokenId), "No eres el propietario o no estas autorizado");     //Si es owner implica que existe _exists() no necesario
        require(ownerOf(tokenId) != comprador, "No puedes venderte a ti mismo");
        _Ventas[tokenId]._comprador = comprador;
        _Ventas[tokenId]._EstaEnVenta = true;
        _Ventas[tokenId]._precio = precio * 1000000000; //En Gweis ahora * 1 Ether
        return(_Ventas[tokenId]._comprador, _Ventas[tokenId]._EstaEnVenta, _Ventas[tokenId]._precio);
    }
    
    function EstaEnVenta(uint256 tokenId) public view returns(Pagos memory) {
        return(_Ventas[tokenId]);
    }
    
    
    function _CancelarVenta(uint256 tokenId) internal virtual{
        _Ventas[tokenId]._comprador = address(0);
        _Ventas[tokenId]._EstaEnVenta = false;
        _Ventas[tokenId]._precio = 0;
    }

    
    function CancelarVenta(uint256 tokenId) public returns (string memory) {
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _CancelarVenta(tokenId);
        return("Ya no esta a la venta");
    }

    function Comprar(uint256 tokenId) public payable {
        require(_Ventas[tokenId]._comprador == _msgSender(), "No estas autorizado como comprador"); //Solo si has sido designado comprador puede comprarlo
        require(msg.value == _Ventas[tokenId]._precio, "El valor de pago no es correcto");      
        
        address payable owner1 = payable(ownerOf(tokenId));     
        uint256 pago = _Ventas[tokenId]._precio;
        
        _CancelarVenta(tokenId);
        _transfer(owner1, _msgSender(), tokenId);
        
        owner1.transfer(pago);
        _Ventas[tokenId]._HistVentas.push(HistVentas(_msgSender(), pago));       //En el momento de hacer Mint() incluir el primer propietario en este array
        
    }
    
    function VerHistCompradores(uint256 tokenId) public view returns(HistVentas[] memory) {
        return(_Ventas[tokenId]._HistVentas);
    }
    
    
// Car sharing

    struct RegistroProp {
            address _direccion;
            uint256 _HoraInic;    //Se podría usar timestamp, Es necesario realizar una transaccion para poder cancelar el alquiler de forma efectiva.
            uint _horas;            //Sería interesante hacer un oráculo para que se ejecute automáticamente
        }
        
    struct Alquiler {
        bool _disponible;           //Marca si el coche esta disponible para poder alquilarse
        bool _alquilado;            //Marca si el coche está alquilado en este momento
        uint256 _PrecioHora;
        uint256 _NumUsuarios;       //Num de usuarios que lo han utilizado
        RegistroProp[] _RegistroProp;
    }
    
    mapping (uint256 => Alquiler) private _Alquiler;        //Mapping del vehículo a sus datos de alquiler
    
    
    struct Registros {
        uint256 _tokenId;
        uint256 _numRegistro;
    }
    
    struct Historial {
        uint256 _numUsos;
        Registros[] _Registros;
    }
    
    mapping (address => Historial) private _Historial;          //Mapping para guardar la actividad de un usuario

    function PonerEnAlquiler(uint256 tokenId, uint256 PrecioHora) public {      //Quiza sea necesario un tiempo máximo
        require(_isApprovedOrOwner(_msgSender(), tokenId), "No eres el propietario o no estas autorizado");
        
        _Alquiler[tokenId]._disponible = true;
        _Alquiler[tokenId]._PrecioHora = PrecioHora * 1000000000; //En GWeis
    }

    function RetirarDelAlquiler(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "No eres el propietario o no estas autorizado");
        
        _Alquiler[tokenId]._disponible = false;
        _Alquiler[tokenId]._PrecioHora = 0;         //Quiza instruccion innecesaria
    }
    
    function DatosDeAlquiler(uint256 tokenId) public view returns(Alquiler memory) {
        require(_exists(tokenId), "El Id no existe");
        return(_Alquiler[tokenId]);
    }

    function _sePuedeAlquilar(uint256 tokenId) internal view virtual returns(bool) {
        return(_Alquiler[tokenId]._disponible);
    }

    //    function _estaAlquilado(uint256 tokenId) internal view virtual returns(bool) {
    //    return(_Alquiler[tokenId]._alquilado);      //Si no se usa oraculo hay que comprobar si se han consumido las horas
    //    }

    function Alquilar(uint256 tokenId, uint256 horas) public payable {
        require(_exists(tokenId), "El Id no existe");
        require(_sePuedeAlquilar(tokenId), "El vehiculo no esta en alquiler");
        //require(!_estaAlquilado(tokenId), "El vehiculo ya esta alquilado");
        
        if (_Alquiler[tokenId]._NumUsuarios != 0) {
            require(_FinDelAnterior(tokenId), "El vehiculo sigue en alquiler");
        }
        
        uint256 pagoTotal = _Alquiler[tokenId]._PrecioHora * horas;
        require(msg.value == pagoTotal, "El valor pagado es incorrecto");
        _Alquiler[tokenId]._NumUsuarios += 1;
        uint256 NumUsuarios = _Alquiler[tokenId]._NumUsuarios - 1;  //Para que comience con el 0
        
        _Alquiler[tokenId]._alquilado = true;
        _Alquiler[tokenId]._RegistroProp.push(RegistroProp(_msgSender(), block.timestamp, horas));

        _GuardarUsuario(tokenId, _msgSender(), NumUsuarios);
        
        address payable owner1 = payable(ownerOf(tokenId));
        owner1.transfer(pagoTotal);

    }


    function _GuardarUsuario(uint256 tokenId, address user, uint256 numRegistro) internal virtual {
        _Historial[user]._numUsos += 1;
        _Historial[user]._Registros.push(Registros(tokenId, numRegistro));
    }

    function InfoAlquilerUsuario(address user) public view virtual returns(Historial memory) {          //Se pasa una address y se obtiene (token, num registro)
        return(_Historial[user]);
    }

    function VerRegistro(uint256 tokenId, uint256 numRegistro) public view virtual returns(RegistroProp memory) {       //Se pasa un (token, num registro) y se obtiene la informacion del alquiler de ese registro en ese token)
        return(_Alquiler[tokenId]._RegistroProp[numRegistro]);
    }

    function _FinDelAnterior(uint256 tokenId) internal view virtual returns(bool) {         //Nos dice si se ha terminado el tiempo del alquiler anterior (En el caso de que no hayamos puesto confirmacion)
        uint256 UltimoUser = _Alquiler[tokenId]._NumUsuarios - 1;
        uint256 HoraInic = _Alquiler[tokenId]._RegistroProp[UltimoUser]._HoraInic;
        uint256 HoraFin = HoraInic + _Alquiler[tokenId]._RegistroProp[UltimoUser]._horas * 1 hours; //poner hours (minutes para minutos)
        bool HaTerminado;
        
        if (block.timestamp > HoraFin) {        //Si es la primera vez, block.timestap siempre sera > HoraFin = 0
            HaTerminado = true;
        }
        else {
            HaTerminado = false;
        }
        return (HaTerminado);
    }
    
    
    
    
    //function ConfirmarFinAlquiler(uint256 tokenId) public {          //Esta funcion podria ser llamada por un Oraculo, por un usuario o que directamente se efectue al realquilar
    //    require(_exists(tokenId), "El Id no existe");
    //    require(_estaAlquilado(tokenId), "El vehiculo no esta alquilado");
        
    //    uint256 HoraInic = _Alquiler[tokenId]._RegistroProp[_Alquiler[tokenId]._NumUsuarios - 1]._HoraInic;
    //    uint256 HoraFin = HoraInic + _Alquiler[tokenId]._RegistroProp[_Alquiler[tokenId]._NumUsuarios - 1]._horas * 1 hours;
    //    require(block.timestamp > HoraFin);
    //    
    //    _Alquiler[tokenId]._alquilado = false;
        
    //    }



// Pasaporte digital

    
    //Recambio
    struct RecambioPieza {
        address _agente;        //Agente que realiza la operacion
        uint256 _fecha;         //Fecha de la operacion
        Producto _producto;     //Producto, pieza incorporada
        string _info;           //Informacion adicional
    }
    
    struct Producto {
        uint256 _productCode;       //Codigo de la pieza
        uint256 _productBatch;      //Número de lote o unidad
        string _productName;        //Nombre de la pieza
        address _productOwner;      //Fabricante
    }


    //Evento
    struct Evento {
        address _agente;
        uint256 _fecha;
        string _eventName;
        string _info;
    }
    
    
    //Revision
    struct Revision {
        address _agente;
        uint256 _fecha;
        uint256 _kilometraje;
        string _resultado;
        string _info;
    }
    
    
    
    //Mappings del tokenId a sus historiales de recambios, eventos y revisiones
    mapping (uint256 => RecambioPieza[]) _RecambioPieza;
    mapping (uint256 => Evento[]) _Evento;
    mapping (uint256 => Revision[]) _Revision;
    
    
    //Mapping aprobados para escribir en el PD
    mapping (address => mapping (uint256 => bool)) private _aprobadoGeneral;        //Mapping de agente => tokenId => true/false
    mapping (uint256 => address) private _permisoUnico;                             //tokenId => direccion agente, cambia a 0 cuando el agente ejecuta la operacion 



    function PermisoUnico(uint256 tokenId, address agente) public{           //La funcion permite dar permisos de escritura en el PD una vez
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _permisoUnico[tokenId] = agente;
    }
    
    function PermisoGeneral(uint256 tokenId, address agente, bool aprobado) public{         //La funcion permite dar permisos de forma indefinida
        require(_isApprovedOrOwner(_msgSender(), tokenId));
        _aprobadoGeneral[agente][tokenId] = aprobado;
    }

    function _PuedeEscribir(address agente, uint256 tokenId) internal virtual returns(bool) {           //Funcion de ayuda para permisos
        require(_exists(tokenId), "El vehiculo no existe");
        bool puede = (_permisoUnico[tokenId] == agente || _aprobadoGeneral[agente][tokenId] || _isApprovedOrOwner(agente, tokenId));
        
        if (_permisoUnico[tokenId] == agente) {
            _permisoUnico[tokenId] = address(0);
        }
        
        return(puede);
    }

    function ARecambio(uint256 tokenId, uint256 productCode, uint256 productBatch, string memory productName, address productOwner, string memory info) public {
        require(_PuedeEscribir(_msgSender(), tokenId));
        Producto memory _producto1;
        _producto1._productCode = productCode;
        _producto1._productBatch = productBatch;
        _producto1._productName = productName;
        _producto1._productOwner = productOwner;
        _RecambioPieza[tokenId].push(RecambioPieza(_msgSender(), block.timestamp, _producto1, info));
    }
    
    function VerRecambios(uint256 tokenId) public view virtual returns (RecambioPieza[] memory) {
        return (_RecambioPieza[tokenId]);
    }
    
    function AEvento(uint256 tokenId, string memory eventName, string memory info) public {
        require(_PuedeEscribir(_msgSender(), tokenId));
        _Evento[tokenId].push(Evento(_msgSender(), block.timestamp, eventName, info));
    }
    
    function VerEventos(uint256 tokenId) public view virtual returns (Evento[] memory) {
        return(_Evento[tokenId]);
    }
    
    function ARevision(uint256 tokenId, uint256 kilometraje, string memory resultado, string memory info) public {
        require(_PuedeEscribir(_msgSender(), tokenId));
        _Revision[tokenId].push(Revision(_msgSender(), block.timestamp, kilometraje, resultado, info));
    }

    function VerRevisiones(uint256 tokenId) public view virtual returns (Revision[] memory) {
        return(_Revision[tokenId]);
    }






//Recordar que _Mint hay que establecer que solo lo pueda hacer el owner del contrato


}