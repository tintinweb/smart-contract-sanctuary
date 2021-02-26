/**
 *Submitted for verification at Etherscan.io on 2021-02-26
*/

pragma solidity 0.5.11;


contract Registro_Documentos
{

    
    mapping(bytes32 => address) vDocumentos;
    

    event NovoDocumento(bytes32 hashDocumento);
    
    event DocumentoExistente(bytes32 hashDocumento,address Emissor);

    address payable dono;



    modifier apenasDono {
        msg.sender == address(this);
    _;
    }
    

    function registrarDocumento (bytes32 hashDocumento) public  apenasDono payable {
        
        require(msg.value >= 0.0001 ether, "Valor insuficiente" );

        //require(!verificarDocumento(hashDocumento), "Documento já existe");

        
        if (!verificarDocumento(hashDocumento))
        {
            emit NovoDocumento(hashDocumento);
            vDocumentos[hashDocumento] = msg.sender;
        }
        else
        {
            emit DocumentoExistente(hashDocumento,vDocumentos[hashDocumento]);
        }

        
    }    
    
    function verificarDocumento (bytes32 hashDocumento) public  returns(bool) 
    {
        return vDocumentos[hashDocumento] != address(0);
    }

    function descobrirQuemRegistrou (bytes32 hashDocumento) public apenasDono payable returns (address) {
        require(msg.value >= 0.00001 ether, "Valor insuficiente");
        return vDocumentos[hashDocumento];
    }
    

    
}