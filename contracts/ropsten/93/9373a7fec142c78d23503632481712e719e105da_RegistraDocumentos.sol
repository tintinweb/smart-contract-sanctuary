/**
 *Submitted for verification at Etherscan.io on 2021-09-02
*/

pragma solidity 0.8.2;

contract RegistraDocumentos {

    mapping (bytes32 => address) documentos;
    uint256 public arrecadacao;
    modifier incrementarArrecadacao {
        arrecadacao += msg.value;
        _;
    }

    event NovoDocumento (bytes32 _hashDocumento, address _requisitor);
    event DocumentoExistente (bytes32 _hashDocumento, address _requisitor);

    function registrarDocumento (bytes32 hashDocumento) public incrementarArrecadacao payable {
        require(msg.value >= 0.001 ether, "Abortada: falta de saldo");
        if (documentos[hashDocumento] != address(0)) {
            emit DocumentoExistente (hashDocumento, msg.sender);
        }
        else {
            documentos[hashDocumento] = msg.sender;
            emit NovoDocumento (hashDocumento, msg.sender);
        }
    }

    function verificarDocumento (bytes32 hashDocumento) public view returns (bool) {
        return documentos[hashDocumento] != address(0);
    }
}