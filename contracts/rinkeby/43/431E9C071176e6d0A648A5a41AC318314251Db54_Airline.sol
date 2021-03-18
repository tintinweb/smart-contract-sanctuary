/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

pragma solidity ^0.5.16;

contract Airline { 
    address public owner;

    //Customer
    struct Cliente{
        uint nroPuntosCliente;
        uint nroVuelosTotales;
    }

    //Flight
    struct Vuelo{
        string nombreVuelo;
        uint256 precioVuelo;
    }

    //flights
    Vuelo[] public vuelos;

    //customers
    mapping(address => Cliente) public clientes;

    //vuelos que tiene comprado un usuario
    //customerFlights
    mapping(address => Vuelo[]) public  vuelosClientes;

    //total de vuelos que ha comprado un cliente
    //customerTotalFlight
    mapping(address => uint) public total_vuelosCliente;

    //evento para que cada vez que un cliente compre un vuelo este sea emitido
    event VueloComprado(address indexed cliente, uint precio, string vuelo);

    uint etherPorPunto = 0.5 ether;

    constructor() public{
        owner = msg.sender; //persona q despliega el SC
        vuelos.push(Vuelo('Tokio', 4 ether));
        vuelos.push(Vuelo('Germany', 3 ether));
        vuelos.push(Vuelo('Madrid', 3 ether));
    }

    //funcion para poder comprar un vuelo
    //byFlight
    function ComprarVuelo(uint indexVuelo)public payable{
        Vuelo memory vuelo = vuelos[indexVuelo];
        require(msg.value == vuelo.precioVuelo);
        //identificar al cliente para asignarle dicho vuelo

        Cliente storage cliente = clientes[msg.sender];
        cliente.nroPuntosCliente += 5;
        cliente.nroVuelosTotales += 1;
        vuelosClientes[msg.sender].push(vuelo);
        total_vuelosCliente[msg.sender]++;

        emit VueloComprado(msg.sender, vuelo.precioVuelo, vuelo.nombreVuelo);
    }

    //recuperar el numero de vuelos totales que tiene la aerolinea
    function totalVuelosAir() public view returns(uint){
        return vuelos.length;
    }

    //los clientes deben poder recuperar dinero por los puntos adquiridos con la compra de los vuelos
    function cambiarPuntos() public {
        Cliente storage cliente = clientes[msg.sender];
        uint etherCliente = etherPorPunto * cliente.nroPuntosCliente;
        msg.sender.transfer(etherCliente);
        cliente.nroPuntosCliente = 0;
    }

    //cantidad de puntos con los que cuenta un cliente
    function getEtherTotalesPorPuntos()public view returns(uint){
        Cliente memory cliente = clientes[msg.sender];
        return cliente.nroPuntosCliente * etherPorPunto;
    }

    //recuperar el balance de la aerolinea
   function getAirlineBalance() public isOwner view returns (uint) {
      address airlineAddress = address(this);
      return airlineAddress.balance;
     }

    modifier isOwner(){
        require(msg.sender == owner);
        _;
    }
}