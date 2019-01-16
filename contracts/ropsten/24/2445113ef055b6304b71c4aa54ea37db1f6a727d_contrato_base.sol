pragma solidity >=0.4.22 <0.6.0;
contract contrato_base {
    bool estado;
    mapping(address => uint) map_recivers;
    address[] arr_recivers;
    address owner;

    function envio_dinero () payable returns(string){
        require (estado == true,"El contrato no est&#225; en producci&#243;n");
        //Leo el array y consulto el porcentaje del mapping. Env&#237;o dinero.
        return "OK";
    }
    
    function set_owner (address _owner) returns(string){
        require (estado==false, "El contrato est&#225; bloqueado. &#39;En producci&#243;n&#39;");
        require (owner == 0 || owner==msg.sender,"Ya existe un owner seleccionado");
        owner = _owner;
        return "Se asign&#243; el owner _owner al contrato";
    }
    function set_recivers (address _recivers,uint _porcentaje) returns(string){
        require (estado==false, "El contrato est&#225; bloqueado. &#39;En producci&#243;n&#39;");
        require (owner==msg.sender, "Solo el owner puede configurar el contrato");
        //require (llama a funcion para validar porcentaje);
        map_recivers[_recivers]=_porcentaje;
    }
    function bloquear_contrato() returns (string){
        estado=true;
    }

}