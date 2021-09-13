/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// SPDX-License-Identifier: GPL-3.0
/*
    contrato principal de registro de sociedad con sus miembros y capitales para iniciar operaciones
    
    FUNCIONES:
    
    
*/
pragma solidity >=0.7.0 <0.9.0;

contract SociedadAdministradoraCriptoActivos{
    
    string public sociedad;
    address manager; // dirección del que administra el contrato
    uint256 public priceStock; // valor de una acción de participación
    uint256 partidaInversiones;
    uint256 public inversionSocios;
    uint256 decimalsParticipacion;
    
    mapping ( address => Socio) socio; //datos de los socios asociados a su billetera
    mapping ( address => Afiliados) afiliado; //datos de los socios asociados a su billetera
    
    address [] socios_array;  //arreglo con las direcciones de los socios
    address [] afiliados_array;  //arreglo con las direcciones de los afiliados
    
    struct Socio{
        string name;
        string id;
        address direccion_cartera;
        uint porcentaje_participacion;
        uint256 capital_invertido;
        uint256 bloqueCreacion;    

    }
    
    struct Afiliados{
        string name;
        string id;
        address direccion_cartera;
        uint currentBalance;
        
        
    }
    
    modifier SoloSocios(){ //solo los socios pueden ejecutar las funciones con este modificador
        require(socio[msg.sender].direccion_cartera == msg.sender);
        _;
    }
    
    modifier SoloManager(){ //solo el  Director Principal pueden ejecutar las funciones con este modificador
        require(manager == msg.sender);
        _;
    }
    
    modifier NoEnviarEther(){//para asergurar que al ejecutar una funcion no se pague ETHER, solo el fee del gas en cualquier caso
        require(msg.value == 0);
        _;
    }
    
    constructor ( string memory _nombre_sociedad, uint256 _precioStock) NoEnviarEther payable{
         // al crear la sociedad el capital debe ser 0, luego los socios invertiran individualmente
        manager = msg.sender;
        sociedad = _nombre_sociedad;
        priceStock = _precioStock;
        decimalsParticipacion = 1000;
    }
    
    function getBalanceSociedad() public view returns (uint256){
        return address(this).balance;
    }
    
    
    function addSocio(string memory _name, string memory _id, address _nuevo_socio) external payable NoEnviarEther SoloManager {
        require(socio[msg.sender].direccion_cartera != _nuevo_socio);// para no reperir al agregar socios nuevos
        
        socio[_nuevo_socio].name = _name;
        socio[_nuevo_socio].id = _id;
        socio[_nuevo_socio].direccion_cartera = _nuevo_socio;
        socio[_nuevo_socio].capital_invertido = 0;
        socio[_nuevo_socio].porcentaje_participacion = 0;
        socio[_nuevo_socio].bloqueCreacion = block.number;
        
        
        //agregamos la direccion a un arreglo de socios para iterar
        socios_array.push(_nuevo_socio);
    }
    
    function getAllSocios() external view SoloSocios returns( address[]  memory){
        
        return socios_array;
    }
    
    function getDatosSocio()public view returns(string memory, address, uint256){
        
        return(socio[msg.sender].name, socio[msg.sender].direccion_cartera, socio[msg.sender].capital_invertido);
    }
    
    function getPorcentajeParticipacion()external view SoloSocios returns(uint){
        uint256 porcentaje =  decimalsParticipacion * socio[msg.sender].capital_invertido  / inversionSocios;
        return porcentaje;
        
    }
    
    /*esta funcion permite a los socios enviar capital a la sociedad de modo de aumentar su 
    participación y su poder de voto 
    *el porcentaje de participación también establece el porcentaje de derecho a los benefios de la actividad así como 
    a los beneficios productos de la terminación del contrato 
    */
    
    event Capital(uint256 c);

    function sendCapital()public SoloSocios payable returns (uint){
        
        socio[msg.sender].capital_invertido += msg.value;
        inversionSocios += msg.value;
        calcularPorcentajeParticipacion(msg.sender);                
        calcularPriceStock();
        return  socio[msg.sender].porcentaje_participacion;
        
    }
    
    function calcularPorcentajeParticipacion(address _direccion) internal returns(uint256){
        socio[_direccion].porcentaje_participacion =  decimalsParticipacion * socio[_direccion].capital_invertido  / inversionSocios;
    
        return socio[_direccion].porcentaje_participacion;
    }
    
    //envio de ganancias de las actividades de la sociedad al balance del contrato
    function sendProfits()public payable returns (bool _status){
        calcularPriceStock();
        return true;
    }
    
    event GananciasSociedad(uint256 _ganancias);
    event Porcentaje(uint256 _porcentaje);
    
    function getCalculoProfit()public payable returns(uint256 _ganancias){
        uint256 gananciasSociedad = address(this).balance - inversionSocios;
        
        emit GananciasSociedad(gananciasSociedad);
        uint256 gananciasSocio = gananciasSociedad * calcularPorcentajeParticipacion(msg.sender)/ 1000;
        emit Porcentaje(calcularPorcentajeParticipacion(msg.sender));
        return gananciasSocio;
    }
    
    function calcularPriceStock()internal returns(uint256 _valor_stock){
        priceStock = address(this).balance  / 1000;
        return priceStock;
    }
    
    //retiro de ganancias 
    function retirarGanancias(uint256 monto)public payable NoEnviarEther SoloSocios returns(bool _status){
        require(getCalculoProfit() >= monto);
        msg.sender.transfer(monto);
        return true;
    }
    
    
    /*
    function recalcularParticipacionSocios() private {
        
        uint arrayLength = socios_array.length;
        
        for (uint i=0; i< arrayLength; i++) {
            //el calculo de % se hace en base a 1000% y no a 100% para resolver el problema de precisión por no tener float en solidity    
           socio[socios_array[i]].porcentaje_participacion =  decimalsParticipacion * socio[socios_array[i]].capital_invertido  / (address(this).balance);
        
            
        }
    }
    
    */
    
}