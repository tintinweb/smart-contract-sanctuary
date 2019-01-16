pragma solidity ^0.4.25;

contract AssinaturaDigital {
    // The owner of the contract
    address proprietario = msg.sender;
    // Name of the institution (for reference purposes only)
    string public empresa;
    // Storage for linking the signatures to the digital fingerprints
	mapping (bytes32 => string) arquivosAssinados;
    // Event functionality
	event AssinaturaAdicionada(string indexed hashArquivo, string indexed assinatura, uint256 datahora);
    // Modifier restricting only the owner of this contract to perform certain operations
    modifier ehProprietario() { require(msg.sender == proprietario); _;}
    
    constructor(string _empresa) public {
        empresa = _empresa;
    }
    
    // Adds a new signature and links it to its corresponding digital fingerprint
	function adicionarAssinatura(string hashArquivo, string assinatura) public ehProprietario {
        arquivosAssinados[keccak256(abi.encodePacked(hashArquivo))] = assinatura;
        emit AssinaturaAdicionada(hashArquivo, assinatura, now);
	}

    // Removes a signature from this contract
	function removerAssinatura(string hashArquivo) public ehProprietario {
        arquivosAssinados[keccak256(abi.encodePacked(hashArquivo))] = "";
	}

    // Returns the corresponding signature for a specified digital fingerprint
	function buscarAssinatura(string hashArquivo) public constant returns(string){
		return arquivosAssinados[keccak256(abi.encodePacked(hashArquivo))];
	}

    // Removes the entire contract from the blockchain and invalidates all signatures
    function removeSdaContract() public ehProprietario {
        selfdestruct(proprietario);
    }
}