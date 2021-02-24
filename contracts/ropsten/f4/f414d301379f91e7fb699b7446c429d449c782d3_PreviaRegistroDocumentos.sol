/**
 *Submitted for verification at Etherscan.io on 2021-02-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

contract PreviaRegistroDocumentos {
 
	 mapping(bytes32 => address) documentos;
	 uint256 public arrecadacao;
	 address payable dono;

    constructor () {
        dono = msg.sender;
        documentos[0x9aed541153e3f39cc0b4cfd1d2b1b1d2c99f660742055147505e7e8f5ef08070] = msg.sender;        
    }

	 modifier apenasDono {
		require(msg.sender == dono, "Apenas o dono!");
		_;
	 }
	 
	 modifier incrementarArrecadacao {
		arrecadacao += msg.value;
	 _;
	 }
	 
	 event NovoDocumento(bytes32 hashDocumento, address disparador);
	 event DocumentoExistente(bytes32 hashDocumento, address disparador);
	 
	 function registrarDocumento (bytes32 hashDocumento) public incrementarArrecadacao payable {
	    // *** ALTERADO para wei para evitar gastar Ether em homologação ***
		require(msg.value >= 1 wei, "Valor insuficiente");
		//******************************************************************
		if (documentos[hashDocumento] != address(0)) {
		    emit DocumentoExistente(hashDocumento, msg.sender);   
		} else {
		    emit NovoDocumento(hashDocumento, msg.sender);
		    documentos[hashDocumento] = msg.sender;
		}
	 }
	 
	 function verificarDocumento (bytes32 hashDocumento) public view returns (bool) {
		return documentos[hashDocumento] != address(0);
	 }
	 
}