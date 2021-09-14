/**
 *Submitted for verification at BscScan.com on 2021-09-14
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
    uint256 porcentaje_penalizacion_fin_unilateral;
    uint256 public saldo_finiquitos;
    uint256 public debitado;
    
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
        uint256 acu_ganancias;
        uint256 ultimo_retiro;
        uint256 limite_permitido_inversion;

    }
    
    struct Afiliados{
        string name;
        string id;
        address direccion_cartera;
        uint currentacu_ganancias;
        
        
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
    
    constructor ( string memory _nombre_sociedad) NoEnviarEther payable{
         // al crear la sociedad el capital debe ser 0, luego los socios invertiran individualmente
        manager = msg.sender;
        sociedad = _nombre_sociedad;
        priceStock = 0;
        decimalsParticipacion = 1000;
        
    }
    
    function getacu_gananciasSociedad() public view returns (uint256){
        return address(this).balance;
    }
    
    
    function addSocio(string memory _name, string memory _id, address _nuevo_socio, uint256 limite_permitido_inversion) public payable NoEnviarEther SoloManager {
        require(socio[msg.sender].direccion_cartera != _nuevo_socio);// para no reperir al agregar socios nuevos
        
        socio[_nuevo_socio].name = _name;
        socio[_nuevo_socio].id = _id;
        socio[_nuevo_socio].direccion_cartera = _nuevo_socio;
        socio[_nuevo_socio].capital_invertido = 0;
        socio[_nuevo_socio].porcentaje_participacion = 0;
        socio[_nuevo_socio].bloqueCreacion = block.number;
        socio[_nuevo_socio].limite_permitido_inversion = limite_permitido_inversion;
        
        //agregamos la direccion a un arreglo de socios para iterar
        socios_array.push(_nuevo_socio);
    }
    
    function setLimiteInversion(address _socio, uint256 _limite)public SoloManager returns(bool _status){
        socio[_socio].limite_permitido_inversion = _limite;
        return true;
    }
    
    function setPorcentajePenalizacionSalidaUnilateral(uint256 _porcentaje)public SoloManager returns(bool _status){
        require(_porcentaje <= 100);//no se puede pasar del 100%
        porcentaje_penalizacion_fin_unilateral = _porcentaje;
        return true;
    }
    
    function getAllSocios() external view SoloSocios returns( address[]  memory){
        
        return socios_array;
    }
    
    function getDatosSocio() public view returns(string memory, address, uint256 _capital_invertido, uint256 _acu_ganancias, uint256 _ultimo_retiro, uint256 blk_creacion){
        
        return(socio[msg.sender].name, socio[msg.sender].direccion_cartera, socio[msg.sender].capital_invertido, socio[msg.sender].acu_ganancias, socio[msg.sender].ultimo_retiro,  socio[msg.sender].bloqueCreacion);
    }
    
    function getPorcentajeParticipacion() external view SoloSocios returns(uint){
        uint256 porcentaje =  decimalsParticipacion * socio[msg.sender].capital_invertido  / inversionSocios;
        return porcentaje;
        
    }
    
    event Capital(uint256 c);

    //cuando un socio envía más capital aumenta su cuota de participación en la empresa
    function sendCapitalPorSocio() public SoloSocios payable returns (uint){
        
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
    
    //envio de ganancias de las actividades de la sociedad al acu_ganancias del contrato
    function sendProfits()public payable returns (bool _status){
    
        //repartir ganancias entre los socios según su Porcentaje de participación
        for (uint i=0; i< socios_array.length; i++) {
            //el calculo de % se hace en base a 1000% y no a 100% para resolver el problema de precisión por no tener float en solidity    
            uint256 porc_part = decimalsParticipacion * socio[socios_array[i]].capital_invertido  / inversionSocios;
            socio[socios_array[i]].acu_ganancias += (msg.value * porc_part ) / decimalsParticipacion;
        }
        
        calcularPriceStock();
        return true;
    }
    
    //para enviar fondos sin afectar los saldos 
    function sendFound(uint256 _amount)public payable{
        debitado -= _amount;
        require(_amount == msg.value);
    }
    
    
    event GananciasSociedad(uint256 _ganancias);
    event Porcentaje(uint256 _porcentaje);
    event Valor(uint256 _valor);
    
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
        require(socio[msg.sender].acu_ganancias >= monto);
        socio[msg.sender].acu_ganancias  -= monto;
        msg.sender.transfer(monto);
        return true;
    }
    
    function finContratoUnilateral()public payable SoloSocios returns(uint256 _total_acumulado, uint256 _porcentaje_penalizado, uint256 _total_penalizdo, uint256 _total_retirado){
        //finiquita el contrato enviando al socio su porcentaje del capital invertido + el acu_ganancias del momento menos el monto correspondiente a la penalización
        
        //calcular porcentaje de porcentaje_penalizacion_fin_unilateral
        uint256 acumulado = (socio[msg.sender].capital_invertido + socio[msg.sender].acu_ganancias);
        uint256 penal = (acumulado * porcentaje_penalizacion_fin_unilateral ) / 100;
        
        uint256 retirar = (acumulado - penal);
        
        inversionSocios -= socio[msg.sender].capital_invertido;// se resta el capital del socio del capital total, por lo que su participacion llega a 0
        socio[msg.sender].capital_invertido = 0;
        socio[msg.sender].acu_ganancias = 0;
        socio[msg.sender].porcentaje_participacion = 0;
        
        //el saldo penalizado se contabiliza aparte
        saldo_finiquitos += penal;
    
        msg.sender.transfer(retirar);
        
        return (acumulado, porcentaje_penalizacion_fin_unilateral, penal,  retirar);
    }
    
    function withDrawFondos(uint256 _monto)public payable SoloManager returns(bool _status){
        require(address(this).balance >= _monto);
        debitado += _monto;
        msg.sender.transfer(_monto);
        return true;
    }
    
}