pragma solidity ^0.4.25;

//Este contrato permite recibir fondos,
//asignar una direcci&#243;n que recibir&#225; esos fondos (heredero)
//cuando un or&#225;culo (un reloj que recibe las pulsaciones del owner)
//determine que esa persona falleci&#243;.

contract testamento{
    
    //Se declaran las variables globales
    address public heredero;
    address public owner;
    address public reloj;
   
   //En el constructor se asigna la direcci&#243;n del owner como quien lanza 
   //el contrato y la direcci&#243;n del dispositivo que sirve como or&#225;culo.
    constructor() public {
        owner = msg.sender;
        reloj = 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c;
    }
    
    //Esta funci&#243;n permite al owner designar quien va a heredar el contenido
    //de este contrato.
    function designarHeredero(address _heredero) public {
        heredero = _heredero;
    }
    
    //Esta funci&#243;n es la que le permite unicamente al owner ir ingresando fondos
    //en su legado.
    function ingresarFondos() payable public {
        require(msg.sender == owner, &#39;Esta persona no puede ingresar fondos.&#39;);
    }
    
    //Esta funci&#243;n es la que llama el or&#225;culo cuando deja de recibir los signos
    //vitales del owner
    function seMurio () public {
        require(msg.sender == reloj, &#39;Este no es el or&#225;culo&#39;);
        heredar();
    }
    
    //Esta funci&#243;n envia los fondos al heredero.
    function heredar () private {
        heredero.transfer(address(this).balance);
    }
    
    //Esta funci&#243;n permite al owner ver el balance del contrato.
    function getBalance () public view returns (uint256){
        require(msg.sender == owner, &#39;Esta persona no puede ver el balance&#39;);
        return (address(this).balance);
    }
}