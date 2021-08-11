/**
 *Submitted for verification at Etherscan.io on 2021-08-10
*/

pragma solidity ^0.4.24;

contract Airline {
    address public owner;
    //Estructura de una persona:
    //loyaltyPoints: puntos de lealtad (brindados cuando compras vuelos)
    //totalFlights: número de vuelos que tiene el cliente
    struct Customer {
        uint256 loyaltyPoints;
        uint256 totalFlights;
    }
    //Estructura de un Vuelo:
    //name: nombre del vuelo
    //price: precio del vuelo
    struct Flight {
        string name;
        uint256 price;
    }

    uint256 etherPerPoint = 0.5 ether;

    Flight[] public flights;

    mapping(address => Customer) public customers;
    mapping(address => Flight[]) public customerFlights;
    mapping(address => uint256) public customerTotalFlights;
    //Evento cuando se compra un vuelo
    event FlightPurchased(
        address indexed customer,
        uint256 price,
        string flight
    );

    constructor() {
        //Asignamos el address que instancia el contrato
        owner = msg.sender;
        //Instanciamos unos vuelos
        flights.push(Flight("Tokio", 4 ether));
        flights.push(Flight("Germany", 3 ether));
        flights.push(Flight("Madrid", 3 ether));
    }

    //Función para comprar vuelos
    //flightIndex: index del vuelo []
    function buyFlight(uint256 flightIndex) public payable {
        Flight flight = flights[flightIndex];
        require(msg.value == flight.price);

        Customer storage customer = customers[msg.sender];
        customer.loyaltyPoints += 5;
        customer.totalFlights += 1;
        customerFlights[msg.sender].push(flight);
        customerTotalFlights[msg.sender]++;

        emit FlightPurchased(msg.sender, flight.price, flight.name);
    }

    //Función que devuelve el total de vuelos que tiene el contrato
    function totalFlights() public view returns (uint256) {
        return flights.length;
    }

    //Función para recuperar las divisas por los puntos de lealtad que tiene el cliente
    function redeemLoyaltyPoints() public {
        Customer storage customer = customers[msg.sender];
        uint256 etherToRefund = etherPerPoint * customer.loyaltyPoints;
        msg.sender.transfer(etherToRefund);
        customer.loyaltyPoints = 0;
    }

    //Función que devuelve el ether que tiene el cliente en caso de recuperar los puntos de lealtad
    function getRefundableEther() public view returns (uint256) {
        return etherPerPoint * customers[msg.sender].loyaltyPoints;
    }

    //Función para recuperar el balance que tiene el contrato
    function getAirlineBalance() public view isOwner returns (uint256) {
        address airlineAddress = this;
        return airlineAddress.balance;
    }

    modifier isOwner() {
        require(msg.sender == owner);
        _;
    }
}