/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract CompraVentaCoches{
    uint valor_inicial;
    uint resta;
    uint year;
    uint km;
    bool estado;  // true: bien, false: mal
    bool itv;  // true: tiene pasada la itv
    
    uint precio_compra;
    uint precio_venta;
    
    string modelo = new string(2);
    string texto = "Actualmente tenemos en nuestra base de datos estos modelos de Audi disponibles: A1, A3, A4, A5, A6, A7, A8; Q2, Q3, Q4, Q5, Q7, Q8; ET, ETGT; R8; TT";  // Para poder ver que modelos estan disponibles para tasar
    
    event Precios(string, uint, string, uint);
    
    function CochesDisponibles() public view returns(string memory){
        return texto;
    }
    
    function precioCoche (string memory _modelo, uint _year, uint _km, bool _estado, bool _itv) public {
        modelo = _modelo;
        year = _year;
        km = _km;
        estado = _estado;
        itv = _itv;
        
        require(year < 10, "Solo trabajamos con coches de hasta 10 years de antiguedad");
        require(km < 200000, "Solo trabajamos con coches de hasta 200000km");
        
        valor_inicial = 0;
        
        bytes32 bymodelo = keccak256(bytes(modelo));
        
        
        if (bymodelo == keccak256(bytes("A1"))) valor_inicial = 23000  * (0.00045 * 10**18);  // precio de cada vehiculo en weis
        if (bymodelo == keccak256(bytes("A3"))) valor_inicial = 30000  * (0.00045 * 10**18);
        if (bymodelo == keccak256(bytes("A4"))) valor_inicial = 44000  * (0.00045 * 10**18);
        if (bymodelo == keccak256(bytes("A5"))) valor_inicial = 47000  * (0.00045 * 10**18);
        if (bymodelo == keccak256(bytes("A6"))) valor_inicial = 63000  * (0.00045 * 10**18);
        if (bymodelo == keccak256(bytes("A7"))) valor_inicial = 75000  * (0.00045 * 10**18);
        if (bymodelo == keccak256(bytes("A8"))) valor_inicial = 105000 * (0.00045 * 10**18);
        
        if (bymodelo == keccak256(bytes("Q2"))) valor_inicial = 30000  * (0.00045 * 10**18);
        if (bymodelo == keccak256(bytes("Q3"))) valor_inicial = 38000  * (0.00045 * 10**18);
        if (bymodelo == keccak256(bytes("Q4"))) valor_inicial = 50000  * (0.00045 * 10**18);
        if (bymodelo == keccak256(bytes("Q5"))) valor_inicial = 57000  * (0.00045 * 10**18);
        if (bymodelo == keccak256(bytes("Q7"))) valor_inicial = 85000  * (0.00045 * 10**18);
        if (bymodelo == keccak256(bytes("Q8"))) valor_inicial = 90000  * (0.00045 * 10**18);
        
        if (bymodelo == keccak256(bytes("ET"))) valor_inicial = 80000  * (0.00045 * 10**18);
        if (bymodelo == keccak256(bytes("ETGT"))) valor_inicial = 105000 * (0.00045 * 10**18);
        
        if (bymodelo == keccak256(bytes("R8"))) valor_inicial = 200000 * (0.00045 * 10**18);
        if (bymodelo == keccak256(bytes("TT"))) valor_inicial = 50000  * (0.00045 * 10**18);
        
        require(valor_inicial != 0, "Modelo incorrecto");
        
        resta = valor_inicial * year * 75 / 10000;
        
        if (km < 1000) {
            resta += valor_inicial * 25 / 1000;
        }
        else{
            if (km < 50000) {
                resta += valor_inicial * 9 / 100;
            }
            else {
                if (km < 100000) {
                    resta += valor_inicial * 135 / 1000;
                }
                else{  // 100000 < km < 200000
                    resta += valor_inicial * 185 / 1000;
                }
            }
        }
        
        if (! estado) resta += valor_inicial * 2 / 10;
        
        if(! itv) resta += 200 * (0.00045 * 10**18);
        
        precio_venta = valor_inicial - resta;
        precio_compra = precio_venta * 75 / 100;
        
        emit Precios("Precio de compra en weis: ", precio_compra, "Precio de venta en weis: ", precio_venta);
    }
}