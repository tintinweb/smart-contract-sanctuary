// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC20.sol";
import "./Ownable.sol";

contract Kermes is Ownable {
    // Instancia del contrato token
    ERC20Basic private token;
    

    constructor()  {
        token = new ERC20Basic(1000000);
    }

    // --------------------------- Declaraciones ---------------------------

    // Estructura de datos de clientes
    struct cliente {
        uint tokensComprados;
        string[] atraccionesDisfrutadas;
    }

    // Registro de clientes
    mapping(address => cliente) public Clients;


    // --------------------------- Manejo de tokens ---------------------------

    // Establecer el precio de un Token =>  1 token = 1 eth
    function tokenPrice(uint _numTokens) internal pure returns(uint) {
        return _numTokens*(1 ether);
    }

    // Funciona para comprar token
    function buyTokens(uint _numTokens) public payable {
        uint price = tokenPrice(_numTokens);
        require(msg.value >= price);
        uint returnValue = msg.value - price; // Diferencia de lo que el cliente paga
        if(returnValue > 0) {
            payable(msg.sender).transfer(returnValue); // Se regresa la diferencia
        }
        uint balance = balanceOf();
        require(_numTokens <= balance);
        token.transfer(msg.sender, _numTokens);
        Clients[msg.sender].tokensComprados = _numTokens;
    }

    // Devuelve la cantidad de tokens disponibles
    function balanceOf() public view returns(uint) {
        return token.balanceOf(address(this));
    }

    // Devuelve la cantidad de tokens (para cliente)
    function myTokens() public view returns(uint) {
        return token.balanceOf(msg.sender);
    }

    // Agrega mas tokens
    function generateNewTokens(uint _numTokens) public onlyOwner {
        token.increaseTotalSupply(_numTokens);
    }


    // --------------------------- Manejo de kermes ---------------------------

    // Eventos
    event DisfrutaJuegoMecanico(string);
    event NewJuegoMecanico(string _name, uint _price);
    event BajaDeJuegoMecanico(string);

    event NewComida(string _name, uint _price);
    event BajaDeComida(string);
    event comerComida(string);

    struct JuegoMecanico {
        string name;
        uint price;
        bool status;
    }

    struct Comida {
        string name;
        uint price;
        bool status;
    }

    // Relacion de un nombre de juego mecanico con una estructura de datos del juego
    mapping(string => JuegoMecanico) public MappingJuegoMecanico;

    mapping(string => Comida) public MappingComida;

    string[] listaJuegoMecanico;

     string[] listaComidas;

    // Historial de cliente
    mapping(address => string[]) HistorialJuegoMecanico;
    mapping(address => string[]) HistorialComidas;

    // Dar de alta juegoMecanico
    function nuevoJuegoMecanico(string memory _nameJuegoMecanico, uint _precio) public onlyOwner {
        MappingJuegoMecanico[_nameJuegoMecanico] = JuegoMecanico(_nameJuegoMecanico, _precio, true);
        listaJuegoMecanico.push(_nameJuegoMecanico);
        emit NewJuegoMecanico(_nameJuegoMecanico, _precio);
    }
    function nuevaComida(string memory _nameComida, uint _precio) public onlyOwner {
        MappingComida[_nameComida] = Comida(_nameComida, _precio, true);
        listaComidas.push(_nameComida);
        emit NewComida(_nameComida, _precio);
    }

    function bajaJuegoMecanico(string memory _nameJuegoMecanico) public onlyOwner {
         MappingJuegoMecanico[_nameJuegoMecanico].status = false;
         emit BajaDeJuegoMecanico(_nameJuegoMecanico);
    }
    function bajaComida(string memory _nameJuegoMecanico) public onlyOwner {
         MappingComida[_nameJuegoMecanico].status = false;
         emit BajaDeComida(_nameJuegoMecanico);
    }

    function juegosDisponibles() public view returns(string[] memory) {
        return listaJuegoMecanico;
    }
    function comidasDisponibles() public view returns(string[] memory) {
        return listaComidas;
    }

    function subirseJuegoMecanico(string memory _nameJuegoMecanico) public {
        // uint tokenPrice = MappingJuegoMecanico[_nameJuegoMecanico].price;
        require(MappingJuegoMecanico[_nameJuegoMecanico].status == true);
        require(MappingJuegoMecanico[_nameJuegoMecanico].price <= myTokens());
        token.transferToSmartContract(msg.sender, address(this), MappingJuegoMecanico[_nameJuegoMecanico].price);
        HistorialJuegoMecanico[msg.sender].push(_nameJuegoMecanico);
        emit DisfrutaJuegoMecanico(_nameJuegoMecanico);
    }
    function comprarComida(string memory _nameComida) public {
        require(MappingComida[_nameComida].status == true);
        require(MappingComida[_nameComida].price <= myTokens());
        token.transferToSmartContract(msg.sender, address(this), MappingJuegoMecanico[_nameComida].price);
        HistorialComidas[msg.sender].push(_nameComida);
        emit comerComida(_nameComida);
    }

    // visualizar el historial de juegos mecanicos de un cliente
    function historialJuegosMecanicos() public view returns(string[] memory) {
        return HistorialJuegoMecanico[msg.sender];
    }
    function historialDeComida() public view returns(string[] memory) {
        return HistorialComidas[msg.sender];
    }

    // Cliente devuelve tokens
    function devolverTokens(uint _numTokens) public payable {
        require(_numTokens > 0);
        require(_numTokens <= myTokens());
        token.transferToSmartContract(msg.sender, address(this), _numTokens); // tokens a el smart contrct
        payable(msg.sender).transfer(tokenPrice(_numTokens));  // devolucion de eth a cliente
    }


 }