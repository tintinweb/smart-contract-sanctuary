/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

contract proyecto{
    string nomCont;
      string nomEmpleado;
    uint256 saldo;
    address director;
      address contador;
      address empleado;
constructor() {
    director=msg.sender;
contador=msg.sender;
empleado=msg.sender;
    
}
modifier soloDirector{
    require(msg.sender == director);
    _;
}
modifier soloContador{
    require(msg.sender == contador);
    _;
}

function nuevoEmpleado(address _newemp)public soloContador{
    empleado=_newemp;

}
function getEmpleado()view public returns(address){
    return empleado;
    
}


function nuevoContador(address _newcont)public soloDirector{
    contador=_newcont;

}
function getContador()view public returns(address){
    return contador;
    
}






function getDirector()view public returns(address){
    return director;
    
}


 function Nombre_Cont(string calldata _nomCont)public soloDirector{
        nomCont=_nomCont;
        
    }
    function ver_Nombre_Contador()public view returns(string memory){
        return nomCont;
    }
    
    function Nombre_Empleado(string calldata _nomEmpleado)public soloContador{
        nomEmpleado=_nomEmpleado;
        
    }
    function ver_Nombre_Empleado()public view returns(string memory){
        return nomEmpleado;
    }
    
   function withdrawBalance()public soloDirector{
    msg.sender.transfer(address(this).balance);
    
}

function incrementarBalance(uint256 cantidad)payable public soloContador{
    require(msg.value == cantidad);
}
  function Sueldo_Empleado(uint256 _saldo) public soloContador{
         saldo = _saldo;
          }
  function getSaldoEmpleado()view public  returns(uint256) {
    return saldo;
}
function getBalance() view public returns(uint256){
    return address(this).balance-saldo;
    
}


 

}