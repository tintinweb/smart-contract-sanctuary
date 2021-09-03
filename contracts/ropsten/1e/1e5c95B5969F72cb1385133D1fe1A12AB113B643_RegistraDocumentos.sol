/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity 0.8.1;

contract RegistraDocumentos {
    
    mapping (bytes32 => address) documentos;
    uint256 public arrecadacao;
    
    event NovoDocumento (bytes32 _hashDocumento, address _requisitor);
    event DocumentoExistente (bytes32 _hashDocumento, address _requisitor);
    
    function registrarDocumento (bytes32 hashDocumento) public payable {
        require(msg.value >= 0.001 ether, "Transacao abortada por falta de saldo");
        documentos[hashDocumento] = msg.sender;
        arrecadacao += msg.value;
    }
    
    function verificarDocumento (bytes32 hashDocumento) public view returns (bool) {
        return documentos[hashDocumento] != address(0);
    }
}