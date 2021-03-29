/**
 *Submitted for verification at Etherscan.io on 2021-03-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */ 
 
contract CompraTickets {
    address payable owner;      //dueño de contrato
    uint256 public precio = 0;  //precio en finney (1 ether/10000
    uint256 public cantidad = 0;
    string public descripcion;
    string public website;
    
    uint256 public iValorRecv = 0;
    
    mapping(address => uint) public purcharsers;
    mapping(string => uint256) public sub_monedas;
    address[] arrCompradores;
    
    constructor(uint256 _precio, uint256 _cantidad, string memory _descripcion, string memory _website){
        
        CargaSubMonedas();
        owner = msg.sender;
        //precio = _precio * sub_monedas['finney'];
        precio = _precio;
        cantidad = _cantidad;
        descripcion = _descripcion;
        website = _website;
    }
    
    
     function GeneraNuevaCompraTicket(uint _cantidad, uint _precio, string memory _descripcion, string memory _website)  public{
        if (msg.sender != address(owner)){
            return;
        }
        //------------------
        LimpiaPurcharsers();
        //------------------
        descripcion = _descripcion;
        website = _website;
        cantidad = _cantidad;
        //precio = _precio * sub_monedas['finney'];
        precio = _precio;
    }
    
    
    function EditPrice(uint _nuevo_precio) public returns(string memory){
        if (msg.sender != address(owner)){
            return 'no tiene permiso para cambiar este valor';
        }
        precio = _nuevo_precio; // * sub_monedas['finney'];
        return 'precio actualizado';
    }
    
    
     function ComprarTickets(uint _cantidad_compra) payable external{
       if(msg.value != (_cantidad_compra * precio) || _cantidad_compra >cantidad){
            revert();
        }else{
            purcharsers[msg.sender] += _cantidad_compra;
            arrCompradores.push(msg.sender); //guardamos el address del comprador
            cantidad -= _cantidad_compra;
            
            if(cantidad==0){
                owner.transfer(address(this).balance);
            }
        }
        
        
    }
    
    
    function refund(uint _cantidad_devueltas) public{
        if(purcharsers[msg.sender] < _cantidad_devueltas){
            revert();
        }else{
            msg.sender.transfer(_cantidad_devueltas * precio);
            purcharsers[msg.sender] -= _cantidad_devueltas;
            cantidad += _cantidad_devueltas;
        }
    }
    
    
    
    function  LimpiaPurcharsers() private{
        uint i = 0;
        for(i= 0;i < arrCompradores.length;i++){
            purcharsers[arrCompradores[i]] = 0;
        }
    }
    
    
    function CargaSubMonedas() private {
        sub_monedas['wei']         = 1;
        sub_monedas['kwei']        = 1000;
        sub_monedas['ada']         = 1000;
        sub_monedas['femtoether']  = 1000;
        sub_monedas['mwei']        = 1000000;
        sub_monedas['babbage']     = 1000000;
        sub_monedas['picoether']   = 1000000;
        sub_monedas['gwei']        = 1000000000;
        sub_monedas['shannon']     = 1000000000;
        sub_monedas['nanoether']   = 1000000000;
        sub_monedas['nano']        = 1000000000;
        sub_monedas['szabo']       = 1000000000000;
        sub_monedas['microether']  = 1000000000000;
        sub_monedas['micro']       = 1000000000000;
        sub_monedas['finney']      = 1000000000000000;
        sub_monedas['milliether']  = 1000000000000000;
        sub_monedas['milli']       = 1000000000000000;
        sub_monedas['ether']       = 1000000000000000000;
        sub_monedas['kether']      = 1000000000000000000000;
        sub_monedas['grand']       = 1000000000000000000000;
        sub_monedas['einstein']    = 1000000000000000000000;
        sub_monedas['mether']      = 1000000000000000000000000;
        sub_monedas['gether']      = 1000000000000000000000000000;
        sub_monedas['tether']      = 1000000000000000000000000000000;
   }
   
}