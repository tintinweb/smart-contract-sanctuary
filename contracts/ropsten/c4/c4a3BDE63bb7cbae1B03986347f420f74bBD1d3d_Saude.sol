/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

pragma solidity 0.8.2;

contract Saude {

    mapping (bytes32 => address) diagnosticos;
    
    address[] public permitidos;
    
    address owner;
    
    event NovoDiagnostico (bytes32 _hashDiagnostico, address _requisitor);
    event DiagnosticoExistente (bytes32 _hashDiagnostico, address _requisitor);
    
    constructor(address[] memory enderecos) {
        owner = msg.sender;
        permitidos = enderecos;
    }

    function registrarDiagnostico(bytes32 hashDiagnostico) public {
        require(validador(msg.sender), "Permissao necessaria");
        if (diagnosticos[hashDiagnostico] != address(0)) {
            emit DiagnosticoExistente(hashDiagnostico, msg.sender);
        }
        else {
            diagnosticos[hashDiagnostico] = msg.sender;
            emit NovoDiagnostico(hashDiagnostico, msg.sender);
        }
    }

    function verificarDiagnostico(bytes32 hashDiagnostico) public view returns (bool) {
        return diagnosticos[hashDiagnostico] != address(0);
    }

    function validador(address endereco) public view returns(bool) {
        for(uint i = 0; i < permitidos.length; i++) {
          if(permitidos[i] == endereco) return true;
        }
        return false;
  }
}