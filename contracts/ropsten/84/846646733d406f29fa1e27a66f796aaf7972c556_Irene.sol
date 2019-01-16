pragma solidity >=0.4.22 <0.6.0;
contract Irene {
    string public mensaje;
    uint public epochTimestamp;
    
    constructor() public {
        mensaje = "";
        epochTimestamp = 0;
    }
    
    function fijarMensaje(string memory msj) public returns (bool success) {
        require(keccak256(mensaje) == keccak256(""));
        mensaje = msj;
        epochTimestamp = now;
        return true;
    }
    
    
}