pragma solidity ^0.5.1;

contract ContratoRifaBenefica {
    
    address moderador;
    address oraculo;
    uint256 Maximo;
    mapping (address => bool) blackList;
    mapping (address => uint256) reputacion_org;
    mapping (address => bool) oraculos_aprobados;
    /*
    Se encarga de mantener las rifas creadas
    */
    struct rifa {
        uint256 Max;
        uint256 Vendido;
        bool activa;
        mapping (uint256 => address payable) ticket;//Se debe crear de tipo payble para poder hacer transfer
        address payable owner; //Se debe crear de tipo payble para poder hacer transfer
        address oraculo;
    }
    
    rifa[] listaRifa;
    
    /*
    Constructor
    @_max: hace referencia a la cantidad maximas de tickets que puede crear cualquier sorteo
    */
    constructor (uint256 _max) public {
        moderador = msg.sender;
        Maximo = _max;
    }
    /*
    Crear_rifa: Crea una nueva rifa.
    @_cantMax: hace referencia a la cantidad maximas de tickets que puede vender este sorteo
    @_ora: direccion de oraculo la cual va decir el tikect ganador del sorteo
    retur _id: el id del sorteo
    */
    function Crear_rifa(uint256 _cantMax, address _ora) public returns(uint256 _id){
        require(_cantMax <= Maximo);
        require(!blackList[msg.sender]);
        require(oraculos_aprobados[_ora]);
        rifa memory aux;
        aux.owner = msg.sender;
        aux.Max = _cantMax;
        aux.activa = true;
        aux.oraculo = _ora;
        listaRifa.push(aux);
        _id = listaRifa.length;
        return (_id);
    }
    /*
    Compra_Ticket: Vende un ticket este ticket se relaciona directamente al address
    @_idRifa: hace referencia al sorteo al que quiere participar
    @_nroTicket: hace referencia al numero de ticket que quiere comprar, no debe estar comprado previamente y debe ser un numero entre 0 y el maximo del sorteo
    */
    function Compra_Ticket(uint256 _idRifa, uint256 _nroTicket) public payable {
        require(msg.value == 1 ether);
        require(listaRifa[_idRifa].activa);
        require(_nroTicket <= listaRifa[_idRifa].Max);
        require(listaRifa[_idRifa].ticket[_nroTicket] == address(0));
        listaRifa[_idRifa].ticket[_nroTicket] = msg.sender;
        listaRifa[_idRifa].Vendido ++;
    }
    /*
    Ticket_Ganador: El oraculo asignado es el encargado de asignar el ganador, el ganador recibe su recompenza y el organizador tambien.
    @_idRifa: hace referencia al sorteo 
    @_nroTicket: hace referencia al numero de ticket ganador, debe haber un ganador al menos
    */
    function Ticket_Ganador(uint256 _idRifa, uint256 _nroTicket) public returns (bool _salida){
        require(msg.sender == listaRifa[_idRifa].oraculo);
        require(listaRifa[_idRifa].activa);
        require(listaRifa[_idRifa].ticket[_nroTicket] != address(0));
        listaRifa[_idRifa].activa = false;
        address(listaRifa[_idRifa].ticket[_nroTicket]).transfer(listaRifa[_idRifa].Vendido * 0.5 ether);
        address(listaRifa[_idRifa].owner).transfer(listaRifa[_idRifa].Vendido * 0.5 ether);
        reputacion_org[listaRifa[_idRifa].owner]++;
        return(true);
    }
    /*
    Devolver_Tickets: En caso de que el moderador vea algo fuera de lugar, puede cancelar el sorteo y devolver los tickets vendidos.
    @_idRifa: hace referencia al sorteo 
    */
    function Devolver_Tickets(uint256 _idRifa) public{
        require(msg.sender == moderador);
        require(listaRifa[_idRifa].activa);
        require(listaRifa[_idRifa].Vendido > 0);
        listaRifa[_idRifa].activa = false;
        blackList[listaRifa[_idRifa].owner] = true;
        for (uint256 i = 1; i <=  listaRifa[_idRifa].Max; i++){
            if(listaRifa[_idRifa].ticket[i] != address(0)){
                address(listaRifa[_idRifa].ticket[i]).transfer(1 ether);
            }
        }
    }
    /*
    Sacar_BlackList: Saca de la lista negra a un organizador en caso de que se demuestre que fue un error.
    @_dir: address del organizador
    */
    function Sacar_BlackList(address _dir) public {
        require(msg.sender == moderador);
        require(blackList[_dir]);
        blackList[_dir] = false;
    }
    /*Obtener_Reputacion: Un comprador puede ver la reputacion (cantidad de sorteos exitosos) de un organizador
    @_dir: address del organizador
    */
    function Obtener_Reputacion(address _dir) public view returns(uint256 _rep){
        return reputacion_org[_dir];
    }
    /*Registrar_Oraculo: Solo el moderador puede asignar los oraculos permitidos para los eventos.
    @_ora: address del oraculo
    */
    function Registrar_Oraculo(address _ora) public {
        require(msg.sender == moderador);
        require(blackList[_ora]);
        oraculos_aprobados[_ora] = true;
    }
    /*Banear_Oraculo: el moderador puede eliminar de la lista oraculos no confiables.
    @_ora: address del oraculo
    */
    function Banear_Oraculo(address _ora) public {
        require(msg.sender == moderador);
        require(oraculos_aprobados[_ora]);
        oraculos_aprobados[_ora] = false;
    }
    
}