/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

pragma solidity 0.5.11;

contract RegistroDocumentos {

    struct Register {
        address owner;
        bytes32 documentHash;
    }
    
    Register[] public registers;
    
    event NovoDocumento(bytes32 documentHash, address owner);
    
    event DocumentoExistente(bytes32 documentHash, address owner);
    
    function registrarDocumento(bytes32 documentHash) public payable {
        require(msg.value >= 0.001 ether, "Saldo insuficiente!");
        
        
        if(existsDocumentHash(documentHash)) {
            emit DocumentoExistente(documentHash, msg.sender);

        }else {
            registers.push(Register({
                owner: msg.sender,
                documentHash: documentHash
            }));
            
            emit NovoDocumento(documentHash, msg.sender);
        }
    }
    
    function verificarDocumento(bytes32 documentHash) public view returns(bool){
        return getOwner(documentHash) != address(0);
        
    }
    
    function getOwner(bytes32 documentHash) private view returns(address) {
        for (uint reg = 0; reg < registers.length; reg++) {
            if (registers[reg].documentHash == documentHash) {
                return registers[reg].owner;
            }
        }   
    }
    
    function existsDocumentHash(bytes32 documentHash) private view returns(bool) {
        for (uint reg = 0; reg < registers.length; reg++) {
            if (registers[reg].documentHash == documentHash) {
                return true;
            }
        }
        
        return false;
    }
    
}