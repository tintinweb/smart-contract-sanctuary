pragma solidity ^0.4.0;
contract RegistroBlockchain {

    struct Registro {
        bool existe;
        uint block_number;
    }

    mapping(bytes32 => Registro) public registros;
    address public admin;

    function RegistroBlockchain() public {
        admin = msg.sender;
    }
    
    function TrocarAdmin(address _admin) public {
        require(msg.sender == admin);
        admin = _admin;
    }

    function GuardaRegistro(string _hash) public {
        require(msg.sender == admin);
        bytes32 hash = sha256(_hash);
        require(!registros[hash].existe);
        registros[hash].existe = true;
        registros[hash].block_number = block.number;
    }

    function ConsultaRegistro(string _hash) public constant returns (uint) {
        bytes32 hash = sha256(_hash);
        require(registros[hash].existe);
        return (registros[hash].block_number);
    }
}