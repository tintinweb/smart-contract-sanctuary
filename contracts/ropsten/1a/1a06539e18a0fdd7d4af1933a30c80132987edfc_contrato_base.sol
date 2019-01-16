pragma solidity 0.4.25;
contract contrato_base {
    bool estado;
    mapping(address => uint) map_recivers;
    address[] arr_recivers;
    address owner;
    uint porcentaje_total;
    
    function set_owner (address _owner) returns(string){
        require (estado==false, "El contrato est&#225; bloqueado. &#39;En producci&#243;n&#39;");
        require (owner == 0 || owner==msg.sender,"Ya existe un owner seleccionado");
        owner = _owner;
        return "Se asign&#243; el owner _owner al contrato";
    }
    function set_recivers (address _recivers,uint _porcentaje) returns(string){
        require (estado==false, "El contrato est&#225; bloqueado. &#39;En producci&#243;n&#39;");
        require (owner==msg.sender, "Solo el owner puede configurar el contrato");
        require (porcentaje_total+_porcentaje<=100,"Porcentaje total superado");
        porcentaje_total=porcentaje_total+_porcentaje;
        arr_recivers.push(_recivers);
        map_recivers[_recivers]=_porcentaje;
        return "Se carg&#243; el receptor correctamente";
    }
    function bloquear_contrato() returns (string){
        estado=true;
        return "Contrato listo para operar.";
    }

    function envio_dinero (uint _monto) payable returns(string){
        require (estado == true,"El contrato no est&#225; en producci&#243;n");
        //Leo el array y consulto el porcentaje del mapping. Env&#237;o dinero.
        for (uint i=0; i<arr_recivers.length; i++) {
          arr_recivers[i].transfer(_monto*(map_recivers[arr_recivers[0]]/100));
        }
        return "OK";
    }
    
    function view_state() view returns (string){
        if (estado== false){
                return "El contrato est&#225; en etapa de configuracion";
            } else {
                return "El contrato est&#225; en etapa de utilizaci&#243;n. Nadie puede modificar los recivers ni sus porcentajes";
            }
    }
    function view_owner() view returns (address){
            return owner;
    } 
}