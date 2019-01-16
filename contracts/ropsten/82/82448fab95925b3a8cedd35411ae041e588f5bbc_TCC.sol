pragma solidity ^0.4.22;

contract TCC {
     string public retorno;
     
     constructor() public{
        retorno = "Aluno nota 10.";
     }
     
      function query() public view returns(string a){
         return retorno;
     }
     
}