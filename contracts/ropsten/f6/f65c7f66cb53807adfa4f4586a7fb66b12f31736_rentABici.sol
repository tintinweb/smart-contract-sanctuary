pragma solidity ^0.4.25;

// El siguiente contrato permite el alquiler de una bicicleta.
// El valor del mismo es de 0.01 eth la hora.
// Se cobrar&#225;n a modo de dep&#243;sito 0.1 eth y cuando se produzca
// la devoluci&#243;n se devolver&#225; el monto restante.
// La devoluci&#243;n del rodado se verificar&#225; digitalmente mediante 
// un or&#225;clulo determinado por sistema de anclaje ubicado en la v&#237;a p&#250;blica
// que se comunicar&#225; con el contrato cuando la bicicleta se encuentre anclada.

contract rentABici{
    
    address public owner;
    bool public disponible = true;
    address public cliente;
    uint public fechaYHoraAlquiler;
    uint public fechaYHoraDevolucion;
    uint public precioPorHora = 0.01 ether;
    uint public seguro;
    address public oracle;
    
    // Se determina como due&#241;o al que ejecuta el contrato y se asigna la address
    // del or&#225;culo.
    constructor () public{
        owner = msg.sender;
        oracle = 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c;
        
    }
    // La funci&#243;n AlquilarBici determina el monto del dep&#243;sito, valida la 
    // disponibilidad del rodado, registra el horario de inicio del alquiler,
    // asigna como cliente a la address que llama a la funci&#243;n y cambia el
    // estado de la disponibilidad de la bicicleta.
    function AlquilarBici () public payable {
        	require (msg.value == 0.1 ether,
        	"Se deber&#225; abonar como dep&#243;sito 0.1 ether, una vez devuelta la bicicleta se cobrar&#225; el servicio sobre este monto y el resto ser&#225; devuelto a su cuenta");
        	require (disponible == true, "La bicicleta no est&#225; disponible");
        	fechaYHoraAlquiler = block.timestamp;
        	cliente = msg.sender;
        	disponible = false;
        	
    }
    
    // La funci&#243;n BiciDevuelta puede ser llamada s&#243;lo por el oraculo,
    // registra el horario de devoluci&#243;n y llama a la funci&#243;n devolverBici.
    function BiciDevuelta () public {
        require(msg.sender == oracle, &#39;Este no es el or&#225;culo&#39;);
        fechaYHoraDevolucion = block.timestamp;
        
        devolverBici();
    }
    
    // La funci&#243;n devolverBici calcula el tiempo de alquiler, el precio del
    // mismo, devuelve el monto restante al cliente, env&#237;a la tarifa del servicio
    // al due&#241;o y vuelve a asignar a la bicicleta como disponible.
    function devolverBici () private {
        uint tiempo = (fechaYHoraDevolucion - fechaYHoraAlquiler) /60 /60;
        uint tarifa = tiempo * precioPorHora;
        cliente.transfer(address(this).balance - tarifa);
        owner.transfer (address(this).balance);
        disponible = true;
        cliente = owner;
        
    }
    
}