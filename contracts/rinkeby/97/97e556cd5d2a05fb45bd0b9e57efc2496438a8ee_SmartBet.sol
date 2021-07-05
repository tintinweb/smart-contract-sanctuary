/**
 *Submitted for verification at Etherscan.io on 2021-07-04
*/

// SPDX-License-Identifier: MIT

/* Trabajo final Curso Blockchain UP Julio 2021 
   "SmartBet" - Apuestas deportivas
*/


/*Nota: Desde la versión 0.8 en adelante, cuando se producen overflows o underflows 
  se realiza un revert por defecto, por lo que no es necesario utilizar SafeMath.*/

pragma solidity ^0.8.0;


contract SmartBet {
    
    address owner;
    mapping(uint32 => Evento) eventos;
    uint fondos; // Dado que no hay que fiarse de payable(this).balance, llevo el total acá
    
    constructor(address _owner)
    {
        owner = _owner;
    }

    
    //El owner puede destruir el contrato cuando quiera siempre que no haya fondos reclamables
    function destruir(address payable _destino) external isOwner {
        require(fondos == 0);
        selfdestruct(_destino);
    }

    /************************Structs****************************************/
    //Optimizo los slots usando uints de 32 bits cuando se puede y declarandolos en el orden adecuado
    
    struct Evento {
        
        uint32 Id;
        uint32 totalApuestas;
        bool inactivo;
        bool ganadoresInformados;
        address oraculoAutorizado;
        mapping(uint32 => Competidor) competidores;
        uint totalMontoApostado;
        uint totalMontoGanadores;
        uint fechaInicioEvento;
        uint fechaEstimadaFinEvento;
    }
    
    struct Competidor {
        
        uint32 Id;
        uint32 cantApuestas;
        bool ganador;
        bool activo;
        mapping(address => uint) apuestas;
        uint totalApostado;
    }
    
    
    /*****************Métodos de la dinámica del negocio*********************/
    event  ganadorInformado(uint32 _idEvento);
    
    //Si hay un único competidor ganador usar esta función, ya que evita loops (ver función informarGanadores)
    //Valido que el evento y el competidor existen y están activos, que el evento haya pasado, y que el sender sea el oráculo
    function informarGanador(uint32 _idEvento, uint32 _idCompetidorGanador) external {
        require(existeCompetidorActivo(_idEvento, _idCompetidorGanador) && 
         (block.timestamp > eventos[_idEvento].fechaEstimadaFinEvento) && eventos[_idEvento].oraculoAutorizado == msg.sender
        );
        
        
        eventos[_idEvento].competidores[_idCompetidorGanador].ganador = true;
        eventos[_idEvento].inactivo = true;
        eventos[_idEvento].ganadoresInformados = true;
        eventos[_idEvento].totalMontoGanadores = eventos[_idEvento].competidores[_idCompetidorGanador].totalApostado;
        emit ganadorInformado(_idEvento);
       
    }
    
    //Si hay más de un competidor ganador (ej. en un empate) debe usarse esta función que consume más gas
    function informarGanadores(uint32 _idEvento, uint32[] memory _idCompetidoresGanadores)  external {
        require(existeEventoActivo(_idEvento) && (block.timestamp > eventos[_idEvento].fechaEstimadaFinEvento) 
        && eventos[_idEvento].oraculoAutorizado == msg.sender);
        
         for(uint8 i=0;i<_idCompetidoresGanadores.length;i++)
             //Si algun Id no existe invalido todo
             if(existeCompetidorActivo(_idEvento, _idCompetidoresGanadores[i]))
             {
                eventos[_idEvento].competidores[_idCompetidoresGanadores[i]].ganador = true;
                eventos[_idEvento].totalMontoGanadores += eventos[_idEvento].competidores[_idCompetidoresGanadores[i]].totalApostado;
             }
             else
                revert();
         
         
         eventos[_idEvento].inactivo = true;
         eventos[_idEvento].ganadoresInformados = true;
         emit ganadorInformado(_idEvento);
    }
    
    //Valido que el evento aún no haya comenzado - Se permiten apuestas hasta 1 hora antes asi no hay problema 
    // con inexactitudes en el timestamp del bloque
    function apostar(uint32 _idEvento, uint32 _idCompetidor) external payable{
         require(existeCompetidorActivo(_idEvento, _idCompetidor) && msg.value > 0
         &&  eventos[_idEvento].fechaInicioEvento > (block.timestamp + 60*60));
         
         if(eventos[_idEvento].competidores[_idCompetidor].apuestas[msg.sender] == 0)
         {
            eventos[_idEvento].competidores[_idCompetidor].cantApuestas++;
            eventos[_idEvento].totalApuestas++;
         }
         
         eventos[_idEvento].competidores[_idCompetidor].apuestas[msg.sender] += msg.value;
         eventos[_idEvento].competidores[_idCompetidor].totalApostado += msg.value;
         eventos[_idEvento].totalMontoApostado += msg.value;
         
         //Actualizo fondos del contrato
         fondos+= msg.value;
         
    }
    
    
    function reclamarPago(uint32 _idEvento, uint32 _idCompetidor, address payable _dirPago) public
    {
        /*Puede reclamar los fondos si tiene fondos en un evento y competidor existente y alguna de las siguientes:
           1) El evento fue cancelado
           2) El competidor fue dado de baja (Cláusula "fair Play")
           3) Pasaron 48 hs de la finalización del evento y el oráculo no informó los ganadores
           4) Ganó la apuesta (El oráculo informó previamente)
        */   

        require(
            //Valido que el evento, el competidor, y los fondos reclamados existan
            eventos[_idEvento].competidores[_idCompetidor].apuestas[msg.sender]!= 0 &&
            (
                // 1) El evento fue cancelado
                (eventos[_idEvento].inactivo && !eventos[_idEvento].ganadoresInformados) ||
                
                // 2) El competidor fue dado de baja (Cláusula "fair Play")
                (!eventos[_idEvento].competidores[_idCompetidor].activo) ||
                
                // 3) Pasaron 48 hs de la finalización del evento y el oráculo no informó los ganadores
                (!eventos[_idEvento].inactivo && block.timestamp > eventos[_idEvento].fechaEstimadaFinEvento + 60*60*48) ||
                
                // 4) Ganó la apuesta (El oráculo informó previamente)
                (eventos[_idEvento].competidores[_idCompetidor].ganador)
                
            )
        );
        
        
        //Antes de seguir, prevengo reentrancy attacks debitando los fondos del storage
        uint _fondosAPagar = eventos[_idEvento].competidores[_idCompetidor].apuestas[msg.sender];
        eventos[_idEvento].competidores[_idCompetidor].apuestas[msg.sender] = 0;
        
        //Recalculo monto a pagar si es ganador
        if(eventos[_idEvento].competidores[_idCompetidor].ganador)
        {
            //Monto a pagar = % de lo apostado sobre las apuestas ganadoras * Bolsa total
            //Al ser operaciones entre enteros el resultado se redondeará a un entero. De todos modos los decimales
            // en caso de existir representarían montos extremadamente bajos.
           _fondosAPagar = (_fondosAPagar/ eventos[_idEvento].totalMontoGanadores)*eventos[_idEvento].totalMontoApostado;
        }
        
        //Actualizo balance del contrato
        fondos-= _fondosAPagar;
        
        _dirPago.transfer(_fondosAPagar);
        
    }
    
  
    
    /*****************Métodos de gestión*******************************/
    
    function crearEvento(uint32 _IdEvento, uint _fechaInicioEvento, uint _fechaEstimadaFinEvento, address _oraculoAutorizado) public isOwner {
        //Por transparencia exijo que el oráculo sea distinto al owner, valido que la fecha de comienzo del evento sea al menos dentro de 24 hs.
        // y que la finalización sea posterior al inicio. También valido que la duración del evento no pueda ser mayor a 30 días
        require(!existeEvento(_IdEvento) && _oraculoAutorizado!= owner 
            && _fechaInicioEvento > (block.timestamp + 60*60*24) && _fechaEstimadaFinEvento - _fechaInicioEvento < 60*60*24*30 );
        
         
        eventos[_IdEvento].Id = _IdEvento;
        eventos[_IdEvento].fechaInicioEvento = _fechaInicioEvento;
        eventos[_IdEvento].fechaEstimadaFinEvento = _fechaEstimadaFinEvento;
        eventos[_IdEvento].oraculoAutorizado =  _oraculoAutorizado;
        
        
        //Nota: Si bien el minero del bloque puede alterar un poco el timestamp, no afecta para nada la seguridad y funcionalidad del contrato
    }
    

    function agregarCompetidor(uint32 _IdEvento, uint32 _IdNuevoCompetidor)  public isOwner {
        require(existeEventoActivo(_IdEvento) && !existeCompetidorActivo(_IdEvento, _IdNuevoCompetidor));
        
        eventos[_IdEvento].competidores[_IdNuevoCompetidor].Id = _IdNuevoCompetidor;
        eventos[_IdEvento].competidores[_IdNuevoCompetidor].activo = true;
    }
    
    
    //Se ofrece este método, si no se desea agregar los competidores de a 1 a la vez.
    //El usuario del contrato decidirá que le resulta más conveniente en función del consumo de gas.
    function agregarCompetidores(uint32 _IdEvento, uint32[] memory _IdsNuevosCompetidores)   public isOwner {
         
         for(uint16 i=0;i<_IdsNuevosCompetidores.length;i++) 
             agregarCompetidor(_IdEvento,_IdsNuevosCompetidores[i]);
        
    }
    
    //Cláusula Fair Play: Si un competidor no participa de la competencia, se devuelve los fondos a los que apostaron por el mismo.
    //Para evitar loops, en lugar de devolver todos los fondos, solo disparo un evento para avisar que los fondos pueden ser retirados
    // Si el oráculo ya informó ganadores, el evento deportivo aparecerá inactivo y no se podrá desactivar al competidor
    event  competidorDesactivado(uint32 _idEvento, uint32 _idCompetidor);
    function desactivarCompetidor(uint32 _idEvento, uint32 _idCompetidor) public isOwner {
        require(existeCompetidorActivo(_idEvento, _idCompetidor));
        
        //Quito los fondos correspondientes al evento
        eventos[_idEvento].totalApuestas -= eventos[_idEvento].competidores[_idCompetidor].cantApuestas;
        eventos[_idEvento].totalMontoApostado -= eventos[_idEvento].competidores[_idCompetidor].totalApostado;
        
        eventos[_idEvento].competidores[_idCompetidor].activo = false;
        emit competidorDesactivado(_idEvento, _idCompetidor);
        
        
    }
    
    
    //Para evitar loops, en lugar de devolver todos los fondos, solo disparo un evento para avisar que los fondos pueden ser retirados.
    // Si el oráculo ya informó ganadores, el evento aparecerá inactivo y no se podrá cancelar
    event  eventoCancelado (uint32 _idEvento);
    function cancelarEvento(uint32 _idEvento) public isOwner {
        require(existeEventoActivo(_idEvento));
        
        eventos[_idEvento].inactivo = true;
        emit eventoCancelado(_idEvento);
    }
    
    
    /*****************Métodos de consulta*****************************/
    
    //Si el evento existe y está activo devuelve su fecha de inicio, su fecha de finalización, el oráculo autorizado,el total de apuestas,
    //y el monto total apostado.
    function verEvento(uint32 _idEvento)  public view returns(uint,uint,address,uint32,uint) {
        require(existeEventoActivo(_idEvento));
        
        return (eventos[_idEvento].fechaInicioEvento,eventos[_idEvento].fechaEstimadaFinEvento,
        eventos[_idEvento].oraculoAutorizado,eventos[_idEvento].totalApuestas, eventos[_idEvento].totalMontoApostado);
    }
    
    
    //Si el evento y el competidor existen y están activos devuelve el total apostado, la cant. total de apuestas para ese competidor,
    // y el monto total apostado en el evento.
    function verCompetidor(uint32 _idEvento, uint32 _idCompetidor) public view returns(uint,uint32,uint) {
        require(existeCompetidorActivo(_idEvento,_idCompetidor));
          
        return(eventos[_idEvento].competidores[_idCompetidor].totalApostado, 
        eventos[_idEvento].competidores[_idCompetidor].cantApuestas,
         eventos[_idEvento].totalMontoApostado);
        
    }
    
    
    //Devuelve el monto apostado por una dirección, para un competidor específico
    function verApuesta(uint32 _idEvento, uint32 _idCompetidor, address _apostador) public view returns(uint)
    {
        require(existeCompetidorActivo(_idEvento,_idCompetidor));
        
        //Si el apostador no existe devolverá 0 por defecto del mapping.
        return eventos[_idEvento].competidores[_idCompetidor].apuestas[_apostador];
    }
    
    
    //Sobrecarga del método anterior: Devuelve la apuesta con el address del sender.
    function verApuesta(uint32 _idEvento, uint32 _idCompetidor) public view returns(uint) {
        
        return verApuesta(_idEvento,_idCompetidor,msg.sender);
    }
    
     /******************Utilidades*************************************/
      
     modifier isOwner {
        require(msg.sender == owner, "Solo el Owner puede llamar a esta funcion");
        _;
     }
      
     function existeEventoActivo(uint32 _idEvento) private view returns(bool) {
          return eventos[_idEvento].Id != 0 && !eventos[_idEvento].inactivo;
     }
     
       function existeEvento(uint32 _idEvento) private view returns(bool) {
          return eventos[_idEvento].Id != 0;
     }
     
     
     function existeCompetidorActivo(uint32 _idEvento, uint32 _idCompetidor) private view returns(bool){
         require(existeEventoActivo(_idEvento));
         
         return eventos[_idEvento].competidores[_idCompetidor].Id != 0 &&
                eventos[_idEvento].competidores[_idCompetidor].activo;
     }
     
}