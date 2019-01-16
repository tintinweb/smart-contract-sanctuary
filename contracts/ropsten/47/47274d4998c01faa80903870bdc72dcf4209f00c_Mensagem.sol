pragma solidity 0.4.24;

contract Mensagem {
    address public owner;
    string private info;

    constructor(string _mensagemInicial) public {
        owner = msg.sender;
        info = _mensagemInicial;
    }
    
    function setInfo(string _mensagem) public {
        info = _mensagem;
    }
    
    function getInfo() public view returns (string infostring) {
        return info;
    }

    function kill() public { 
        if (msg.sender == owner)  // only allow this action if the account sending the signal is the creator / owner
            selfdestruct(owner);
    }
    
    function isAlive() public pure returns (bool) {
        return true;
    } 
        
}