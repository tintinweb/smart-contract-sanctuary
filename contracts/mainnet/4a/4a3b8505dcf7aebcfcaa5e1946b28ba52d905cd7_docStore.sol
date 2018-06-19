pragma solidity ^0.4.13;

contract Owned {
    address public owner;
    
    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    function Owned() public {
        owner = msg.sender;
    }

    function isOwner(address addr) view public returns(bool) {
        return addr == owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(this)) {
            owner = newOwner;
        }
    }
}

contract docStore is Owned {
    
    uint public indice;
    
    mapping(string => Documento) private storeByString;
    mapping(bytes32 => Documento) private storeByTitle;
    mapping(uint => Documento) private storeById;
    mapping(bytes32 => Documento) private storeByHash;
    
    struct Documento {
        string ipfsLink;
        bytes32 titulo;
        uint timestamp;
        address walletAddress;
        bytes32 fileHash;
        uint Id;
    }
    
    function docStore() public {
        indice = 0;
    }
    
    function guardarDocumento(string _ipfsLink, bytes32 _titulo, bytes32 _fileHash) onlyOwner external {
        require(storeByString[_ipfsLink].titulo == 0x0);
        require(storeByTitle[_titulo].titulo == 0x0);
        indice += 1;
        Documento memory _documento = Documento(_ipfsLink, _titulo, now, msg.sender, _fileHash, indice); 
        storeByTitle[_titulo] = _documento;
        storeByString[_ipfsLink] = _documento;
        storeById[indice] = _documento;
        storeByHash[_fileHash] = _documento;
    }
    
    function buscarDocumentoPorQM (string _ipfsLink) view external returns (string, bytes32, uint, address, bytes32, uint){
        Documento memory _documento = storeByString[_ipfsLink];
        return (_documento.ipfsLink, _documento.titulo, _documento.timestamp, _documento.walletAddress, _documento.fileHash, _documento.Id);
    }
    
    function buscarDocumentoPorTitulo (bytes32 _titulo) view external returns (string, bytes32, uint, address, bytes32, uint){
        Documento memory _documento = storeByTitle[_titulo];
        return (_documento.ipfsLink, _documento.titulo, _documento.timestamp, _documento.walletAddress, _documento.fileHash, _documento.Id);
    }
    
    function buscarDocumentoPorId (uint _index) view external returns (string, bytes32, uint, address, bytes32, uint){
        Documento memory _documento = storeById[_index];
        return (_documento.ipfsLink, _documento.titulo, _documento.timestamp, _documento.walletAddress, _documento.fileHash, _documento.Id);
    }

    function buscarDocumentoPorHash (bytes32 _index) view external returns (string, bytes32, uint, address, bytes32, uint){
        Documento memory _documento = storeByHash[_index];
        return (_documento.ipfsLink, _documento.titulo, _documento.timestamp, _documento.walletAddress, _documento.fileHash, _documento.Id);
    }
    
}