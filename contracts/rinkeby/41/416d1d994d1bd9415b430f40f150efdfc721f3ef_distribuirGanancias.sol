/**
 *Submitted for verification at Etherscan.io on 2021-09-10
*/

// SPDX-License-Identifier: MIT 

pragma solidity >= 0.7.0 < 0.8.0;

contract distribuirGanancias{
    
    //datos contratacion
    string nombre_cliente;
    string nombre_servicio;
    string codigo_servicio;
    string declaracion_terminos;
    
    uint256 fecha_creacion;
    uint256 fecha_vencimiento;
    
    
    uint256 costo_entrada;
    
    address propietario;
    
    //esta es la persona que instancia el contrato, es decir el que hace el deploy y la ejecución en la blockchain
    constructor() payable {
        propietario = msg.sender;
    }
    
    modifier soloPropietario {
        require(msg.sender == propietario);
        _;
    }
    
    function consultarPropiedad() view public returns(address){
        return propietario;
    }
    
    //solo el propietario puede cambiar la propiedad del contrato
    function cambiarPropietario( address _nuevoPropietario ) public soloPropietario{
        propietario = _nuevoPropietario;
    }
    
    function setTerminos(string memory _nueva_declaracion, string memory _nombre_cliente, string memory _nombre_servicio, string memory _codigo_servicio, uint256 numero_dias) public soloPropietario{
        
        declaracion_terminos = _nueva_declaracion;
        
        nombre_cliente = _nombre_cliente;
        nombre_servicio = _nombre_servicio;
        codigo_servicio = _codigo_servicio;
        fecha_creacion = block.timestamp;
        fecha_vencimiento = block.timestamp + (numero_dias * 1 days);
    }
    
    //establecer costo de la entrada
    function setCostoServicio(uint256  _costo_entrada) public soloPropietario {
        costo_entrada = _costo_entrada;
    }
    
    function getTerminos() public view returns(string memory, string memory, string memory, string memory){
        return (declaracion_terminos, nombre_cliente, nombre_servicio, codigo_servicio);
    }
    
    function getFechas() public view returns(uint256, uint256){
        return (fecha_creacion, fecha_vencimiento);
    }
    
    function getCliente() public view returns(string memory){
        return declaracion_terminos;
    }
    
    function getPrecioServicio() public view returns(uint256){
        return (costo_entrada /(1 ether));
    }
    
    function pagar() public payable{
        require(msg.value == costo_entrada);
    }
    
    function consultarBalanceContrato() public view soloPropietario returns (uint256  x){
       return address(this).balance;
    }
    
    function retirarTodo() payable public soloPropietario{
        msg.sender.transfer(address(this).balance);
    } 
    
}